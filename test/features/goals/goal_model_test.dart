// Tests for the Goal domain model — progress calculation, completion state,
// and Firestore serialisation.
//
// Uses the local Goal stub from goal_test_stubs.dart.
// TODO: Once JARVIS ships lib/features/goals/, swap to the real import.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'goal_test_stubs.dart';

void main() {
  final baseDate = DateTime(2026, 4, 7);

  Goal makeGoal({
    String id = 'goal-1',
    String name = 'New Bike',
    double targetAmount = 100.0,
    double balance = 0.0,
    DateTime? completedAt,
    bool isActive = true,
  }) =>
      Goal(
        id: id,
        familyId: 'family-1',
        childId: 'child-1',
        name: name,
        targetAmount: targetAmount,
        balance: balance,
        isActive: isActive,
        completedAt: completedAt,
        createdAt: baseDate,
      );

  // ── progressPercent ────────────────────────────────────────────────────────

  group('Goal.progressPercent', () {
    test('returns 0.0 when balance is 0', () {
      final goal = makeGoal(balance: 0.0, targetAmount: 100.0);
      expect(goal.progressPercent, equals(0.0));
    });

    test('returns 0.5 when balance is half the target', () {
      final goal = makeGoal(balance: 50.0, targetAmount: 100.0);
      expect(goal.progressPercent, equals(0.5));
    });

    test('returns 1.0 when balance equals target', () {
      final goal = makeGoal(balance: 100.0, targetAmount: 100.0);
      expect(goal.progressPercent, equals(1.0));
    });

    test('clamps to 1.0 when balance exceeds target (never > 100%)', () {
      final goal = makeGoal(balance: 150.0, targetAmount: 100.0);
      expect(
        goal.progressPercent,
        equals(1.0),
        reason: 'Progress must never exceed 1.0 even when balance is higher',
      );
    });

    test('returns 0.0 when targetAmount is 0 (division-by-zero guard)', () {
      final goal = makeGoal(balance: 50.0, targetAmount: 0.0);
      expect(
        goal.progressPercent,
        equals(0.0),
        reason: 'Division by zero must return 0.0, not throw',
      );
    });
  });

  // ── isCompleted ───────────────────────────────────────────────────────────

  group('Goal.isCompleted', () {
    test('returns false when completedAt is null', () {
      final goal = makeGoal(completedAt: null);
      expect(goal.isCompleted, isFalse);
    });

    test('returns true when completedAt is set', () {
      final goal = makeGoal(completedAt: DateTime(2026, 4, 7));
      expect(goal.isCompleted, isTrue);
    });
  });

  // ── fromFirestore ──────────────────────────────────────────────────────────

  group('Goal.fromFirestore', () {
    test('deserializes name, targetAmount, and isActive correctly', () {
      final data = {
        'familyId': 'family-1',
        'childId': 'child-1',
        'name': 'New Bike',
        'targetAmount': 100.0,
        'balance': 25.0,
        'isActive': true,
        'completedAt': null,
        'createdAt': Timestamp.fromDate(baseDate),
      };

      final goal = Goal.fromFirestore(data, 'goal-abc');

      expect(goal.id, equals('goal-abc'));
      expect(goal.name, equals('New Bike'));
      expect(goal.targetAmount, equals(100.0));
      expect(goal.isActive, isTrue);
    });

    test('completedAt is null when Firestore field is null', () {
      final data = {
        'familyId': 'f1',
        'childId': 'c1',
        'name': 'Toy Car',
        'targetAmount': 50.0,
        'balance': 0.0,
        'isActive': true,
        'completedAt': null,
        'createdAt': Timestamp.fromDate(baseDate),
      };

      final goal = Goal.fromFirestore(data, 'goal-1');
      expect(goal.completedAt, isNull);
    });

    test('completedAt deserializes from Timestamp when present', () {
      final completedDate = DateTime(2026, 4, 5, 10);
      final data = {
        'familyId': 'f1',
        'childId': 'c1',
        'name': 'Soccer Ball',
        'targetAmount': 30.0,
        'balance': 30.0,
        'isActive': true,
        'completedAt': Timestamp.fromDate(completedDate),
        'createdAt': Timestamp.fromDate(baseDate),
      };

      final goal = Goal.fromFirestore(data, 'goal-2');
      expect(goal.completedAt, isNotNull);
    });
  });

  // ── toMap ──────────────────────────────────────────────────────────────────

  group('Goal.toMap', () {
    test('contains all required Firestore field keys', () {
      final goal = makeGoal(name: 'Skateboard', targetAmount: 80.0, balance: 40.0);
      final map = goal.toMap();

      for (final key in [
        'familyId',
        'childId',
        'name',
        'targetAmount',
        'balance',
        'isActive',
        'completedAt',
        'createdAt',
      ]) {
        expect(map.containsKey(key), isTrue, reason: 'Missing key: $key');
      }
    });

    test('name and targetAmount values match source Goal', () {
      final goal = makeGoal(name: 'Skateboard', targetAmount: 80.0);
      final map = goal.toMap();
      expect(map['name'], equals('Skateboard'));
      expect(map['targetAmount'], equals(80.0));
    });

    test('completedAt serializes as Timestamp when set', () {
      final completed = DateTime(2026, 4, 7, 12);
      final goal = makeGoal(completedAt: completed);
      final map = goal.toMap();
      expect(map['completedAt'], isA<Timestamp>());
    });

    test('completedAt serializes as null when not set', () {
      final goal = makeGoal(completedAt: null);
      final map = goal.toMap();
      expect(map['completedAt'], isNull);
    });
  });
}
