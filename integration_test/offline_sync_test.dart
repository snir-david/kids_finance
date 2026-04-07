// Integration tests for offline sync behavior (Sprint 5D).
//
// Prerequisites:
//   - All 7 tests use InMemoryOfflineQueue + FakeFirebaseFirestore.
//   - No Firebase emulator required.
//
// What is tested:
//   - Operations are enqueued when offline (not written to Firestore)
//   - SyncEngine.syncPending applies queued ops when coming back online
//   - Conflict detection: server value changed since the op was queued
//   - Conflict resolution: useLocal applies queued value; useServer discards it
//   - TTL: operations aged ≥ 23h appear in getExpiring()

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kids_finance/core/offline/conflict.dart';
import 'package:kids_finance/core/offline/pending_operation.dart';
import 'package:kids_finance/core/offline/sync_engine.dart';
import 'package:kids_finance/features/buckets/data/firebase_bucket_repository.dart';
import 'package:kids_finance/features/children/data/firebase_child_repository.dart';
import 'helpers.dart';

// ---------------------------------------------------------------------------
// Helper: enqueue a PendingOperation with an explicit createdAt timestamp.
// Used for TTL boundary tests where we need to simulate aged operations.
// ---------------------------------------------------------------------------
Future<void> enqueueAt(
  InMemoryOfflineQueue queue, {
  required String type,
  required Map<String, dynamic> payload,
  required DateTime createdAt,
}) async {
  await queue.enqueue(PendingOperation(
    id: 'test-op-${createdAt.microsecondsSinceEpoch}',
    type: type,
    payload: payload,
    createdAt: createdAt,
    retryCount: 0,
  ));
}

void main() {
  const familyId = 'family-test';
  const childId = 'child-test';
  const parentUid = 'parent-uid';

  late FakeFirebaseFirestore fakeFirestore;
  late InMemoryOfflineQueue queue;

  setUp(() async {
    fakeFirestore = FakeFirebaseFirestore();
    queue = InMemoryOfflineQueue();

    await seedBuckets(
      fakeFirestore,
      familyId: familyId,
      childId: childId,
      money: 100.0,
      investment: 200.0,
      charity: 50.0,
    );
  });

  group('Offline Sync — enqueue while offline', () {
    test('Going offline: addMoney enqueues an operation instead of writing',
        () async {
      final repository = FirebaseBucketRepository(
        firestore: fakeFirestore,
        connectivity: FakeOfflineConnectivity(),
        queue: queue,
      );

      await repository.addMoney(
        childId: childId,
        familyId: familyId,
        amount: 25.0,
        performedByUid: parentUid,
      );

      // Firestore should be unchanged — op was queued, not written
      final balance = await readBalance(fakeFirestore,
          familyId: familyId, childId: childId, bucketType: 'money');
      expect(balance, equals(100.0),
          reason: 'Firestore should be unchanged while offline');
      expect(queue.count, equals(1));
      expect(queue.getPending().first.type, equals('addMoney'));
    });

    test('Going offline: distributeFunds enqueues a distribute operation',
        () async {
      final repository = FirebaseBucketRepository(
        firestore: fakeFirestore,
        connectivity: FakeOfflineConnectivity(),
        queue: queue,
      );

      await repository.distributeFunds(
        familyId: familyId,
        childId: childId,
        moneyAmount: 50.0,
        investmentAmount: 30.0,
        charityAmount: 20.0,
        performedByUid: parentUid,
      );

      expect(queue.count, equals(1));
      expect(queue.getPending().first.type, equals('distribute'));
      final money = await readBalance(fakeFirestore,
          familyId: familyId, childId: childId, bucketType: 'money');
      expect(money, equals(100.0));
    });
  });

  group('Offline Sync — SyncEngine.syncPending (come back online)', () {
    late FirebaseBucketRepository onlineRepo;
    late SyncEngine syncEngine;

    setUp(() {
      onlineRepo = FirebaseBucketRepository(
        firestore: fakeFirestore,
        connectivity: FakeOnlineConnectivity(),
        queue: queue,
      );
      syncEngine = SyncEngine(
        queue: queue,
        firestore: fakeFirestore,
        bucketRepo: onlineRepo,
        childRepo: FirebaseChildRepository(
          firestore: fakeFirestore,
          connectivity: FakeOnlineConnectivity(),
          queue: queue,
        ),
      );
    });

    test('Sync: addMoney op applied to Firestore, removed from queue',
        () async {
      await enqueueAt(queue,
          type: 'addMoney',
          payload: {
            'childId': childId,
            'familyId': familyId,
            'amount': 25.0,
            'performedByUid': parentUid,
            'note': null,
          },
          createdAt: DateTime.now());

      expect(queue.count, equals(1));
      final conflicts = await syncEngine.syncPending();

      expect(conflicts, isEmpty);
      expect(queue.count, equals(0));
      final balance = await readBalance(fakeFirestore,
          familyId: familyId, childId: childId, bucketType: 'money');
      expect(balance, equals(125.0), reason: '100 + 25 = 125 after sync');
    });

    test('Sync: setMoney with no conflict (baseValue matches server) → applied',
        () async {
      // Server balance is 100. baseValue=100 → no conflict.
      await enqueueAt(queue,
          type: 'setMoney',
          payload: {
            'childId': childId,
            'familyId': familyId,
            'newBalance': 80.0,
            'performedByUid': parentUid,
            'note': null,
            'baseValue': 100.0,
          },
          createdAt: DateTime.now());

      final conflicts = await syncEngine.syncPending();

      expect(conflicts, isEmpty);
      final balance = await readBalance(fakeFirestore,
          familyId: familyId, childId: childId, bucketType: 'money');
      expect(balance, equals(80.0));
    });

    test(
        'Sync: setMoney with conflict (server changed since queue) → '
        'BucketConflict returned, op NOT applied', () async {
      // Server is 100, but op recorded baseValue=50 → server changed → conflict
      await enqueueAt(queue,
          type: 'setMoney',
          payload: {
            'childId': childId,
            'familyId': familyId,
            'newBalance': 75.0,
            'performedByUid': parentUid,
            'note': null,
            'baseValue': 50.0,
          },
          createdAt: DateTime.now());

      final conflicts = await syncEngine.syncPending();

      expect(conflicts, hasLength(1));
      final conflict = conflicts.first;
      expect(conflict.bucketType, equals('money'));
      expect(conflict.localValue, equals(75.0));
      expect(conflict.serverValue, equals(100.0));
      expect(queue.count, equals(1),
          reason: 'Conflicted op must remain in queue until resolved');
    });

    test(
        'Sync: resolveConflict(useLocal) → applies local value, removes from queue',
        () async {
      await enqueueAt(queue,
          type: 'setMoney',
          payload: {
            'childId': childId,
            'familyId': familyId,
            'newBalance': 75.0,
            'performedByUid': parentUid,
            'note': null,
            'baseValue': 50.0,
          },
          createdAt: DateTime.now());

      final conflicts = await syncEngine.syncPending();
      final opId = conflicts.first.operationId;

      await syncEngine.resolveConflict(opId, ConflictResolution.useLocal);

      final balance = await readBalance(fakeFirestore,
          familyId: familyId, childId: childId, bucketType: 'money');
      expect(balance, equals(75.0));
      expect(queue.count, equals(0));
    });

    test(
        'Sync: resolveConflict(useServer) → discards op, Firestore unchanged',
        () async {
      await enqueueAt(queue,
          type: 'setMoney',
          payload: {
            'childId': childId,
            'familyId': familyId,
            'newBalance': 75.0,
            'performedByUid': parentUid,
            'note': null,
            'baseValue': 50.0,
          },
          createdAt: DateTime.now());

      final conflicts = await syncEngine.syncPending();
      final opId = conflicts.first.operationId;

      await syncEngine.resolveConflict(opId, ConflictResolution.useServer);

      final balance = await readBalance(fakeFirestore,
          familyId: familyId, childId: childId, bucketType: 'money');
      expect(balance, equals(100.0),
          reason: 'Server value preserved after useServer resolution');
      expect(queue.count, equals(0));
    });
  });

  group('Offline Sync — TTL expiry warnings', () {
    test('getExpiring: op aged ≥ 23h appears in expiring list', () async {
      await enqueueAt(queue,
          type: 'addMoney',
          payload: {
            'childId': childId,
            'familyId': familyId,
            'amount': 10.0,
            'performedByUid': parentUid,
            'note': null,
          },
          createdAt: DateTime.now().subtract(
            const Duration(hours: 23, minutes: 30),
          ));

      final expiring = queue.getExpiring();
      expect(expiring, hasLength(1),
          reason: 'Op that is 23.5h old should appear in expiring list');
    });

    test('getExpiring: op aged < 23h does NOT appear in expiring list',
        () async {
      await enqueueAt(queue,
          type: 'addMoney',
          payload: {
            'childId': childId,
            'familyId': familyId,
            'amount': 10.0,
            'performedByUid': parentUid,
            'note': null,
          },
          createdAt: DateTime.now().subtract(const Duration(hours: 22)));

      final expiring = queue.getExpiring();
      expect(expiring, isEmpty,
          reason: 'Op that is only 22h old should NOT be in expiring list');
    });
  });
}
