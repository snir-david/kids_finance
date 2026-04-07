import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:bcrypt/bcrypt.dart';
import 'pin_attempt_tracker.dart';

export 'pin_attempt_tracker.dart' show PinLockoutException;

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
  PinService({PinAttemptTracker? tracker})
      : _tracker = tracker ?? PinAttemptTracker();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final PinAttemptTracker _tracker;

  /// Child sessions expire after 24 hours, requiring PIN re-entry.
  static const Duration sessionDuration = Duration(hours: 24);

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

    await _tracker.resetAttempts(childId);
  }

  Future<PinResult> verifyChildPin(
    String childId,
    String familyId,
    String enteredPin,
  ) async {
    // Check lockout first — state persists across app restarts.
    final remaining = await _tracker.lockoutRemaining(childId);
    if (remaining != null) {
      return PinLocked(DateTime.now().add(remaining));
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
      await _tracker.resetAttempts(childId);
      await _createSession(childId, familyId);
      return PinSuccess(childId);
    } else {
      try {
        final attemptsRemaining = await _tracker.recordFailure(childId);
        return PinWrongPin(attemptsRemaining);
      } on PinLockoutException catch (e) {
        return PinLocked(e.lockedUntil);
      }
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
    await _tracker.resetAttempts(childId);
  }

  /// Creates a 24-hour session both locally (fast read) and in Firestore
  /// (enforced by [childSessionValidProvider] on every child-mode screen).
  Future<void> _createSession(String childId, String familyId) async {
    final expiry = DateTime.now().add(sessionDuration);

    await _storage.write(
      key: 'child_session_$childId',
      value: expiry.toIso8601String(),
    );

    await _firestore
        .collection('families')
        .doc(familyId)
        .collection('children')
        .doc(childId)
        .update({'sessionExpiresAt': Timestamp.fromDate(expiry)});
  }
}
