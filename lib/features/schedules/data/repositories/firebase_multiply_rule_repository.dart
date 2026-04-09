import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/multiply_rule_model.dart';
import 'multiply_rule_repository.dart';

class FirebaseMultiplyRuleRepository implements MultiplyRuleRepository {
  FirebaseMultiplyRuleRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _rulesRef(String familyId) =>
      _firestore.collection('families').doc(familyId).collection('multiplyRules');

  @override
  Stream<List<MultiplyRule>> watchRules(String familyId, String childId) {
    return _rulesRef(familyId)
        .where('childId', isEqualTo: childId)
        .snapshots()
        .map((snap) {
      final rules = snap.docs.map((d) => MultiplyRule.fromFirestore(d)).toList();
      rules.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return rules;
    });
  }

  @override
  Future<void> addRule({
    required String familyId,
    required String childId,
    required double multiplierPercent,
    required ScheduleFrequency frequency,
  }) async {
    final now = DateTime.now();
    await _rulesRef(familyId).add({
      'childId': childId,
      'familyId': familyId,
      'multiplierPercent': multiplierPercent,
      'frequency': frequency.toJson(),
      'isActive': true,
      'nextRunAt': Timestamp.fromDate(MultiplyRule.computeFirstRunAt(frequency)),
      'createdAt': Timestamp.fromDate(now),
    });
  }

  @override
  Future<void> toggleRule(String familyId, String ruleId, bool isActive) async {
    await _rulesRef(familyId).doc(ruleId).update({'isActive': isActive});
  }

  @override
  Future<void> deleteRule(String familyId, String ruleId) async {
    await _rulesRef(familyId).doc(ruleId).delete();
  }

  @override
  Future<int> processOverdueRules(String familyId) async {
    final now = DateTime.now();
    final snap = await _rulesRef(familyId).where('isActive', isEqualTo: true).get();
    final overdue = snap.docs
        .map((d) => MultiplyRule.fromFirestore(d))
        .where((r) => r.nextRunAt.isBefore(now))
        .toList();

    if (overdue.isEmpty) return 0;

    int processed = 0;
    for (final rule in overdue) {
      await _applyMultiply(familyId, rule);
      processed++;
    }
    return processed;
  }

  Future<void> _applyMultiply(String familyId, MultiplyRule rule) async {
    final investRef = _firestore
        .collection('families')
        .doc(familyId)
        .collection('children')
        .doc(rule.childId)
        .collection('buckets')
        .doc('investment');

    final snap = await investRef.get();
    final prevBalance = (snap.data()?['balance'] as num? ?? 0).toDouble();
    final newBalance =
        double.parse((prevBalance * rule.factor).toStringAsFixed(2));

    final batch = _firestore.batch();
    final ts = Timestamp.fromDate(DateTime.now());

    batch.update(investRef, {'balance': newBalance, 'lastUpdatedAt': ts});

    final txRef = _firestore
        .collection('families')
        .doc(familyId)
        .collection('transactions')
        .doc();
    batch.set(txRef, {
      'childId': rule.childId,
      'familyId': familyId,
      'bucketType': 'investment',
      'type': 'investmentMultiplied',
      'amount': newBalance - prevBalance,
      'multiplier': rule.factor,
      'previousBalance': prevBalance,
      'newBalance': newBalance,
      'performedByUid': 'scheduler',
      'ruleId': rule.id,
      'performedAt': ts,
    });

    batch.update(_rulesRef(familyId).doc(rule.id),
        {'nextRunAt': Timestamp.fromDate(rule.advanceNextRunAt())});

    await batch.commit();
  }
}
