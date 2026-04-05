import 'child.dart';

abstract class ChildRepository {
  /// Stream a specific child's data
  Stream<Child?> getChildStream(String childId, String familyId);

  /// Update child information (display name, avatar)
  Future<void> updateChild({
    required String childId,
    required String familyId,
    String? displayName,
    String? avatarEmoji,
  });

  /// Update child's PIN hash
  Future<void> updatePinHash({
    required String childId,
    required String familyId,
    required String newPinHash,
  });

  /// Update child session expiry
  Future<void> updateSessionExpiry({
    required String childId,
    required String familyId,
    required DateTime expiresAt,
  });
}
