import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/family.dart';
import '../domain/parent_user.dart';
import '../domain/family_repository.dart';
import '../../children/domain/child.dart';

class FirebaseFamilyRepository implements FamilyRepository {
  final FirebaseFirestore _firestore;

  FirebaseFamilyRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Stream<Family?> getFamilyStream(String familyId) {
    return _firestore
        .collection('families')
        .doc(familyId)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists) return null;
      return Family.fromJson({
        'id': snapshot.id,
        ...snapshot.data()!,
      });
    });
  }

  @override
  Future<Family> createFamily({
    required String name,
    required String parentUid,
    required String parentDisplayName,
  }) async {
    final familyRef = _firestore.collection('families').doc();
    final userProfileRef = _firestore.collection('userProfiles').doc(parentUid);

    final now = DateTime.now();
    final family = Family(
      id: familyRef.id,
      name: name,
      parentIds: [parentUid],
      childIds: [],
      createdAt: now,
      schemaVersion: '1.0.0',
    );

    final parentUser = ParentUser(
      uid: parentUid,
      displayName: parentDisplayName,
      familyId: familyRef.id,
      isOwner: true,
      createdAt: now,
    );

    // Use batch write for atomicity
    final batch = _firestore.batch();

    batch.set(familyRef, family.toJson()..remove('id'));
    batch.set(userProfileRef, parentUser.toJson());

    await batch.commit();

    return family;
  }

  @override
  Future<void> addParent({
    required String familyId,
    required String parentUid,
    required String parentDisplayName,
    bool isOwner = false,
  }) async {
    final familyRef = _firestore.collection('families').doc(familyId);
    final userProfileRef = _firestore.collection('userProfiles').doc(parentUid);

    final now = DateTime.now();
    final parentUser = ParentUser(
      uid: parentUid,
      displayName: parentDisplayName,
      familyId: familyId,
      isOwner: isOwner,
      createdAt: now,
    );

    final batch = _firestore.batch();

    // Add parent UID to family's parentIds array
    batch.update(familyRef, {
      'parentIds': FieldValue.arrayUnion([parentUid]),
    });

    // Create user profile
    batch.set(userProfileRef, parentUser.toJson());

    await batch.commit();
  }

  @override
  Future<Child> addChild({
    required String familyId,
    required String displayName,
    required String avatarEmoji,
  }) async {
    final familyRef = _firestore.collection('families').doc(familyId);
    final childRef = familyRef.collection('children').doc();

    final now = DateTime.now();
    final child = Child(
      id: childRef.id,
      familyId: familyId,
      displayName: displayName,
      avatarEmoji: avatarEmoji,
      createdAt: now,
    );

    final batch = _firestore.batch();

    // Create child document
    batch.set(childRef, child.toJson()..remove('id'));

    // Add child ID to family's childIds array
    batch.update(familyRef, {
      'childIds': FieldValue.arrayUnion([childRef.id]),
    });

    // Initialize three buckets for the child
    final buckets = ['money', 'investment', 'charity'];
    for (final bucketType in buckets) {
      final bucketRef = childRef.collection('buckets').doc(bucketType);
      batch.set(bucketRef, {
        'childId': childRef.id,
        'familyId': familyId,
        'type': bucketType,
        'balance': 0.0,
        'lastUpdatedAt': Timestamp.fromDate(now),
      });
    }

    await batch.commit();

    return child;
  }
}
