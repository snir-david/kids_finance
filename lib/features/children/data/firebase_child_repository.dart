import 'package:bcrypt/bcrypt.dart';
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
    String? name,
    String? avatarEmoji,
    String? newPin,
  }) async {
    final childRef = _firestore
        .collection('families')
        .doc(familyId)
        .collection('children')
        .doc(childId);

    final updates = <String, dynamic>{};
    if (name != null) updates['displayName'] = name;
    if (avatarEmoji != null) updates['avatarEmoji'] = avatarEmoji;
    if (newPin != null) updates['pinHash'] = BCrypt.hashpw(newPin, BCrypt.gensalt());

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

    await childRef.update({'sessionExpiresAt': Timestamp.fromDate(expiresAt)});
  }

  @override
  Future<void> archiveChild({
    required String familyId,
    required String childId,
  }) async {
    await _firestore
        .collection('families')
        .doc(familyId)
        .collection('children')
        .doc(childId)
        .update({'archived': true});
  }
}
