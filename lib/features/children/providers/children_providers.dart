/// Riverpod providers for child-related functionality.
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/child.dart';
import '../domain/child_repository.dart';
import '../data/firebase_child_repository.dart';
import '../../../core/offline/connectivity_provider.dart';
import '../../../core/offline/sync_providers.dart';

/// Repository provider
final childRepositoryProvider = Provider<ChildRepository>((ref) {
  return FirebaseChildRepository(
    connectivity: ref.watch(connectivityServiceProvider),
    queue: ref.watch(offlineQueueProvider),
  );
});

/// Stream provider for all children in a family (excludes archived children)
final childrenProvider =
    StreamProvider.family<List<Child>, String>((ref, familyId) {
  return FirebaseFirestore.instance
      .collection('families')
      .doc(familyId)
      .collection('children')
      .snapshots()
      .map((snapshot) {
    return snapshot.docs
        .map((doc) => Child.fromJson({'id': doc.id, ...doc.data()}))
        .where((c) => !c.archived)
        .toList();
  });
});

/// Stream provider for a specific child
final childProvider =
    StreamProvider.family<Child?, ({String childId, String familyId})>(
        (ref, params) {
  final repository = ref.watch(childRepositoryProvider);
  return repository.getChildStream(params.childId, params.familyId);
});

/// Notifier for the currently selected child ID
class SelectedChildNotifier extends Notifier<String?> {
  SelectedChildNotifier([this._initial]);
  final String? _initial;

  @override
  String? build() => _initial;

  void setState(String? value) => state = value;
}

/// State provider for the currently selected child ID
final selectedChildProvider =
    NotifierProvider<SelectedChildNotifier, String?>(SelectedChildNotifier.new);
