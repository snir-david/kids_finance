import 'package:bcrypt/bcrypt.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/child.dart';
import '../domain/child_repository.dart';
import '../../../core/offline/connectivity_service.dart';
import '../../../core/offline/offline_queue.dart';
import '../../../core/offline/pending_operation.dart';

class FirebaseChildRepository implements ChildRepository {
  final FirebaseFirestore _firestore;
  final ConnectivityService _connectivity;
  final OfflineQueue _queue;

  FirebaseChildRepository({
    FirebaseFirestore? firestore,
    required ConnectivityService connectivity,
    required OfflineQueue queue,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _connectivity = connectivity,
        _queue = queue;

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
    if (!await _connectivity.isOnline) {
      final payload = <String, dynamic>{
        'childId': childId,
        'familyId': familyId,
        if (name != null) 'name': name,
        if (avatarEmoji != null) 'avatarEmoji': avatarEmoji,
        if (newPin != null) 'pinHash': BCrypt.hashpw(newPin, BCrypt.gensalt()),
      };
      await _queue.enqueue(PendingOperation(
        id: _queue.generateId(),
        type: 'updateChild',
        payload: payload,
        createdAt: DateTime.now(),
        retryCount: 0,
      ));
      return;
    }

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
    if (!await _connectivity.isOnline) {
      await _queue.enqueue(PendingOperation(
        id: _queue.generateId(),
        type: 'archiveChild',
        payload: {'childId': childId, 'familyId': familyId},
        createdAt: DateTime.now(),
        retryCount: 0,
      ));
      return;
    }

    await _firestore
        .collection('families')
        .doc(familyId)
        .collection('children')
        .doc(childId)
        .update({'archived': true});
  }
}
