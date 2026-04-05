import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../domain/child.dart';
import '../domain/child_repository.dart';
import '../data/firebase_child_repository.dart';

part 'children_providers.g.dart';

/// Repository provider
@riverpod
ChildRepository childRepository(ChildRepositoryRef ref) {
  return FirebaseChildRepository(firestore: FirebaseFirestore.instance);
}

/// Stream provider for all children in a family
@riverpod
Stream<List<Child>> children(ChildrenRef ref, String familyId) {
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
}

/// Stream provider for a specific child
@riverpod
Stream<Child?> child(ChildRef ref, String childId, String familyId) {
  final repository = ref.watch(childRepositoryProvider);
  return repository.getChildStream(childId, familyId);
}

/// State provider for the currently selected child ID
@riverpod
class SelectedChild extends _$SelectedChild {
  @override
  String? build() => null;

  void select(String? childId) {
    state = childId;
  }

  void clear() {
    state = null;
  }
}
