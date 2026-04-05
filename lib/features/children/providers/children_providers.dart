/// Riverpod providers for child-related functionality.
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/child.dart';
import '../domain/child_repository.dart';
import '../data/firebase_child_repository.dart';

/// Repository provider
final childRepositoryProvider = Provider<ChildRepository>((ref) {
  return FirebaseChildRepository(firestore: FirebaseFirestore.instance);
});

/// Stream provider for all children in a family
final childrenProvider =
    StreamProvider.family<List<Child>, String>((ref, familyId) {
  return FirebaseFirestore.instance
      .collection('families')
      .doc(familyId)
      .collection('children')
      .snapshots()
      .map((snapshot) {
    return snapshot.docs.map((doc) {
      return Child.fromJson({
        'id': doc.id,
        ...doc.data(),
      });
    }).toList();
  });
});

/// Stream provider for a specific child
final childProvider =
    StreamProvider.family<Child?, ({String childId, String familyId})>(
        (ref, params) {
  final repository = ref.watch(childRepositoryProvider);
  return repository.getChildStream(params.childId, params.familyId);
});

/// State provider for the currently selected child ID
final selectedChildProvider = StateProvider<String?>((ref) => null);
