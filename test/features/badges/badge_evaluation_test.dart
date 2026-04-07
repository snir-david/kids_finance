// Tests for BadgeEvaluationService — badge trigger logic.
//
// Uses FakeBadgeRepository (defined in badge_test_stubs.dart) injected into
// the service so tests run in-memory without Firebase.

import 'package:flutter_test/flutter_test.dart';

import 'badge_test_stubs.dart';

void main() {
  const familyId = 'family-1';
  const childId = 'child-1';

  late FakeBadgeRepository repo;
  late BadgeEvaluationService service;

  setUp(() {
    repo = FakeBadgeRepository();
    service = BadgeEvaluationService(repo);
  });

  // ── evaluateAfterDeposit ──────────────────────────────────────────────────

  group('evaluateAfterDeposit', () {
    test('awards firstDeposit on the first call', () async {
      await service.evaluateAfterDeposit(familyId, childId, 10.0);

      expect(await repo.hasBadge(familyId, childId, BadgeType.firstDeposit),
          isTrue);
    });

    test('does NOT re-award firstDeposit on a second call', () async {
      await service.evaluateAfterDeposit(familyId, childId, 10.0);
      await service.evaluateAfterDeposit(familyId, childId, 20.0);

      final count = repo.allBadges
          .where((b) => b.type == BadgeType.firstDeposit)
          .length;
      expect(count, equals(1),
          reason: 'firstDeposit must only be awarded once');
    });

    test('awards saver when balance is exactly 100', () async {
      await service.evaluateAfterDeposit(familyId, childId, 100.0);

      expect(await repo.hasBadge(familyId, childId, BadgeType.saver), isTrue);
    });

    test('awards saver when balance exceeds 100', () async {
      await service.evaluateAfterDeposit(familyId, childId, 150.0);

      expect(await repo.hasBadge(familyId, childId, BadgeType.saver), isTrue);
    });

    test('does NOT award saver when balance is less than 100', () async {
      await service.evaluateAfterDeposit(familyId, childId, 99.99);

      expect(await repo.hasBadge(familyId, childId, BadgeType.saver), isFalse);
    });

    test('does NOT award saver when balance is 0', () async {
      await service.evaluateAfterDeposit(familyId, childId, 0.0);

      expect(await repo.hasBadge(familyId, childId, BadgeType.saver), isFalse);
    });
  });

  // ── evaluateAfterDonation ─────────────────────────────────────────────────

  group('evaluateAfterDonation', () {
    test('awards generousHeart on the first call', () async {
      await service.evaluateAfterDonation(familyId, childId);

      expect(
          await repo.hasBadge(familyId, childId, BadgeType.generousHeart),
          isTrue);
    });

    test('does NOT re-award generousHeart on a second call', () async {
      await service.evaluateAfterDonation(familyId, childId);
      await service.evaluateAfterDonation(familyId, childId);

      final count = repo.allBadges
          .where((b) => b.type == BadgeType.generousHeart)
          .length;
      expect(count, equals(1),
          reason: 'generousHeart must only be awarded once');
    });
  });

  // ── evaluateAfterInvestmentMultiply ───────────────────────────────────────

  group('evaluateAfterInvestmentMultiply', () {
    test('awards youngInvestor on the first call', () async {
      await service.evaluateAfterInvestmentMultiply(familyId, childId);

      expect(
          await repo.hasBadge(familyId, childId, BadgeType.youngInvestor),
          isTrue);
    });

    test('does NOT re-award youngInvestor on a second call', () async {
      await service.evaluateAfterInvestmentMultiply(familyId, childId);
      await service.evaluateAfterInvestmentMultiply(familyId, childId);

      final count = repo.allBadges
          .where((b) => b.type == BadgeType.youngInvestor)
          .length;
      expect(count, equals(1),
          reason: 'youngInvestor must only be awarded once');
    });
  });

  // ── evaluateAfterGoalCompleted ────────────────────────────────────────────

  group('evaluateAfterGoalCompleted', () {
    test('awards goalGetter on the first call', () async {
      await service.evaluateAfterGoalCompleted(familyId, childId);

      expect(
          await repo.hasBadge(familyId, childId, BadgeType.goalGetter), isTrue);
    });

    test('does NOT re-award goalGetter on a second call', () async {
      await service.evaluateAfterGoalCompleted(familyId, childId);
      await service.evaluateAfterGoalCompleted(familyId, childId);

      final count =
          repo.allBadges.where((b) => b.type == BadgeType.goalGetter).length;
      expect(count, equals(1), reason: 'goalGetter must only be awarded once');
    });
  });

  // ── Multi-badge evaluation ────────────────────────────────────────────────

  group('multi-badge evaluation', () {
    test(
        'evaluateAfterDeposit awards both firstDeposit AND saver in one pass '
        'when balance >= 100', () async {
      await service.evaluateAfterDeposit(familyId, childId, 200.0);

      expect(await repo.hasBadge(familyId, childId, BadgeType.firstDeposit),
          isTrue);
      expect(await repo.hasBadge(familyId, childId, BadgeType.saver), isTrue);
      expect(repo.allBadges.length, equals(2));
    });

    test('multiple distinct evaluations award multiple distinct badges',
        () async {
      await service.evaluateAfterDeposit(familyId, childId, 150.0);
      await service.evaluateAfterDonation(familyId, childId);
      await service.evaluateAfterInvestmentMultiply(familyId, childId);
      await service.evaluateAfterGoalCompleted(familyId, childId);

      // evaluateAfterDeposit(150) → firstDeposit + saver (2)
      // evaluateAfterDonation → generousHeart (1)
      // evaluateAfterInvestmentMultiply → youngInvestor (1)
      // evaluateAfterGoalCompleted → goalGetter (1)
      // Total = 5 distinct badges
      expect(repo.allBadges.length, equals(5),
          reason:
              'firstDeposit + saver + generousHeart + youngInvestor + goalGetter = 5');
    });
  });

  // ── Idempotency across all evaluations ───────────────────────────────────

  group('all evaluations are idempotent', () {
    test('calling every evaluation twice yields the same badge set', () async {
      for (var i = 0; i < 2; i++) {
        await service.evaluateAfterDeposit(familyId, childId, 100.0);
        await service.evaluateAfterDonation(familyId, childId);
        await service.evaluateAfterInvestmentMultiply(familyId, childId);
        await service.evaluateAfterGoalCompleted(familyId, childId);
      }

      // firstDeposit + saver + generousHeart + youngInvestor + goalGetter = 5
      expect(repo.allBadges.length, equals(5),
          reason: 'No badge should be doubled by running all evaluations twice');
    });
  });
}
