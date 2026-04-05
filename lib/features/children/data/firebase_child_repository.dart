import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/child.dart';
import '../domain/child_repository.dart';

class FirebaseChildRepository implements ChildRepository {
  final FirebaseFirestore _firestore;

  FirebaseChildRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Stream<Child?> getChildStream(String childId, String familyId) {
    return _firestore
        .collection('families')
        .doc(familyId)
        .collection('children')
        .doc(childId)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists) return null;
      return Child.fromJson({
        'id': snapshot.id,
        ...snapshot.data()!,
      });
    });
  }

  @override
  Future<void> updateChild({
    required String childId,
    required String familyId,
    String? displayName,
    String? avatarEmoji,
  }) async {
    final childRef = _firestore
        .collection('families')
        .doc(familyId)
        .collection('children')
        .doc(childId);

    final updates = <String, dynamic>{};
    if (displayName != null) updates['displayName'] = displayName;
    if (avatarEmoji != null) updates['avatarEmoji'] = avatarEmoji;

    if (updates.isNotEmpty) {
      await childRef.update(updates);
    }
  }

  @override
  Future<void> updatePinHash({
    required String childId,
    required String familyId,
    required String newPinHash,
  }) async {
    final childRef = _firestore
        .collection('families')
        .doc(familyId)
        .collection('children')
        .doc(childId);

    await childRef.update({'pinHash': newPinHash});
  }

  @override
  Future<void> updateSessionExpiry({
    required String childId,
    required String familyId,
    required DateTime expiresAt,
  }) async {
    final childRef = _firestore
        .collection('families')
        .doc(familyId)
        .collection('children')
        .doc(childId);

    await childRef.update({'sessionExpiresAt': expiresAt.toIso8601String()});
  }
}
