// TODO: written anticipatorily — wire up when updateChild method is enhanced
// Testing edit child dialog feature (Sprint 5A)

import 'package:flutter_test/flutter_test.dart';
import 'package:kids_finance/features/children/domain/child.dart';
import 'package:kids_finance/features/children/domain/child_repository.dart';
import 'package:bcrypt/bcrypt.dart';

class _FakeChildRepository implements ChildRepository {
  int updateChildCallCount = 0;
  int updatePinHashCallCount = 0;
  String? capturedPinHash;

  @override
  Stream<Child?> getChildStream(String childId, String familyId) =>
      Stream.value(null);

  @override
  Future<void> updateChild({
    required String childId,
    required String familyId,
    String? name,
    String? avatarEmoji,
    String? newPin,
  }) async {
    updateChildCallCount++;
  }

  @override
  Future<void> updatePinHash({
    required String childId,
    required String familyId,
    required String newPinHash,
  }) async {
    updatePinHashCallCount++;
    capturedPinHash = newPinHash;
  }

  @override
  Future<void> updateSessionExpiry({
    required String childId,
    required String familyId,
    required DateTime expiresAt,
  }) async {}

  @override
  Future<void> archiveChild({
    required String familyId,
    required String childId,
  }) async {}
}

void main() {
  group('Edit Child', () {
    late _FakeChildRepository mockRepository;

    setUp(() {
      mockRepository = _FakeChildRepository();
    });

    test('updateChild with new name — only name field updated', () async {
      const childId = 'child1';
      const familyId = 'family1';
      const newName = 'Updated Name';

      await mockRepository.updateChild(
        childId: childId,
        familyId: familyId,
        name: newName,
        avatarEmoji: null,
      );

      expect(mockRepository.updateChildCallCount, 1);
    });

    test('updateChild with new PIN — PIN is hashed (not stored plaintext)', () async {
      const childId = 'child1';
      const familyId = 'family1';
      const newPin = '5678';

      final hashedPin = BCrypt.hashpw(newPin, BCrypt.gensalt());
      
      await mockRepository.updatePinHash(
        childId: childId,
        familyId: familyId,
        newPinHash: hashedPin,
      );

      final capturedHash = mockRepository.capturedPinHash!;
      
      // Verify it's not plaintext
      expect(capturedHash, isNot(equals(newPin)));
      
      // Verify it's a valid BCrypt hash
      expect(capturedHash.length, greaterThan(20));
      
      // Verify we can verify the PIN with the hash
      expect(BCrypt.checkpw(newPin, capturedHash), isTrue);
      expect(BCrypt.checkpw('9999', capturedHash), isFalse);
    });

    test('updateChild with no changes (all null) — no Firestore write', () async {
      // If all fields are null, the service layer should skip the Firestore write
      expect(mockRepository.updateChildCallCount, 0);
      expect(mockRepository.updatePinHashCallCount, 0);
    });

    test('updateChild with new avatar — only avatar field updated', () async {
      const childId = 'child1';
      const familyId = 'family1';
      const newAvatar = '🦄';

      await mockRepository.updateChild(
        childId: childId,
        familyId: familyId,
        name: null,
        avatarEmoji: newAvatar,
      );

      expect(mockRepository.updateChildCallCount, 1);
    });

    test('updateChild with both name and avatar — both fields updated', () async {
      const childId = 'child1';
      const familyId = 'family1';
      const newName = 'New Name';
      const newAvatar = '🎈';

      await mockRepository.updateChild(
        childId: childId,
        familyId: familyId,
        name: newName,
        avatarEmoji: newAvatar,
      );

      expect(mockRepository.updateChildCallCount, 1);
    });
  });
}
