import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Thrown when a child is locked out due to too many failed PIN attempts.
class PinLockoutException implements Exception {
  const PinLockoutException(this.lockedUntil);

  final DateTime lockedUntil;

  @override
  String toString() =>
      'PinLockoutException: locked until ${lockedUntil.toIso8601String()}';
}

/// Tracks per-child PIN failure counts and enforces lockout policy.
///
/// After [maxAttempts] consecutive failures the child is locked out for
/// [lockoutDuration]. State is persisted via [FlutterSecureStorage] so
/// lockouts survive app restarts.
class PinAttemptTracker {
  PinAttemptTracker({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static const int maxAttempts = 5;
  static const Duration lockoutDuration = Duration(minutes: 15);

  String _attemptsKey(String childId) => 'pin_attempts_$childId';
  String _lockoutKey(String childId) => 'pin_lockout_until_$childId';

  /// Returns `true` if [childId] is currently under an active lockout.
  Future<bool> isLockedOut(String childId) async {
    return await lockoutRemaining(childId) != null;
  }

  /// Returns the remaining lockout [Duration], or `null` if not locked out.
  /// Automatically clears expired lockouts from storage.
  Future<Duration?> lockoutRemaining(String childId) async {
    final lockoutStr = await _storage.read(key: _lockoutKey(childId));
    if (lockoutStr == null) return null;

    try {
      final lockedUntil = DateTime.parse(lockoutStr);
      final remaining = lockedUntil.difference(DateTime.now());
      if (remaining.isNegative) {
        await _storage.delete(key: _lockoutKey(childId));
        await _storage.delete(key: _attemptsKey(childId));
        return null;
      }
      return remaining;
    } catch (_) {
      return null;
    }
  }

  /// Records one failed PIN attempt for [childId].
  ///
  /// Returns the number of attempts remaining before lockout.
  /// Throws [PinLockoutException] if this failure triggers a lockout.
  Future<int> recordFailure(String childId) async {
    final attemptsStr = await _storage.read(key: _attemptsKey(childId));
    final attempts = int.tryParse(attemptsStr ?? '0') ?? 0;
    final newAttempts = attempts + 1;

    if (newAttempts >= maxAttempts) {
      final lockedUntil = DateTime.now().add(lockoutDuration);
      await _storage.write(
        key: _lockoutKey(childId),
        value: lockedUntil.toIso8601String(),
      );
      await _storage.delete(key: _attemptsKey(childId));
      throw PinLockoutException(lockedUntil);
    }

    await _storage.write(
      key: _attemptsKey(childId),
      value: newAttempts.toString(),
    );
    return maxAttempts - newAttempts;
  }

  /// Resets the failure counter and clears any active lockout for [childId].
  Future<void> resetAttempts(String childId) async {
    await _storage.delete(key: _attemptsKey(childId));
    await _storage.delete(key: _lockoutKey(childId));
  }
}
