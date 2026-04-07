import '../models/badge_model.dart';

abstract class BadgeRepository {
  Stream<List<Badge>> watchBadges(String familyId, String childId);

  Future<void> awardBadge(String familyId, String childId, BadgeType type);

  Future<void> markSeen(String familyId, String childId, String badgeId);

  Future<bool> hasBadge(String familyId, String childId, BadgeType type);
}
