import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/schedule_model.dart';
import 'schedule_repository.dart';

class FirebaseScheduleRepository implements ScheduleRepository {
  FirebaseScheduleRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _schedulesRef(String familyId) =>
      _firestore
          .collection('families')
          .doc(familyId)
          .collection('schedules');

  @override
  Stream<List<Schedule>> watchSchedules(String familyId, String childId) {
    // No orderBy to avoid requiring a composite Firestore index; sort client-side.
    return _schedulesRef(familyId)
        .where('childId', isEqualTo: childId)
        .snapshots()
        .map((snap) {
      final schedules =
          snap.docs.map((doc) => Schedule.fromFirestore(doc)).toList();
      schedules.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return schedules;
    });
  }

  @override
  Future<void> addSchedule({
    required String familyId,
    required String childId,
    required double amount,
    required ScheduleFrequency frequency,
    required int dayOfWeek,
  }) async {
    final nextRunAt = Schedule.computeNextRunAt(frequency, dayOfWeek);
    final now = DateTime.now();
    await _schedulesRef(familyId).add({
      'childId': childId,
      'familyId': familyId,
      'amount': amount,
      'frequency': frequency.toJson(),
      'dayOfWeek': dayOfWeek,
      'isActive': true,
      'nextRunAt': Timestamp.fromDate(nextRunAt),
      'createdAt': Timestamp.fromDate(now),
    });
  }

  @override
  Future<void> toggleSchedule(
      String familyId, String scheduleId, bool isActive) async {
    await _schedulesRef(familyId)
        .doc(scheduleId)
        .update({'isActive': isActive});
  }

  @override
  Future<void> deleteSchedule(String familyId, String scheduleId) async {
    await _schedulesRef(familyId).doc(scheduleId).delete();
  }

  /// Distributes all overdue allowances for the family directly from the
  /// client — no Cloud Function or Blaze plan required.
  /// Returns the number of schedules that were paid out.
  @override
  Future<int> processOverdueAllowances(String familyId) async {
    final now = DateTime.now();
    final snap = await _schedulesRef(familyId)
        .where('isActive', isEqualTo: true)
        .get();

    final overdue = snap.docs
        .map((d) => Schedule.fromFirestore(d))
        .where((s) => s.nextRunAt.isBefore(now))
        .toList();

    if (overdue.isEmpty) return 0;

    int processed = 0;
    for (final schedule in overdue) {
      await _distributeAllowance(familyId, schedule);
      processed++;
    }
    return processed;
  }

  Future<void> _distributeAllowance(
      String familyId, Schedule schedule) async {
    final moneyAmt =
        double.parse((schedule.amount * 0.70).toStringAsFixed(2));
    final investAmt =
        double.parse((schedule.amount * 0.20).toStringAsFixed(2));
    final charityAmt =
        double.parse((schedule.amount * 0.10).toStringAsFixed(2));

    final childRef = _firestore
        .collection('families')
        .doc(familyId)
        .collection('children')
        .doc(schedule.childId);

    final moneyRef = childRef.collection('buckets').doc('money');
    final investRef = childRef.collection('buckets').doc('investment');
    final charityRef = childRef.collection('buckets').doc('charity');

    final results = await Future.wait(
        [moneyRef.get(), investRef.get(), charityRef.get()]);
    final moneyBal =
        (results[0].data()?['balance'] as num? ?? 0).toDouble();
    final investBal =
        (results[1].data()?['balance'] as num? ?? 0).toDouble();
    final charityBal =
        (results[2].data()?['balance'] as num? ?? 0).toDouble();

    final batch = _firestore.batch();
    final ts = Timestamp.fromDate(DateTime.now());

    batch.update(moneyRef,
        {'balance': moneyBal + moneyAmt, 'lastUpdatedAt': ts});
    batch.update(investRef,
        {'balance': investBal + investAmt, 'lastUpdatedAt': ts});
    batch.update(charityRef,
        {'balance': charityBal + charityAmt, 'lastUpdatedAt': ts});

    final txBase = {
      'childId': schedule.childId,
      'familyId': familyId,
      'type': 'distributed',
      'performedByUid': 'scheduler',
      'scheduleId': schedule.id,
      'performedAt': ts,
    };

    final txCol = _firestore
        .collection('families')
        .doc(familyId)
        .collection('transactions');

    for (final entry in [
      ('money', moneyAmt, moneyBal),
      ('investment', investAmt, investBal),
      ('charity', charityAmt, charityBal),
    ]) {
      batch.set(txCol.doc(), {
        ...txBase,
        'bucketType': entry.$1,
        'amount': entry.$2,
        'previousBalance': entry.$3,
        'newBalance': entry.$3 + entry.$2,
      });
    }

    final nextRunAt = schedule.advanceNextRunAt();
    batch.update(_schedulesRef(familyId).doc(schedule.id),
        {'nextRunAt': Timestamp.fromDate(nextRunAt)});

    await batch.commit();
  }
}
