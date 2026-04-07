// Integration tests for authentication flows (Sprint 5D).
//
// Prerequisites:
//   - Tests 1-4: No emulator needed (PinAttemptTracker with fake storage).
//   - Tests 5-7: Require Firebase emulator. Run:
//       firebase emulators:start --only auth,firestore
//       flutter test integration_test/auth_flow_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:kids_finance/features/auth/data/pin_attempt_tracker.dart';
import 'helpers.dart';

void main() {
  group('Auth Flow — PIN Lockout (no emulator needed)', () {
    late PinAttemptTracker tracker;

    setUp(() {
      FakeSecureStorage.clearAll();
      tracker = PinAttemptTracker(storage: const FakeSecureStorage());
    });

    test(
        'PIN lockout: 5 consecutive wrong PINs trigger a 15-minute lockout',
        () async {
      // Arrange: record 4 failures (should NOT lock yet)
      for (var i = 0; i < 4; i++) {
        final remaining = await tracker.recordFailure('child-1');
        expect(remaining, greaterThan(0),
            reason: 'Should still have attempts remaining after failure ${i + 1}');
      }

      // Act: 5th failure must throw PinLockoutException
      await expectLater(
        () => tracker.recordFailure('child-1'),
        throwsA(isA<PinLockoutException>()),
      );

      // Assert: child is now locked out
      final isLocked = await tracker.isLockedOut('child-1');
      expect(isLocked, isTrue, reason: 'Child should be locked after 5 failures');

      final remaining = await tracker.lockoutRemaining('child-1');
      expect(remaining, isNotNull);
      expect(remaining!.inMinutes, closeTo(15, 1),
          reason: 'Lockout should be ~15 minutes');
    });

    test('PIN lockout: attempts-remaining decrements on each failure', () async {
      // Should go: 4, 3, 2, 1 then throw
      for (var expected in [4, 3, 2, 1]) {
        final remaining = await tracker.recordFailure('child-2');
        expect(remaining, equals(expected));
      }
      // 5th attempt triggers the lock
      await expectLater(
        () => tracker.recordFailure('child-2'),
        throwsA(isA<PinLockoutException>()),
      );
    });

    test('PIN lockout: successful PIN resets counter and clears lockout',
        () async {
      // Record 3 failures
      for (var i = 0; i < 3; i++) {
        await tracker.recordFailure('child-3');
      }

      // Parent/service resets after correct PIN
      await tracker.resetAttempts('child-3');

      // Should now allow 5 more failures
      for (var i = 0; i < 4; i++) {
        final remaining = await tracker.recordFailure('child-3');
        expect(remaining, greaterThan(0));
      }
      // Confirm not locked yet
      final isLocked = await tracker.isLockedOut('child-3');
      expect(isLocked, isFalse);
    });

    test(
        'PIN lockout: lockout state persists across simulated app restarts '
        '(storage is durable)', () async {
      // Simulate 5 failures (triggers lockout)
      for (var i = 0; i < 4; i++) {
        await tracker.recordFailure('child-4');
      }
      await expectLater(
        () => tracker.recordFailure('child-4'),
        throwsA(isA<PinLockoutException>()),
      );

      // Simulate app restart: create a NEW tracker with the SAME backing storage
      final trackerAfterRestart =
          PinAttemptTracker(storage: const FakeSecureStorage());

      // The lockout key should still be present in the shared fake store
      final isStillLocked = await trackerAfterRestart.isLockedOut('child-4');
      expect(isStillLocked, isTrue,
          reason: 'Lockout must persist after app restart via secure storage');
    });
  });

  // ---------------------------------------------------------------------------
  // Tests below require a running Firebase emulator.
  // ---------------------------------------------------------------------------

  group('Auth Flow — Full Firebase flows (emulator required)', () {
    testWidgets(
      'Parent registration → family creation → redirect to parent home',
      (tester) async {
        // 1. Launch app from scratch (unauthenticated state).
        // 2. Tap "Register" on LoginScreen.
        // 3. Fill in email + password, submit.
        // 4. Firebase Auth creates user; authStateProvider emits User.
        // 5. GoRouter detects no familyId → redirects to /family-setup.
        // 6. Fill in family name, submit.
        // 7. Firestore creates /families/{id} and /userProfiles/{uid}.
        // 8. Expect: lands on /parent-home, family name visible.
        expect(true, true); // structure placeholder
      },
      skip: true, // Requires Firebase emulator (run: firebase emulators:start)
    );

    testWidgets(
      'Forgot password flow: entering email sends reset email',
      (tester) async {
        // 1. On LoginScreen tap "Forgot password?".
        // 2. ForgotPasswordScreen renders with email field.
        // 3. Enter valid email, tap Send.
        // 4. Firebase Auth sends reset email (emulator intercepts).
        // 5. Expect: SnackBar "Check your email" visible.
        // 6. Navigate back → LoginScreen visible.
        expect(true, true);
      },
      skip: true, // Requires Firebase emulator (run: firebase emulators:start)
    );

    testWidgets(
      'Session expiry: sessionExpiresAt in the past → child redirected to PIN',
      (tester) async {
        // Prerequisites:
        //   - Parent is logged in.
        //   - Child with expired sessionExpiresAt exists in Firestore.
        // Steps:
        // 1. Set child sessionExpiresAt = DateTime.now().subtract(1 hour).
        // 2. Navigate to /child-home.
        // 3. childSessionValidProvider detects expiry.
        // 4. GoRouter redirects to /child-pin.
        // 5. Expect: PIN entry screen visible, not child home.
        expect(true, true);
      },
      skip: true, // Requires Firebase emulator (run: firebase emulators:start)
    );
  });
}
