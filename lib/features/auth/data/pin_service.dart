import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:bcrypt/bcrypt.dart';

sealed class PinResult {
  const PinResult();
}

class PinSuccess extends PinResult {
  final String childId;
  const PinSuccess(this.childId);
}

class PinWrongPin extends PinResult {
  final int attemptsRemaining;
  const PinWrongPin(this.attemptsRemaining);
}

class PinLocked extends PinResult {
  final DateTime unlocksAt;
  const PinLocked(this.unlocksAt);
}

class PinService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  static const int maxAttempts = 5;
  static const Duration lockoutDuration = Duration(minutes: 15);
  static const Duration sessionDuration = Duration(days: 30);

  String hashPin(String pin) {
    return BCrypt.hashpw(pin, BCrypt.gensalt());
  }

  bool verifyPin(String pin, String hash) {
    try {
      return BCrypt.checkpw(pin, hash);
    } catch (e) {
      return false;
    }
  }

  Future<void> setPinForChild(
    String childId,
    String familyId,
    String pin,
  ) async {
    if (pin.length < 4 || pin.length > 6) {
      throw Exception('PIN must be 4-6 digits');
    }

    if (!RegExp(r'^\d+$').hasMatch(pin)) {
      throw Exception('PIN must contain only digits');
    }

    final hash = hashPin(pin);

    await _firestore
        .collection('families')
        .doc(familyId)
        .collection('children')
        .doc(childId)
        .update({
      'pinHash': hash,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await _resetAttempts(childId);
  }

  Future<PinResult> verifyChildPin(
    String childId,
    String familyId,
    String enteredPin,
  ) async {
    final lockStatus = await _checkLockout(childId);
    if (lockStatus != null) {
      return lockStatus;
    }

    final childDoc = await _firestore
        .collection('families')
        .doc(familyId)
        .collection('children')
        .doc(childId)
        .get();

    if (!childDoc.exists) {
      throw Exception('Child not found');
    }

    final storedHash = childDoc.data()?['pinHash'] as String?;
    if (storedHash == null) {
      throw Exception('PIN not set for this child');
    }

    if (verifyPin(enteredPin, storedHash)) {
      await _resetAttempts(childId);
      await _createSession(childId);
      return PinSuccess(childId);
    } else {
      return await _incrementAttempts(childId);
    }
  }

  Future<bool> isChildSessionValid(String childId) async {
    final expiryStr = await _storage.read(key: 'child_session_$childId');
    if (expiryStr == null) return false;

    try {
      final expiry = DateTime.parse(expiryStr);
      return DateTime.now().isBefore(expiry);
    } catch (e) {
      return false;
    }
  }

  Future<void> clearChildSession(String childId) async {
    await _storage.delete(key: 'child_session_$childId');
    await _resetAttempts(childId);
  }

  Future<void> _createSession(String childId) async {
    final expiry = DateTime.now().add(sessionDuration);
    await _storage.write(
      key: 'child_session_$childId',
      value: expiry.toIso8601String(),
    );
  }

  Future<PinLocked?> _checkLockout(String childId) async {
    final lockoutStr = await _storage.read(key: 'lockout_until_$childId');
    if (lockoutStr == null) return null;

    try {
      final lockoutUntil = DateTime.parse(lockoutStr);
      if (DateTime.now().isBefore(lockoutUntil)) {
        return PinLocked(lockoutUntil);
      } else {
        await _storage.delete(key: 'lockout_until_$childId');
        await _resetAttempts(childId);
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  Future<PinResult> _incrementAttempts(String childId) async {
    final attemptsStr = await _storage.read(key: 'pin_attempts_$childId');
    final attempts = int.tryParse(attemptsStr ?? '0') ?? 0;
    final newAttempts = attempts + 1;

    if (newAttempts >= maxAttempts) {
      final lockoutUntil = DateTime.now().add(lockoutDuration);
      await _storage.write(
        key: 'lockout_until_$childId',
        value: lockoutUntil.toIso8601String(),
      );
      await _storage.delete(key: 'pin_attempts_$childId');
      return PinLocked(lockoutUntil);
    } else {
      await _storage.write(
        key: 'pin_attempts_$childId',
        value: newAttempts.toString(),
      );
      return PinWrongPin(maxAttempts - newAttempts);
    }
  }

  Future<void> _resetAttempts(String childId) async {
    await _storage.delete(key: 'pin_attempts_$childId');
    await _storage.delete(key: 'lockout_until_$childId');
  }
}
