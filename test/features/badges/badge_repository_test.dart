// Tests for FakeBadgeRepository — in-memory repository logic.
//
// FakeBadgeRepository is defined in badge_test_stubs.dart and doubles as a
// behavioural spec for JARVIS's FirebaseBadgeRepository implementation.

import 'package:flutter_test/flutter_test.dart';

import 'badge_test_stubs.dart';

void main() {
  const familyId = 'family-1';
  const childId = 'child-1';

  late FakeBadgeRepository repo;

  setUp(() {
    repo = FakeBadgeRepository();
  });

  // ── awardBadge ────────────────────────────────────────────────────────────

  group('awardBadge', () {
    test('adds a badge with seen = false', () async {
      await repo.awardBadge(familyId, childId, BadgeType.firstDeposit);

      final badge = repo.findByType(familyId, childId, BadgeType.firstDeposit);
      expect(badge, isNotNull);
      expect(badge!.seen, isFalse);
    });

    test('sets correct familyId, childId, and type on the stored badge',
        () async {
      await repo.awardBadge(familyId, childId, BadgeType.saver);

      final badge = repo.findByType(familyId, childId, BadgeType.saver);
      expect(badge, isNotNull);
      expect(badge!.familyId, equals(familyId));
      expect(badge.childId, equals(childId));
      expect(badge.type, equals(BadgeType.saver));
    });

    test('is idempotent — awarding the same BadgeType twice creates one badge',
        () async {
      await repo.awardBadge(familyId, childId, BadgeType.firstDeposit);
      await repo.awardBadge(familyId, childId, BadgeType.firstDeposit);

      final count = repo.allBadges
          .where((b) =>
              b.familyId == familyId &&
              b.childId == childId &&
              b.type == BadgeType.firstDeposit)
          .length;
      expect(count, equals(1),
          reason: 'Duplicate award must not create a second record');
    });
  });

  // ── hasBadge ──────────────────────────────────────────────────────────────

  group('hasBadge', () {
    test('returns false before the badge is awarded', () async {
      final result =
          await repo.hasBadge(familyId, childId, BadgeType.goalGetter);
      expect(result, isFalse);
    });

    test('returns true after the badge is awarded', () async {
      await repo.awardBadge(familyId, childId, BadgeType.goalGetter);

      final result =
          await repo.hasBadge(familyId, childId, BadgeType.goalGetter);
      expect(result, isTrue);
    });

    test('returns false for a different BadgeType even when one type is awarded',
        () async {
      await repo.awardBadge(familyId, childId, BadgeType.firstDeposit);

      final result = await repo.hasBadge(familyId, childId, BadgeType.saver);
      expect(result, isFalse);
    });
  });

  // ── markSeen ──────────────────────────────────────────────────────────────

  group('markSeen', () {
    test('sets seen to true on an existing badge', () async {
      await repo.awardBadge(familyId, childId, BadgeType.generousHeart);
      await repo.markSeen(familyId, childId, BadgeType.generousHeart);

      final badge =
          repo.findByType(familyId, childId, BadgeType.generousHeart);
      expect(badge!.seen, isTrue);
    });

    test('is a no-op when the badge does not exist', () async {
      // Should not throw
      await repo.markSeen(familyId, childId, BadgeType.youngInvestor);
      expect(repo.allBadges, isEmpty);
    });

    test('seen remains true after being called twice', () async {
      await repo.awardBadge(familyId, childId, BadgeType.saver);
      await repo.markSeen(familyId, childId, BadgeType.saver);
      await repo.markSeen(familyId, childId, BadgeType.saver);

      final badge = repo.findByType(familyId, childId, BadgeType.saver);
      expect(badge!.seen, isTrue);
    });
  });

  // ── watchBadges ───────────────────────────────────────────────────────────

  group('watchBadges', () {
    test('streams all badges for the given child', () async {
      await repo.awardBadge(familyId, childId, BadgeType.firstDeposit);
      await repo.awardBadge(familyId, childId, BadgeType.saver);

      final badges = await repo.watchBadges(familyId, childId).first;
      expect(badges, hasLength(2));
    });

    test('returns empty list when no badges have been awarded', () async {
      final badges = await repo.watchBadges(familyId, childId).first;
      expect(badges, isEmpty);
    });

    test('reflects updates after additional awards (re-subscribe)', () async {
      await repo.awardBadge(familyId, childId, BadgeType.firstDeposit);
      final first = await repo.watchBadges(familyId, childId).first;
      expect(first, hasLength(1));

      await repo.awardBadge(familyId, childId, BadgeType.saver);
      final second = await repo.watchBadges(familyId, childId).first;
      expect(second, hasLength(2));
    });

    test('only returns badges for the requested child', () async {
      const otherChildId = 'child-OTHER';
      await repo.awardBadge(familyId, childId, BadgeType.goalGetter);
      await repo.awardBadge(familyId, otherChildId, BadgeType.youngInvestor);

      final badges = await repo.watchBadges(familyId, childId).first;
      expect(badges, hasLength(1));
      expect(badges.first.type, equals(BadgeType.goalGetter));
    });
  });
}
