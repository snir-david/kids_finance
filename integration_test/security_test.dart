// Integration tests for security boundaries (Sprint 5D).
//
// Prerequisites:
//   - Tests 1-2, 4, 6: No emulator needed.
//   - Tests 3, 5: Require Firebase emulator for Firestore rules enforcement.
//
// What is tested:
//   - Family isolation: repositories read only from their own family path
//   - PIN lockout state persists across simulated app restarts
//   - Firestore security rules reject unauthenticated writes (emulator)
//   - Investment multiplier zero guard enforced at repository level
//   - JWT spoofing defense via custom claims (emulator)
//   - Child cannot access another family's bucket data

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kids_finance/features/auth/data/pin_attempt_tracker.dart';
import 'package:kids_finance/features/buckets/data/firebase_bucket_repository.dart';
import 'package:kids_finance/features/children/data/firebase_child_repository.dart';
import 'helpers.dart';

void main() {
  group('Security — Family Data Isolation', () {
    test(
        'Repository: parent cannot read children from a different family '
        '(path isolation)', () async {
      final fakeFirestore = FakeFirebaseFirestore();

      // Seed two separate families
      await seedChild(
        fakeFirestore,
        familyId: 'family-A',
        childId: 'child-A1',
        displayName: 'Alice',
      );
      await seedChild(
        fakeFirestore,
        familyId: 'family-B',
        childId: 'child-B1',
        displayName: 'Bob',
      );

      final connectivity = FakeOnlineConnectivity();
      final queue = InMemoryOfflineQueue();
      final childRepo = FirebaseChildRepository(
        firestore: fakeFirestore,
        connectivity: connectivity,
        queue: queue,
      );

      // Family A repository reads its own child → found
      final childA = await childRepo
          .getChildStream('child-A1', 'family-A')
          .first;
      expect(childA, isNotNull);
      expect(childA!.displayName, equals('Alice'));

      // Attempting to read family-B's child using family-A's path → null
      // (child-A1 does not exist under family-B)
      final wrongFamily = await childRepo
          .getChildStream('child-A1', 'family-B')
          .first;
      expect(wrongFamily, isNull,
          reason: 'Cross-family read should return null due to path isolation');
    });

    test(
        'Repository: child cannot read bucket data from another family '
        '(path isolation)', () async {
      final fakeFirestore = FakeFirebaseFirestore();

      await seedBuckets(
        fakeFirestore,
        familyId: 'family-A',
        childId: 'child-A1',
        money: 500.0,
      );

      final connectivity = FakeOnlineConnectivity();
      final queue = InMemoryOfflineQueue();
      final bucketRepo = FirebaseBucketRepository(
        firestore: fakeFirestore,
        connectivity: connectivity,
        queue: queue,
      );

      // Correct family → returns buckets
      final correctStream = bucketRepo.getBucketsStream(
        childId: 'child-A1',
        familyId: 'family-A',
      );
      final correctBuckets = await correctStream.first;
      expect(correctBuckets, isNotEmpty);

      // Wrong family → empty list (no buckets seeded at that path)
      final wrongStream = bucketRepo.getBucketsStream(
        childId: 'child-A1',
        familyId: 'family-B', // wrong family
      );
      final wrongBuckets = await wrongStream.first;
      expect(wrongBuckets, isEmpty,
          reason: 'Bucket read from wrong family must return empty');
    });
  });

  group('Security — Firestore Rules (emulator required)', () {
    test(
      'Firestore rules: unauthenticated write to /families/{id} is rejected',
      () async {
        // Steps:
        // 1. Initialize Firebase pointing to local Firestore emulator.
        // 2. Attempt a direct write to /families/test-family without auth.
        // 3. Expect: FirebaseException with code 'permission-denied'.
        expect(true, true);
      },
      skip: true, // Requires Firebase emulator (run: firebase emulators:start)
    );

    test(
      'Security: JWT spoofing — custom claims enforce role, '
      'child role cannot write to bucket',
      () async {
        // Steps:
        // 1. Sign in as child user (role=child in claims) via emulator.
        // 2. Attempt to call setMoneyBalance directly on Firestore.
        // 3. Expect: PERMISSION_DENIED — Firestore rules block child writes.
        expect(true, true);
      },
      skip: true, // Requires Firebase emulator (run: firebase emulators:start)
    );

    test(
      'Security: parent from family-A cannot write to family-B buckets',
      () async {
        // Steps:
        // 1. Sign in as parent of family-A.
        // 2. Attempt to write to /families/family-B/children/child/buckets.
        // 3. Expect: PERMISSION_DENIED — Firestore rules enforce familyId match.
        expect(true, true);
      },
      skip: true, // Requires Firebase emulator (run: firebase emulators:start)
    );
  });

  group('Security — PIN Lockout Persistence', () {
    test(
        'PIN lockout persists across simulated app restarts '
        '(secure storage survives restart)', () async {
      FakeSecureStorage.clearAll();
      final tracker = PinAttemptTracker(storage: const FakeSecureStorage());

      // Trigger a lockout via 5 failures
      for (var i = 0; i < 4; i++) {
        await tracker.recordFailure('child-secure');
      }
      await expectLater(
        () => tracker.recordFailure('child-secure'),
        throwsA(isA<PinLockoutException>()),
      );

      // Simulate app restart: new tracker instance, same FakeSecureStorage
      // (FakeSecureStorage._globalStore is static, so state is shared)
      final trackerAfterRestart =
          PinAttemptTracker(storage: const FakeSecureStorage());

      final isLocked = await trackerAfterRestart.isLockedOut('child-secure');
      expect(isLocked, isTrue,
          reason: 'Lockout must still be active after restart');

      final remaining = await trackerAfterRestart.lockoutRemaining('child-secure');
      expect(remaining, isNotNull);
      expect(remaining!.inMinutes, greaterThan(0));
    });

    test('PIN lockout: expired lockout (>15min) is automatically cleared',
        () async {
      FakeSecureStorage.clearAll();
      // Manually write an expired lockout timestamp to simulate expiry
      // (in practice, time passes; here we write a past timestamp directly)
      const storage = FakeSecureStorage();
      final pastTime =
          DateTime.now().subtract(const Duration(minutes: 16)).toIso8601String();
      await storage.write(
        key: 'pin_lockout_until_child-expired',
        value: pastTime,
      );

      final trackerWithExpiredLock =
          PinAttemptTracker(storage: const FakeSecureStorage());
      final isLocked =
          await trackerWithExpiredLock.isLockedOut('child-expired');
      expect(isLocked, isFalse,
          reason: 'Expired lockout (16min ago) should no longer be active');
    });
  });

  group('Security — Input Validation Guards', () {
    test('multiplyInvestment: zero multiplier is rejected at repository level',
        () async {
      final fakeFirestore = FakeFirebaseFirestore();
      await seedBuckets(
        fakeFirestore,
        familyId: 'family-test',
        childId: 'child-test',
        investment: 100.0,
      );
      final repo = FirebaseBucketRepository(
        firestore: fakeFirestore,
        connectivity: FakeOnlineConnectivity(),
        queue: InMemoryOfflineQueue(),
      );

      await expectLater(
        () => repo.multiplyInvestment(
          childId: 'child-test',
          familyId: 'family-test',
          multiplier: 0.0,
          performedByUid: 'parent-uid',
        ),
        throwsA(isA<ArgumentError>()),
        reason: 'Multiplier of 0 must be rejected — zero-amount validation',
      );
    });

    test('distributeFunds: negative amounts are rejected at repository level',
        () async {
      final fakeFirestore = FakeFirebaseFirestore();
      await seedBuckets(
        fakeFirestore,
        familyId: 'family-test',
        childId: 'child-test',
      );
      final repo = FirebaseBucketRepository(
        firestore: fakeFirestore,
        connectivity: FakeOnlineConnectivity(),
        queue: InMemoryOfflineQueue(),
      );

      await expectLater(
        () => repo.distributeFunds(
          familyId: 'family-test',
          childId: 'child-test',
          moneyAmount: -10.0,
          investmentAmount: 0.0,
          charityAmount: 0.0,
          performedByUid: 'parent-uid',
        ),
        throwsA(isA<ArgumentError>()),
      );
    });
  });
}
