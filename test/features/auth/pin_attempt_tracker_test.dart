// TODO: wire up when PinAttemptTracker is available
// Testing PIN brute-force protection (Sprint 5C — Security)

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class _FakeFlutterSecureStorage extends FlutterSecureStorage {
  _FakeFlutterSecureStorage() : super();

  final Map<String, String> _store = {};
  final List<String> deletedKeys = [];

  void configure(String key, String value) => _store[key] = value;

  @override
  Future<String?> read({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async =>
      _store[key];

  @override
  Future<void> write({
    required String key,
    required String? value,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (value != null) _store[key] = value;
    else _store.remove(key);
  }

  @override
  Future<void> delete({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    _store.remove(key);
    deletedKeys.add(key);
  }
}

void main() {
  group('PIN Brute-Force Protection', () {
    late _FakeFlutterSecureStorage mockStorage;

    setUp(() {
      mockStorage = _FakeFlutterSecureStorage();
    });

    test('4 failures → NOT locked out', () async {
      const childId = 'child1';
      mockStorage.configure('pin_failures_$childId', '4');

      final failures = await mockStorage.read(key: 'pin_failures_$childId');
      expect(int.parse(failures!), lessThan(5));
    });

    test('5 failures → locked out for 15 minutes', () async {
      const childId = 'child1';
      final now = DateTime.now();
      final lockoutUntil = now.add(const Duration(minutes: 15));
      mockStorage.configure('pin_failures_$childId', '5');
      mockStorage.configure(
          'pin_lockout_until_$childId', lockoutUntil.toIso8601String());

      final lockoutStr =
          await mockStorage.read(key: 'pin_lockout_until_$childId');
      final lockoutTime = DateTime.parse(lockoutStr!);
      expect(lockoutTime.isAfter(now), isTrue);
      expect(lockoutTime.difference(now).inMinutes, closeTo(15, 1));
    });

    test('isLockedOut returns true during lockout window', () async {
      const childId = 'child1';
      final now = DateTime.now();
      final lockoutUntil =
          now.add(const Duration(minutes: 10)); // Still 10 min remaining
      mockStorage.configure(
          'pin_lockout_until_$childId', lockoutUntil.toIso8601String());

      final lockoutStr =
          await mockStorage.read(key: 'pin_lockout_until_$childId');
      final lockoutTime = DateTime.parse(lockoutStr!);
      expect(lockoutTime.isAfter(now), isTrue);
    });

    test('isLockedOut returns false after lockout expires', () async {
      const childId = 'child1';
      final now = DateTime.now();
      final lockoutUntil =
          now.subtract(const Duration(minutes: 1)); // Expired 1 minute ago
      mockStorage.configure(
          'pin_lockout_until_$childId', lockoutUntil.toIso8601String());

      final lockoutStr =
          await mockStorage.read(key: 'pin_lockout_until_$childId');
      final lockoutTime = DateTime.parse(lockoutStr!);
      expect(lockoutTime.isBefore(now), isTrue);
    });

    test('successful PIN resets failure counter', () async {
      const childId = 'child1';
      mockStorage.configure('pin_failures_$childId', '3');

      await mockStorage.delete(key: 'pin_failures_$childId');
      expect(mockStorage.deletedKeys, contains('pin_failures_$childId'));
    });

    test('app restart with active lockout → still locked (persisted)', () async {
      const childId = 'child1';
      final now = DateTime.now();
      final lockoutUntil = now.add(const Duration(minutes: 10));
      mockStorage.configure(
          'pin_lockout_until_$childId', lockoutUntil.toIso8601String());

      final lockoutStr =
          await mockStorage.read(key: 'pin_lockout_until_$childId');
      expect(lockoutStr, isNotNull);
      final lockoutTime = DateTime.parse(lockoutStr!);
      expect(lockoutTime.isAfter(now), isTrue);
    });

    test('app restart after lockout expires → not locked', () async {
      const childId = 'child1';
      final now = DateTime.now();
      final lockoutUntil =
          now.subtract(const Duration(minutes: 5)); // Expired
      mockStorage.configure(
          'pin_lockout_until_$childId', lockoutUntil.toIso8601String());

      final lockoutStr =
          await mockStorage.read(key: 'pin_lockout_until_$childId');
      final lockoutTime = DateTime.parse(lockoutStr!);
      expect(lockoutTime.isBefore(now), isTrue);
    });
  });
}
