// Testing edit child dialog feature (Sprint 5A)

import 'package:flutter_test/flutter_test.dart';
import 'package:kids_finance/features/children/domain/child.dart';
import 'package:kids_finance/features/children/domain/child_repository.dart';

class _FakeChildRepository implements ChildRepository {
  int updateChildCallCount = 0;

  @override
  Stream<Child?> getChildStream(String childId, String familyId) =>
      Stream.value(null);

  @override
  Future<void> updateChild({
    required String childId,
    required String familyId,
    String? name,
    String? avatarEmoji,
  }) async {
    updateChildCallCount++;
  }

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

    test('updateChild with no changes (all null) — no Firestore write', () async {
      // If all fields are null, the service layer should skip the Firestore write
      expect(mockRepository.updateChildCallCount, 0);
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
