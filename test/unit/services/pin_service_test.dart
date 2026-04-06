import 'package:flutter_test/flutter_test.dart';
import 'package:bcrypt/bcrypt.dart';

void main() {
  group('PIN hash/verify (BCrypt)', () {
    // Test BCrypt directly to avoid Firebase dependencies
    // This tests the same logic that PinService uses
    
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
    
    test('hashPin returns non-empty string', () {
      final hash = hashPin('1234');
      expect(hash, isNotEmpty);
      expect(hash, isNot(equals('1234'))); // must be hashed
    });
    
    test('verifyPin returns true for correct PIN', () {
      final hash = hashPin('1234');
      expect(verifyPin('1234', hash), isTrue);
    });
    
    test('verifyPin returns false for wrong PIN', () {
      final hash = hashPin('1234');
      expect(verifyPin('9999', hash), isFalse);
    });
    
    test('different PINs produce different hashes', () {
      final hash1 = hashPin('1234');
      final hash2 = hashPin('5678');
      expect(hash1, isNot(equals(hash2)));
    });
    
    test('same PIN produces different hashes (salt)', () {
      final hash1 = hashPin('1234');
      final hash2 = hashPin('1234');
      // BCrypt uses salt, so same PIN produces different hashes
      expect(hash1, isNot(equals(hash2)));
      // But both should verify correctly
      expect(verifyPin('1234', hash1), isTrue);
      expect(verifyPin('1234', hash2), isTrue);
    });
    
    test('hash is bcrypt format', () {
      final hash = hashPin('1234');
      // BCrypt hashes start with $2 (e.g., $2a$, $2b$, $2y$)
      expect(hash.startsWith(r'$2'), isTrue);
    });
    
    test('verifyPin handles invalid hash gracefully', () {
      expect(verifyPin('1234', 'invalid_hash'), isFalse);
    });
    
    test('empty PIN can be hashed and verified', () {
      // Note: PinService may validate PIN length in setPinForChild,
      // but hashPin/verifyPin are pure crypto functions
      final hash = hashPin('');
      expect(verifyPin('', hash), isTrue);
      expect(verifyPin('1234', hash), isFalse);
    });
  });
}
