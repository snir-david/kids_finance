// Tests for the Badge domain model — Firestore serialisation and helper getters.
//
// Uses stubs from badge_test_stubs.dart.
// TODO: Once JARVIS ships lib/features/badges/, swap to the real import.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'badge_test_stubs.dart';

void main() {
  final baseDate = DateTime(2026, 4, 7, 10);

  Badge makeBadge({
    String id = 'badge-1',
    BadgeType type = BadgeType.firstDeposit,
    bool seen = false,
    DateTime? awardedAt,
  }) =>
      Badge(
        id: id,
        familyId: 'family-1',
        childId: 'child-1',
        type: type,
        awardedAt: awardedAt ?? baseDate,
        seen: seen,
      );

  // ── fromFirestore ─────────────────────────────────────────────────────────

  group('Badge.fromFirestore', () {
    test('deserializes all fields correctly', () {
      final data = {
        'familyId': 'family-1',
        'childId': 'child-1',
        'type': 'firstDeposit',
        'awardedAt': Timestamp.fromDate(baseDate),
        'seen': false,
      };

      final badge = Badge.fromFirestore(data, 'badge-abc');

      expect(badge.id, equals('badge-abc'));
      expect(badge.familyId, equals('family-1'));
      expect(badge.childId, equals('child-1'));
      expect(badge.type, equals(BadgeType.firstDeposit));
      expect(badge.awardedAt, equals(baseDate));
      expect(badge.seen, isFalse);
    });

    test('handles all 6 BadgeType values without throwing', () {
      for (final type in BadgeType.values) {
        final data = {
          'familyId': 'f1',
          'childId': 'c1',
          'type': type.name,
          'awardedAt': Timestamp.fromDate(baseDate),
          'seen': false,
        };
        final badge = Badge.fromFirestore(data, 'badge-${type.name}');
        expect(badge.type, equals(type),
            reason: 'BadgeType.${type.name} must round-trip through fromFirestore');
      }
    });
  });

  // ── toMap ─────────────────────────────────────────────────────────────────

  group('Badge.toMap', () {
    test('serializes BadgeType as its string name (type.name)', () {
      final badge = makeBadge(type: BadgeType.saver);
      final map = badge.toMap();
      expect(map['type'], equals('saver'));
    });

    test('contains all required Firestore field keys', () {
      final map = makeBadge().toMap();
      for (final key in ['familyId', 'childId', 'type', 'awardedAt', 'seen']) {
        expect(map.containsKey(key), isTrue, reason: 'Missing key: $key');
      }
    });

    test('awardedAt serializes as Timestamp', () {
      final map = makeBadge(awardedAt: baseDate).toMap();
      expect(map['awardedAt'], isA<Timestamp>());
    });

    test('seen field round-trips correctly', () {
      expect(makeBadge(seen: false).toMap()['seen'], isFalse);
      expect(makeBadge(seen: true).toMap()['seen'], isTrue);
    });
  });

  // ── emoji getter ──────────────────────────────────────────────────────────

  group('BadgeType.emoji', () {
    test('returns correct emoji for each of the 6 badge types', () {
      expect(BadgeType.firstDeposit.emoji, equals('🏦'));
      expect(BadgeType.saver.emoji, equals('💰'));
      expect(BadgeType.generousHeart.emoji, equals('❤️'));
      expect(BadgeType.youngInvestor.emoji, equals('📈'));
      expect(BadgeType.goalGetter.emoji, equals('🏆'));
      expect(BadgeType.piggyBank.emoji, equals('🐷'));
    });

    test('all 6 badge types have a non-empty emoji string', () {
      for (final type in BadgeType.values) {
        expect(type.emoji, isNotEmpty,
            reason: 'BadgeType.${type.name} must have an emoji');
      }
    });
  });

  // ── displayName getter ────────────────────────────────────────────────────

  group('BadgeType.displayName', () {
    test('returns correct display name for each of the 6 badge types', () {
      expect(BadgeType.firstDeposit.displayName, equals('First Deposit'));
      expect(BadgeType.saver.displayName, equals('Super Saver'));
      expect(BadgeType.generousHeart.displayName, equals('Generous Heart'));
      expect(BadgeType.youngInvestor.displayName, equals('Young Investor'));
      expect(BadgeType.goalGetter.displayName, equals('Goal Getter'));
      expect(BadgeType.piggyBank.displayName, equals('Piggy Bank'));
    });

    test('all 6 badge types have a non-empty display name', () {
      for (final type in BadgeType.values) {
        expect(type.displayName, isNotEmpty,
            reason: 'BadgeType.${type.name} must have a display name');
      }
    });
  });
}
