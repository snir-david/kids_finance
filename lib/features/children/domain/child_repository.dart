import 'child.dart';

abstract class ChildRepository {
  /// Stream a specific child's data
  Stream<Child?> getChildStream(String childId, String familyId);

  /// Update child information. Only provided (non-null) fields are changed.
  Future<void> updateChild({
    required String childId,
    required String familyId,
    String? name,
    String? avatarEmoji,
  });

  /// Soft-delete a child by setting archived: true.
  /// Data is preserved; UI filters by archived != true.
  Future<void> archiveChild({
    required String familyId,
    required String childId,
  });
}
