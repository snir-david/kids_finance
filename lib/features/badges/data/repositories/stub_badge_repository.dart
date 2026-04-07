import '../models/badge_model.dart';
import 'badge_repository.dart';

/// Temporary stub until JARVIS delivers the Firebase implementation.
class StubBadgeRepository implements BadgeRepository {
  @override
  Stream<List<Badge>> watchBadges(String familyId, String childId) =>
      Stream.value([]);

  @override
  Future<void> awardBadge(String familyId, String childId, BadgeType type) async {}

  @override
  Future<void> markSeen(String familyId, String childId, String badgeId) async {}

  @override
  Future<bool> hasBadge(String familyId, String childId, BadgeType type) async => false;
}
