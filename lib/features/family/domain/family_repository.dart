import 'family.dart';
import '../../children/domain/child.dart';

abstract class FamilyRepository {
  /// Stream the current family data
  Stream<Family?> getFamilyStream(String familyId);

  /// Create a new family with the given name and parent as owner
  Future<Family> createFamily({
    required String name,
    required String parentUid,
    required String parentDisplayName,
  });

  /// Add a parent to the family
  Future<void> addParent({
    required String familyId,
    required String parentUid,
    required String parentDisplayName,
    bool isOwner = false,
  });

  /// Add a child to the family
  Future<Child> addChild({
    required String familyId,
    required String displayName,
    required String avatarEmoji,
  });
}
