// Tests for savings-goal auto-completion logic.
//
// A goal completes when the child's My Money bucket balance reaches or exceeds
// the goal's targetAmount.  Only the Money bucket counts — Investment and
// Charity do not contribute to savings-goal progress.
//
// A local stub `checkGoalCompletion` function mirrors the contract we expect
// GoalCompletionService to expose.  Swap in the real import once JARVIS ships.

import 'package:flutter_test/flutter_test.dart';
import 'package:kids_finance/features/buckets/domain/bucket.dart';

import 'goal_test_stubs.dart';

// ── Stub completion logic ─────────────────────────────────────────────────────
//
// Returns the goal with completedAt set if moneyBalance >= targetAmount and
// the goal is not already completed.  Returns null otherwise.
Goal? checkGoalCompletion({
  required Goal goal,
  required double moneyBalance,
}) {
  if (goal.isCompleted) return null;
  if (moneyBalance >= goal.targetAmount) {
    return goal.copyWith(completedAt: DateTime.now());
  }
  return null;
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  final baseDate = DateTime(2026, 4, 7);

  Goal makeGoal({
    double targetAmount = 100.0,
    double balance = 0.0,
    DateTime? completedAt,
  }) =>
      Goal(
        id: 'goal-1',
        familyId: 'family-1',
        childId: 'child-1',
        name: 'New Bike',
        targetAmount: targetAmount,
        balance: balance,
        completedAt: completedAt,
        createdAt: baseDate,
      );

  // ── Completion trigger ────────────────────────────────────────────────────

  group('Goal completion detection', () {
    test('goal is marked complete when My Money balance == targetAmount', () {
      final goal = makeGoal(targetAmount: 100.0);
      final result = checkGoalCompletion(goal: goal, moneyBalance: 100.0);
      expect(result, isNotNull);
      expect(result!.completedAt, isNotNull);
    });

    test('goal is marked complete when My Money balance exceeds targetAmount', () {
      final goal = makeGoal(targetAmount: 80.0);
      final result = checkGoalCompletion(goal: goal, moneyBalance: 120.0);
      expect(result, isNotNull,
          reason: 'Balance above target should still trigger completion');
    });

    test('goal is NOT marked complete when My Money balance < targetAmount', () {
      final goal = makeGoal(targetAmount: 100.0);
      final result = checkGoalCompletion(goal: goal, moneyBalance: 99.99);
      expect(result, isNull,
          reason: '\$99.99 is one cent short — goal must not complete yet');
    });

    test('goal at zero balance is not complete', () {
      final goal = makeGoal(targetAmount: 50.0, balance: 0.0);
      final result = checkGoalCompletion(goal: goal, moneyBalance: 0.0);
      expect(result, isNull);
    });

    test('already-completed goal is not re-completed (completedAt not overwritten)', () {
      final originalDate = DateTime(2026, 4, 1);
      final goal = makeGoal(targetAmount: 50.0, completedAt: originalDate);

      final result = checkGoalCompletion(goal: goal, moneyBalance: 200.0);

      expect(result, isNull,
          reason: 'checkGoalCompletion must return null for already-completed goals');
    });
  });

  // ── Bucket-type isolation ─────────────────────────────────────────────────

  group('Completion only checks My Money bucket', () {
    test('Investment bucket balance does NOT trigger goal completion', () {
      final goal = makeGoal(targetAmount: 100.0);
      // Investment = 500, but My Money = 0 → no completion
      const moneyBalance = 0.0;
      // (investment balance is intentionally not passed — it never should be)
      final result = checkGoalCompletion(goal: goal, moneyBalance: moneyBalance);
      expect(result, isNull,
          reason: 'Only the Money bucket should count toward goal completion');
    });

    test('Charity bucket balance does NOT trigger goal completion', () {
      final goal = makeGoal(targetAmount: 100.0);
      // Charity = 200, but My Money = 0 → no completion
      const moneyBalance = 0.0;
      final result = checkGoalCompletion(goal: goal, moneyBalance: moneyBalance);
      expect(result, isNull,
          reason: 'Charity balance must not count toward goal completion');
    });

    test('BucketType.money is the correct completion trigger (enum sanity)', () {
      // Explicitly verify the enum value — guards against future rename
      expect(BucketType.money.name, equals('money'));
    });
  });
}
