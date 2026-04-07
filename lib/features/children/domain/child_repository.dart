import 'child.dart';

abstract class ChildRepository {
  /// Stream a specific child's data
  Stream<Child?> getChildStream(String childId, String familyId);

  /// Update child information. Only provided (non-null) fields are changed.
  /// If [newPin] is provided it will be hashed and stored.
  Future<void> updateChild({
    required String childId,
    required String familyId,
    String? name,
    String? avatarEmoji,
    String? newPin,
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

  /// Soft-delete a child by setting archived: true.
  /// Data is preserved; UI filters by archived != true.
  Future<void> archiveChild({
    required String familyId,
    required String childId,
  });
}
