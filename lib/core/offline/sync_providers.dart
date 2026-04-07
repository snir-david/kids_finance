import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/buckets/providers/buckets_providers.dart';
import '../../features/children/providers/children_providers.dart';
import 'conflict.dart';
import 'connectivity_provider.dart';
import 'offline_queue.dart';
import 'pending_operation.dart';
import 'sync_engine.dart';

final offlineQueueProvider = Provider<OfflineQueue>((ref) {
  return OfflineQueue();
});

final syncEngineProvider = Provider<SyncEngine>((ref) {
  return SyncEngine(
    queue: ref.watch(offlineQueueProvider),
    firestore: FirebaseFirestore.instance,
    bucketRepo: ref.watch(bucketRepositoryProvider),
    childRepo: ref.watch(childRepositoryProvider),
  );
});

class PendingOperationsNotifier extends Notifier<List<PendingOperation>> {
  @override
  List<PendingOperation> build() {
    return ref.read(offlineQueueProvider).getPending();
  }

  Future<void> enqueue(PendingOperation op) async {
    final queue = ref.read(offlineQueueProvider);
    await queue.enqueue(op);
    state = queue.getPending();
  }

  Future<void> remove(String id) async {
    final queue = ref.read(offlineQueueProvider);
    await queue.remove(id);
    state = queue.getPending();
  }

  void refresh() {
    state = ref.read(offlineQueueProvider).getPending();
  }
}

final pendingOperationsProvider =
    NotifierProvider<PendingOperationsNotifier, List<PendingOperation>>(
        PendingOperationsNotifier.new);

class PendingConflictsNotifier extends Notifier<List<BucketConflict>> {
  @override
  List<BucketConflict> build() => [];

  void addConflicts(List<BucketConflict> conflicts) {
    state = [...state, ...conflicts];
  }

  void removeConflict(String operationId) {
    state = state.where((c) => c.operationId != operationId).toList();
  }
}

final pendingConflictsProvider =
    NotifierProvider<PendingConflictsNotifier, List<BucketConflict>>(
        PendingConflictsNotifier.new);

// Activate this provider at app startup to enable auto-sync.
// Watches connectivity and triggers sync when transitioning offline -> online.
final autoSyncProvider = Provider<void>((ref) {
  ref.listen<AsyncValue<bool>>(connectivityProvider, (prev, next) async {
    final wasOnline = prev?.maybeWhen(data: (v) => v, orElse: () => null);
    final isNowOnline = next.maybeWhen(data: (v) => v, orElse: () => null);
    if (wasOnline == false && isNowOnline == true) {
      final conflicts = await ref.read(syncEngineProvider).syncPending();
      if (conflicts.isNotEmpty) {
        ref.read(pendingConflictsProvider.notifier).addConflicts(conflicts);
      }
      ref.read(pendingOperationsProvider.notifier).refresh();
    }
  });
});
