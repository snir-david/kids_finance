import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/goal_model.dart';
import 'goal_repository.dart';

class FirebaseGoalRepository implements GoalRepository {
  FirebaseGoalRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _goalsRef(
    String familyId,
    String childId,
  ) =>
      _firestore
          .collection('families')
          .doc(familyId)
          .collection('children')
          .doc(childId)
          .collection('goals');

  @override
  Stream<List<Goal>> watchGoals(String familyId, String childId) {
    return _goalsRef(familyId, childId)
        .where('isActive', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Goal.fromFirestore(doc)).toList());
  }

  @override
  Future<void> createGoal(
    String familyId,
    String childId,
    String name,
    double targetAmount,
  ) async {
    final now = DateTime.now();
    await _goalsRef(familyId, childId).add({
      'name': name,
      'targetAmount': targetAmount,
      'createdAt': Timestamp.fromDate(now),
      'completedAt': null,
      'isActive': true,
    });
  }

  @override
  Future<void> deleteGoal(
    String familyId,
    String childId,
    String goalId,
  ) async {
    await _goalsRef(familyId, childId).doc(goalId).update({'isActive': false});
  }

  @override
  Future<void> markCompleted(
    String familyId,
    String childId,
    String goalId,
  ) async {
    await _goalsRef(familyId, childId).doc(goalId).update({
      'completedAt': Timestamp.now(),
    });
  }

  /// Checks if any active goal for a child is now met by [currentBalance].
  /// Calls [markCompleted] for each goal where targetAmount <= currentBalance
  /// and completedAt is still null.
  ///
  /// TODO(jarvis): Wire this into FirebaseBucketRepository after each Money
  /// bucket balance update so completion is detected server-side without
  /// requiring a UI trigger. For now, Rhodey should call this from the UI
  /// after any balance change.
  Future<void> checkAndCompleteGoals(
    String familyId,
    String childId,
    double currentBalance,
  ) async {
    final snapshot = await _goalsRef(familyId, childId)
        .where('isActive', isEqualTo: true)
        .where('completedAt', isNull: true)
        .get();

    for (final doc in snapshot.docs) {
      final targetAmount = (doc.data()['targetAmount'] as num).toDouble();
      if (currentBalance >= targetAmount) {
        await markCompleted(familyId, childId, doc.id);
      }
    }
  }
}
