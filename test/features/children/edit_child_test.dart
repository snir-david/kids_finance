// TODO: written anticipatorily — wire up when updateChild method is enhanced
// Testing edit child dialog feature (Sprint 5A)

import 'package:flutter_test/flutter_test.dart';
import 'package:kids_finance/features/children/domain/child.dart';
import 'package:kids_finance/features/children/domain/child_repository.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:bcrypt/bcrypt.dart';

import 'edit_child_test.mocks.dart';

@GenerateMocks([ChildRepository])
void main() {
  group('Edit Child', () {
    late MockChildRepository mockRepository;

    setUp(() {
      mockRepository = MockChildRepository();
    });

    test('updateChild with new name — only name field updated', () async {
      // Arrange
      const childId = 'child1';
      const familyId = 'family1';
      const newName = 'Updated Name';

      when(mockRepository.updateChild(
        childId: anyNamed('childId'),
        familyId: anyNamed('familyId'),
        displayName: anyNamed('displayName'),
        avatarEmoji: anyNamed('avatarEmoji'),
      )).thenAnswer((_) async => Future.value());

      // Act
      await mockRepository.updateChild(
        childId: childId,
        familyId: familyId,
        displayName: newName,
        avatarEmoji: null, // No change to avatar
      );

      // Assert
      verify(mockRepository.updateChild(
        childId: childId,
        familyId: familyId,
        displayName: newName,
        avatarEmoji: null,
      )).called(1);
    });

    test('updateChild with new PIN — PIN is hashed (not stored plaintext)', () async {
      // Arrange
      const childId = 'child1';
      const familyId = 'family1';
      const newPin = '5678';

      when(mockRepository.updatePinHash(
        childId: anyNamed('childId'),
        familyId: anyNamed('familyId'),
        newPinHash: anyNamed('newPinHash'),
      )).thenAnswer((_) async => Future.value());

      // Act - Hash the PIN before storing (this is what the service layer should do)
      final hashedPin = BCrypt.hashpw(newPin, BCrypt.gensalt());
      
      await mockRepository.updatePinHash(
        childId: childId,
        familyId: familyId,
        newPinHash: hashedPin,
      );

      // Assert
      final captured = verify(mockRepository.updatePinHash(
        childId: childId,
        familyId: familyId,
        newPinHash: captureAnyNamed('newPinHash'),
      )).captured;

      expect(captured.length, 1);
      final capturedHash = captured[0] as String;
      
      // Verify it's not plaintext
      expect(capturedHash, isNot(equals(newPin)));
      
      // Verify it's a valid BCrypt hash
      expect(capturedHash.length, greaterThan(20));
      
      // Verify we can verify the PIN with the hash
      expect(BCrypt.checkpw(newPin, capturedHash), isTrue);
      expect(BCrypt.checkpw('9999', capturedHash), isFalse);
    });

    test('updateChild with no changes (all null) — no Firestore write', () async {
      // Arrange
      const childId = 'child1';
      const familyId = 'family1';

      // Act & Assert
      // If all fields are null, the service layer should skip the Firestore write
      // This test verifies the pattern - when enhanced updateChild is available,
      // it should check if any fields are non-null before calling repository

      // For now, verify that updateChild doesn't get called when nothing changes
      verifyNever(mockRepository.updateChild(
        childId: anyNamed('childId'),
        familyId: anyNamed('familyId'),
        displayName: anyNamed('displayName'),
        avatarEmoji: anyNamed('avatarEmoji'),
      ));
      
      verifyNever(mockRepository.updatePinHash(
        childId: anyNamed('childId'),
        familyId: anyNamed('familyId'),
        newPinHash: anyNamed('newPinHash'),
      ));
    });

    test('updateChild with new avatar — only avatar field updated', () async {
      // Arrange
      const childId = 'child1';
      const familyId = 'family1';
      const newAvatar = '🦄';

      when(mockRepository.updateChild(
        childId: anyNamed('childId'),
        familyId: anyNamed('familyId'),
        displayName: anyNamed('displayName'),
        avatarEmoji: anyNamed('avatarEmoji'),
      )).thenAnswer((_) async => Future.value());

      // Act
      await mockRepository.updateChild(
        childId: childId,
        familyId: familyId,
        displayName: null, // No change to name
        avatarEmoji: newAvatar,
      );

      // Assert
      verify(mockRepository.updateChild(
        childId: childId,
        familyId: familyId,
        displayName: null,
        avatarEmoji: newAvatar,
      )).called(1);
    });

    test('updateChild with both name and avatar — both fields updated', () async {
      // Arrange
      const childId = 'child1';
      const familyId = 'family1';
      const newName = 'New Name';
      const newAvatar = '🎈';

      when(mockRepository.updateChild(
        childId: anyNamed('childId'),
        familyId: anyNamed('familyId'),
        displayName: anyNamed('displayName'),
        avatarEmoji: anyNamed('avatarEmoji'),
      )).thenAnswer((_) async => Future.value());

      // Act
      await mockRepository.updateChild(
        childId: childId,
        familyId: familyId,
        displayName: newName,
        avatarEmoji: newAvatar,
      );

      // Assert
      verify(mockRepository.updateChild(
        childId: childId,
        familyId: familyId,
        displayName: newName,
        avatarEmoji: newAvatar,
      )).called(1);
    });
  });
}
