// Tests for GoalRepository CRUD operations.
//
// Uses FakeGoalRepository — in-memory, no code generation, no Mockito.
// The fake is defined locally; it doubles as a spec for JARVIS's
// FirebaseGoalRepository implementation.

import 'package:flutter_test/flutter_test.dart';

import 'goal_test_stubs.dart';

// ── FakeGoalRepository ────────────────────────────────────────────────────────

class FakeGoalRepository implements GoalRepository {
  final List<Goal> _goals = [];
  int _idCounter = 0;

  @override
  Stream<List<Goal>> watchGoals(String familyId, String childId) =>
      Stream.value(
        _goals
            .where((g) =>
                g.familyId == familyId &&
                g.childId == childId &&
                g.isActive)
            .toList(),
      );

  @override
  Future<void> createGoal({
    required String familyId,
    required String childId,
    required String name,
    required double targetAmount,
  }) async {
    if (name.trim().isEmpty) {
      throw ArgumentError('Goal name cannot be empty');
    }
    if (targetAmount <= 0) {
      throw ArgumentError('Target amount must be greater than 0');
    }
    _idCounter++;
    _goals.add(Goal(
      id: 'goal-$_idCounter',
      familyId: familyId,
      childId: childId,
      name: name,
      targetAmount: targetAmount,
      createdAt: DateTime.now(),
    ));
  }

  @override
  Future<void> deleteGoal(
      String familyId, String childId, String goalId) async {
    final index = _goals.indexWhere((g) => g.id == goalId);
    if (index != -1) {
      _goals[index] = _goals[index].copyWith(isActive: false);
    }
  }

  @override
  Future<void> markCompleted(
      String familyId, String childId, String goalId) async {
    final index = _goals.indexWhere((g) => g.id == goalId);
    if (index != -1 && _goals[index].completedAt == null) {
      _goals[index] = _goals[index].copyWith(completedAt: DateTime.now());
    }
  }

  // Test helpers
  List<Goal> get allGoals => List.unmodifiable(_goals);

  Goal? findById(String id) {
    final matches = _goals.where((g) => g.id == id);
    return matches.isEmpty ? null : matches.first;
  }
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  const familyId = 'family-1';
  const childId = 'child-1';

  late FakeGoalRepository repo;

  setUp(() {
    repo = FakeGoalRepository();
  });

  // ── createGoal ─────────────────────────────────────────────────────────────

  group('createGoal', () {
    test('adds goal so it appears in watchGoals stream', () async {
      await repo.createGoal(
        familyId: familyId,
        childId: childId,
        name: 'New Bike',
        targetAmount: 100.0,
      );

      final goals = await repo.watchGoals(familyId, childId).first;
      expect(goals, hasLength(1));
      expect(goals.first.name, equals('New Bike'));
    });

    test('newly created goal has isActive = true', () async {
      await repo.createGoal(
        familyId: familyId,
        childId: childId,
        name: 'Scooter',
        targetAmount: 60.0,
      );

      expect(repo.allGoals.first.isActive, isTrue);
    });

    test('cannot create goal with empty name', () async {
      expect(
        () => repo.createGoal(
          familyId: familyId,
          childId: childId,
          name: '   ',
          targetAmount: 50.0,
        ),
        throwsArgumentError,
      );
    });

    test('cannot create goal with targetAmount of exactly 0', () async {
      expect(
        () => repo.createGoal(
          familyId: familyId,
          childId: childId,
          name: 'Toy',
          targetAmount: 0.0,
        ),
        throwsArgumentError,
      );
    });

    test('cannot create goal with negative targetAmount', () async {
      expect(
        () => repo.createGoal(
          familyId: familyId,
          childId: childId,
          name: 'Toy',
          targetAmount: -10.0,
        ),
        throwsArgumentError,
      );
    });
  });

  // ── deleteGoal ────────────────────────────────────────────────────────────

  group('deleteGoal', () {
    test('sets isActive to false (soft delete — record still exists)', () async {
      await repo.createGoal(
        familyId: familyId,
        childId: childId,
        name: 'Scooter',
        targetAmount: 60.0,
      );
      final goalId = repo.allGoals.first.id;

      await repo.deleteGoal(familyId, childId, goalId);

      final stored = repo.findById(goalId);
      expect(stored, isNotNull, reason: 'Soft-deleted goal must still be in storage');
      expect(stored!.isActive, isFalse);
    });

    test('deleted goal no longer appears in watchGoals stream', () async {
      await repo.createGoal(
        familyId: familyId,
        childId: childId,
        name: 'Painting Kit',
        targetAmount: 25.0,
      );
      final goalId = repo.allGoals.first.id;

      await repo.deleteGoal(familyId, childId, goalId);

      final visible = await repo.watchGoals(familyId, childId).first;
      expect(visible, isEmpty,
          reason: 'Soft-deleted goal must not appear in the stream');
    });
  });

  // ── markCompleted ─────────────────────────────────────────────────────────

  group('markCompleted', () {
    test('sets completedAt timestamp on the goal', () async {
      await repo.createGoal(
        familyId: familyId,
        childId: childId,
        name: 'Helmet',
        targetAmount: 30.0,
      );
      final goalId = repo.allGoals.first.id;

      await repo.markCompleted(familyId, childId, goalId);

      expect(repo.findById(goalId)!.completedAt, isNotNull);
    });

    test('does not overwrite completedAt if already completed (idempotent)', () async {
      await repo.createGoal(
        familyId: familyId,
        childId: childId,
        name: 'Book Set',
        targetAmount: 20.0,
      );
      final goalId = repo.allGoals.first.id;

      await repo.markCompleted(familyId, childId, goalId);
      final firstCompletedAt = repo.findById(goalId)!.completedAt;

      // Small delay so a second DateTime.now() would differ
      await Future.delayed(const Duration(milliseconds: 5));
      await repo.markCompleted(familyId, childId, goalId);
      final secondCompletedAt = repo.findById(goalId)!.completedAt;

      expect(secondCompletedAt, equals(firstCompletedAt),
          reason: 'completedAt must not be overwritten once set');
    });
  });

  // ── watchGoals ────────────────────────────────────────────────────────────

  group('watchGoals', () {
    test('only returns active goals for the given child', () async {
      await repo.createGoal(
          familyId: familyId, childId: childId, name: 'A', targetAmount: 10);
      await repo.createGoal(
          familyId: familyId, childId: childId, name: 'B', targetAmount: 20);
      await repo.createGoal(
          familyId: familyId, childId: childId, name: 'C', targetAmount: 30);

      final goalIdToDelete = repo.allGoals.first.id;
      await repo.deleteGoal(familyId, childId, goalIdToDelete);

      final visible = await repo.watchGoals(familyId, childId).first;
      expect(visible, hasLength(2),
          reason: '2 active goals should remain after 1 soft-delete');
    });
  });
}
