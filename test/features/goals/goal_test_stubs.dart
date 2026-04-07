// Stub models and repository interfaces for Savings Goals unit tests.
// These mirror the expected interface that JARVIS will implement in
// lib/features/goals/.
//
// TODO: Once lib/features/goals/ lands, replace Goal + GoalRepository here
//       with imports from the real implementation and delete this file.

import 'package:cloud_firestore/cloud_firestore.dart';

class Goal {
  final String id;
  final String familyId;
  final String childId;
  final String name;
  final double targetAmount;
  final double balance;
  final bool isActive;
  final DateTime? completedAt;
  final DateTime createdAt;

  const Goal({
    required this.id,
    required this.familyId,
    required this.childId,
    required this.name,
    required this.targetAmount,
    this.balance = 0.0,
    this.isActive = true,
    this.completedAt,
    required this.createdAt,
  });

  /// Progress toward the goal as a fraction in [0.0, 1.0].
  /// Returns 0.0 when targetAmount is 0 to guard against division by zero.
  double get progressPercent {
    if (targetAmount <= 0) return 0.0;
    return (balance / targetAmount).clamp(0.0, 1.0);
  }

  bool get isCompleted => completedAt != null;

  factory Goal.fromFirestore(Map<String, dynamic> data, String id) {
    final rawCompletedAt = data['completedAt'];
    final rawCreatedAt = data['createdAt'];
    return Goal(
      id: id,
      familyId: data['familyId'] as String,
      childId: data['childId'] as String,
      name: data['name'] as String,
      targetAmount: (data['targetAmount'] as num).toDouble(),
      balance: (data['balance'] as num? ?? 0).toDouble(),
      isActive: data['isActive'] as bool? ?? true,
      completedAt:
          rawCompletedAt is Timestamp ? rawCompletedAt.toDate() : null,
      createdAt: rawCreatedAt is Timestamp
          ? rawCreatedAt.toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'familyId': familyId,
        'childId': childId,
        'name': name,
        'targetAmount': targetAmount,
        'balance': balance,
        'isActive': isActive,
        'completedAt':
            completedAt != null ? Timestamp.fromDate(completedAt!) : null,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  Goal copyWith({
    String? id,
    String? familyId,
    String? childId,
    String? name,
    double? targetAmount,
    double? balance,
    bool? isActive,
    DateTime? completedAt,
    bool clearCompletedAt = false,
    DateTime? createdAt,
  }) =>
      Goal(
        id: id ?? this.id,
        familyId: familyId ?? this.familyId,
        childId: childId ?? this.childId,
        name: name ?? this.name,
        targetAmount: targetAmount ?? this.targetAmount,
        balance: balance ?? this.balance,
        isActive: isActive ?? this.isActive,
        completedAt:
            clearCompletedAt ? null : (completedAt ?? this.completedAt),
        createdAt: createdAt ?? this.createdAt,
      );
}

/// Interface for the Goals data layer.
/// JARVIS will implement this against Firestore.
abstract class GoalRepository {
  Stream<List<Goal>> watchGoals(String familyId, String childId);

  Future<void> createGoal({
    required String familyId,
    required String childId,
    required String name,
    required double targetAmount,
  });

  Future<void> deleteGoal(String familyId, String childId, String goalId);

  Future<void> markCompleted(String familyId, String childId, String goalId);
}
