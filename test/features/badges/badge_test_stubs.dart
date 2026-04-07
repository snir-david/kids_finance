// Stub models, repository interface, fake repository, and service for
// Achievement Badges unit tests.
//
// These mirror the expected interface that JARVIS will implement in
// lib/features/badges/.
//
// TODO: Once lib/features/badges/ lands, replace Badge, BadgeType,
//       BadgeRepository, and BadgeEvaluationService here with imports from
//       the real implementation and delete this file.
//       FakeBadgeRepository can stay as the test double.

import 'package:cloud_firestore/cloud_firestore.dart';

// ── BadgeType ─────────────────────────────────────────────────────────────────

enum BadgeType {
  firstDeposit,
  saver,
  generousHeart,
  youngInvestor,
  goalGetter,
  piggyBank,
}

extension BadgeTypeX on BadgeType {
  String get emoji => {
        BadgeType.firstDeposit: '🏦',
        BadgeType.saver: '💰',
        BadgeType.generousHeart: '❤️',
        BadgeType.youngInvestor: '📈',
        BadgeType.goalGetter: '🏆',
        BadgeType.piggyBank: '🐷',
      }[this]!;

  String get displayName => {
        BadgeType.firstDeposit: 'First Deposit',
        BadgeType.saver: 'Super Saver',
        BadgeType.generousHeart: 'Generous Heart',
        BadgeType.youngInvestor: 'Young Investor',
        BadgeType.goalGetter: 'Goal Getter',
        BadgeType.piggyBank: 'Piggy Bank',
      }[this]!;
}

// ── Badge model ───────────────────────────────────────────────────────────────

class Badge {
  final String id;
  final String familyId;
  final String childId;
  final BadgeType type;
  final DateTime awardedAt;
  final bool seen;

  const Badge({
    required this.id,
    required this.familyId,
    required this.childId,
    required this.type,
    required this.awardedAt,
    this.seen = false,
  });

  factory Badge.fromFirestore(Map<String, dynamic> data, String id) {
    return Badge(
      id: id,
      familyId: data['familyId'] as String,
      childId: data['childId'] as String,
      type: BadgeType.values.firstWhere((e) => e.name == data['type'] as String),
      awardedAt: (data['awardedAt'] as Timestamp).toDate(),
      seen: data['seen'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() => {
        'familyId': familyId,
        'childId': childId,
        'type': type.name,
        'awardedAt': Timestamp.fromDate(awardedAt),
        'seen': seen,
      };

  Badge copyWith({
    String? id,
    String? familyId,
    String? childId,
    BadgeType? type,
    DateTime? awardedAt,
    bool? seen,
  }) =>
      Badge(
        id: id ?? this.id,
        familyId: familyId ?? this.familyId,
        childId: childId ?? this.childId,
        type: type ?? this.type,
        awardedAt: awardedAt ?? this.awardedAt,
        seen: seen ?? this.seen,
      );
}

// ── BadgeRepository interface ─────────────────────────────────────────────────
// JARVIS will implement this against Firestore.

abstract class BadgeRepository {
  Future<void> awardBadge(String familyId, String childId, BadgeType type);
  Future<bool> hasBadge(String familyId, String childId, BadgeType type);
  Future<void> markSeen(String familyId, String childId, BadgeType type);
  Stream<List<Badge>> watchBadges(String familyId, String childId);
}

// ── FakeBadgeRepository ───────────────────────────────────────────────────────
// In-memory implementation — shared by badge_repository_test and
// badge_evaluation_test.  No code generation required.

class FakeBadgeRepository implements BadgeRepository {
  final Map<String, Badge> _badges = {};

  String _key(String familyId, String childId, BadgeType type) =>
      '${familyId}_${childId}_${type.name}';

  List<Badge> _forChild(String familyId, String childId) => _badges.values
      .where((b) => b.familyId == familyId && b.childId == childId)
      .toList();

  // ── Test helpers ────────────────────────────────────────────────────────────

  List<Badge> get allBadges => List.unmodifiable(_badges.values);

  Badge? findByType(String familyId, String childId, BadgeType type) =>
      _badges[_key(familyId, childId, type)];

  // ── BadgeRepository ─────────────────────────────────────────────────────────

  @override
  Future<void> awardBadge(
      String familyId, String childId, BadgeType type) async {
    final key = _key(familyId, childId, type);
    if (_badges.containsKey(key)) return; // idempotent
    _badges[key] = Badge(
      id: key,
      familyId: familyId,
      childId: childId,
      type: type,
      awardedAt: DateTime.now(),
      seen: false,
    );
  }

  @override
  Future<bool> hasBadge(
      String familyId, String childId, BadgeType type) async {
    return _badges.containsKey(_key(familyId, childId, type));
  }

  @override
  Future<void> markSeen(
      String familyId, String childId, BadgeType type) async {
    final key = _key(familyId, childId, type);
    final badge = _badges[key];
    if (badge != null) {
      _badges[key] = badge.copyWith(seen: true);
    }
  }

  @override
  Stream<List<Badge>> watchBadges(String familyId, String childId) =>
      Stream.value(_forChild(familyId, childId));
}

// ── BadgeEvaluationService ────────────────────────────────────────────────────
// Business logic that decides which badges to award based on app events.
// Each method is idempotent: awarding a badge the child already owns is a no-op.

class BadgeEvaluationService {
  final BadgeRepository _repo;

  BadgeEvaluationService(this._repo);

  Future<void> evaluateAfterDeposit(
      String familyId, String childId, double balance) async {
    if (!await _repo.hasBadge(familyId, childId, BadgeType.firstDeposit)) {
      await _repo.awardBadge(familyId, childId, BadgeType.firstDeposit);
    }
    if (balance >= 100 &&
        !await _repo.hasBadge(familyId, childId, BadgeType.saver)) {
      await _repo.awardBadge(familyId, childId, BadgeType.saver);
    }
  }

  Future<void> evaluateAfterDonation(String familyId, String childId) async {
    if (!await _repo.hasBadge(familyId, childId, BadgeType.generousHeart)) {
      await _repo.awardBadge(familyId, childId, BadgeType.generousHeart);
    }
  }

  Future<void> evaluateAfterInvestmentMultiply(
      String familyId, String childId) async {
    if (!await _repo.hasBadge(familyId, childId, BadgeType.youngInvestor)) {
      await _repo.awardBadge(familyId, childId, BadgeType.youngInvestor);
    }
  }

  Future<void> evaluateAfterGoalCompleted(
      String familyId, String childId) async {
    if (!await _repo.hasBadge(familyId, childId, BadgeType.goalGetter)) {
      await _repo.awardBadge(familyId, childId, BadgeType.goalGetter);
    }
  }
}
