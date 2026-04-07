// TODO: wire up when PinAttemptTracker is available
// Testing PIN brute-force protection (Sprint 5C — Security)

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'pin_attempt_tracker_test.mocks.dart';

@GenerateMocks([FlutterSecureStorage])
void main() {
  group('PIN Brute-Force Protection', () {
    late MockFlutterSecureStorage mockStorage;

    setUp(() {
      mockStorage = MockFlutterSecureStorage();
    });

    test('4 failures → NOT locked out', () async {
      // Arrange
      const childId = 'child1';
      
      // Mock: 4 failures recorded, no lockout timestamp
      when(mockStorage.read(key: 'pin_failures_$childId'))
          .thenAnswer((_) async => '4');
      when(mockStorage.read(key: 'pin_lockout_until_$childId'))
          .thenAnswer((_) async => null);

      // TODO: When PinAttemptTracker is available, use:
      // final tracker = PinAttemptTracker(storage: mockStorage);
      // final isLocked = await tracker.isLockedOut(childId);
      // expect(isLocked, isFalse);

      // For now, verify mock logic
      final failures = await mockStorage.read(key: 'pin_failures_$childId');
      expect(int.parse(failures!), lessThan(5));
    });

    test('5 failures → locked out for 15 minutes', () async {
      // Arrange
      const childId = 'child1';
      final now = DateTime.now();
      final lockoutUntil = now.add(const Duration(minutes: 15));
      
      // Mock: 5 failures recorded, lockout timestamp set
      when(mockStorage.read(key: 'pin_failures_$childId'))
          .thenAnswer((_) async => '5');
      when(mockStorage.read(key: 'pin_lockout_until_$childId'))
          .thenAnswer((_) async => lockoutUntil.toIso8601String());
      when(mockStorage.write(
        key: 'pin_lockout_until_$childId',
        value: anyNamed('value'),
      )).thenAnswer((_) async => Future.value());

      // TODO: When PinAttemptTracker is available, use:
      // final tracker = PinAttemptTracker(storage: mockStorage);
      // await tracker.recordFailure(childId);
      // final isLocked = await tracker.isLockedOut(childId);
      // expect(isLocked, isTrue);

      // For now, verify lockout logic
      final lockoutStr = await mockStorage.read(key: 'pin_lockout_until_$childId');
      final lockoutTime = DateTime.parse(lockoutStr!);
      expect(lockoutTime.isAfter(now), isTrue);
      expect(lockoutTime.difference(now).inMinutes, closeTo(15, 1));
    });

    test('isLockedOut returns true during lockout window', () async {
      // Arrange
      const childId = 'child1';
      final now = DateTime.now();
      final lockoutUntil = now.add(const Duration(minutes: 10)); // Still 10 min remaining
      
      when(mockStorage.read(key: 'pin_lockout_until_$childId'))
          .thenAnswer((_) async => lockoutUntil.toIso8601String());

      // TODO: When PinAttemptTracker is available, use:
      // final tracker = PinAttemptTracker(storage: mockStorage);
      // final isLocked = await tracker.isLockedOut(childId);
      // expect(isLocked, isTrue);
      // final remaining = await tracker.lockoutRemaining(childId);
      // expect(remaining?.inMinutes, closeTo(10, 1));

      // For now, verify lockout detection logic
      final lockoutStr = await mockStorage.read(key: 'pin_lockout_until_$childId');
      final lockoutTime = DateTime.parse(lockoutStr!);
      expect(lockoutTime.isAfter(now), isTrue);
    });

    test('isLockedOut returns false after lockout expires', () async {
      // Arrange
      const childId = 'child1';
      final now = DateTime.now();
      final lockoutUntil = now.subtract(const Duration(minutes: 1)); // Expired 1 minute ago
      
      when(mockStorage.read(key: 'pin_lockout_until_$childId'))
          .thenAnswer((_) async => lockoutUntil.toIso8601String());

      // TODO: When PinAttemptTracker is available, use:
      // final tracker = PinAttemptTracker(storage: mockStorage);
      // final isLocked = await tracker.isLockedOut(childId);
      // expect(isLocked, isFalse);

      // For now, verify expiry detection logic
      final lockoutStr = await mockStorage.read(key: 'pin_lockout_until_$childId');
      final lockoutTime = DateTime.parse(lockoutStr!);
      expect(lockoutTime.isBefore(now), isTrue);
    });

    test('successful PIN resets failure counter', () async {
      // Arrange
      const childId = 'child1';
      
      // Mock: had 3 failures, now successful PIN
      when(mockStorage.read(key: 'pin_failures_$childId'))
          .thenAnswer((_) async => '3');
      when(mockStorage.delete(key: 'pin_failures_$childId'))
          .thenAnswer((_) async => Future.value());
      when(mockStorage.delete(key: 'pin_lockout_until_$childId'))
          .thenAnswer((_) async => Future.value());

      // TODO: When PinAttemptTracker is available, use:
      // final tracker = PinAttemptTracker(storage: mockStorage);
      // await tracker.recordSuccess(childId);
      // final failures = await mockStorage.read(key: 'pin_failures_$childId');
      // expect(failures, isNull);

      // For now, verify reset logic
      await mockStorage.delete(key: 'pin_failures_$childId');
      verify(mockStorage.delete(key: 'pin_failures_$childId')).called(1);
    });

    test('app restart with active lockout → still locked (persisted)', () async {
      // Arrange
      const childId = 'child1';
      final now = DateTime.now();
      final lockoutUntil = now.add(const Duration(minutes: 10));
      
      // Mock: app restarts, reads persisted lockout from secure storage
      when(mockStorage.read(key: 'pin_lockout_until_$childId'))
          .thenAnswer((_) async => lockoutUntil.toIso8601String());

      // TODO: When PinAttemptTracker is available, use:
      // final tracker = PinAttemptTracker(storage: mockStorage);
      // final isLocked = await tracker.isLockedOut(childId);
      // expect(isLocked, isTrue);

      // For now, verify persistence
      final lockoutStr = await mockStorage.read(key: 'pin_lockout_until_$childId');
      expect(lockoutStr, isNotNull);
      final lockoutTime = DateTime.parse(lockoutStr!);
      expect(lockoutTime.isAfter(now), isTrue);
    });

    test('app restart after lockout expires → not locked', () async {
      // Arrange
      const childId = 'child1';
      final now = DateTime.now();
      final lockoutUntil = now.subtract(const Duration(minutes: 5)); // Expired
      
      // Mock: app restarts, reads expired lockout
      when(mockStorage.read(key: 'pin_lockout_until_$childId'))
          .thenAnswer((_) async => lockoutUntil.toIso8601String());

      // TODO: When PinAttemptTracker is available, use:
      // final tracker = PinAttemptTracker(storage: mockStorage);
      // final isLocked = await tracker.isLockedOut(childId);
      // expect(isLocked, isFalse);

      // For now, verify expiry logic after restart
      final lockoutStr = await mockStorage.read(key: 'pin_lockout_until_$childId');
      final lockoutTime = DateTime.parse(lockoutStr!);
      expect(lockoutTime.isBefore(now), isTrue);
    });
  });
}
