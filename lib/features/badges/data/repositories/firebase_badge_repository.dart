import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/badge_model.dart';
import 'badge_repository.dart';

class FirebaseBadgeRepository implements BadgeRepository {
  FirebaseBadgeRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _badgesRef(
    String familyId,
    String childId,
  ) =>
      _firestore
          .collection('families')
          .doc(familyId)
          .collection('children')
          .doc(childId)
          .collection('badges');

  @override
  Stream<List<Badge>> watchBadges(String familyId, String childId) {
    return _badgesRef(familyId, childId)
        .orderBy('earnedAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Badge.fromFirestore(doc)).toList());
  }

  @override
  Future<void> awardBadge(
    String familyId,
    String childId,
    BadgeType type,
  ) async {
    final already = await hasBadge(familyId, childId, type);
    if (already) return;

    await _badgesRef(familyId, childId).add({
      'type': type.name,
      'earnedAt': Timestamp.fromDate(DateTime.now()),
      'seen': false,
    });
  }

  @override
  Future<void> markSeen(
    String familyId,
    String childId,
    String badgeId,
  ) async {
    await _badgesRef(familyId, childId).doc(badgeId).update({'seen': true});
  }

  @override
  Future<bool> hasBadge(
    String familyId,
    String childId,
    BadgeType type,
  ) async {
    final snapshot = await _badgesRef(familyId, childId)
        .where('type', isEqualTo: type.name)
        .limit(1)
        .get();
    return snapshot.docs.isNotEmpty;
  }
}
