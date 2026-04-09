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
    return _schedulesRef(familyId)
        .where('childId', isEqualTo: childId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((doc) => Schedule.fromFirestore(doc)).toList());
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
}
