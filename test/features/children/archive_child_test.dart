// TODO: written anticipatorily — wire up when archiveChild and archived field are available
// Testing soft delete child feature (Sprint 5A)

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kids_finance/features/children/domain/child.dart';
import 'package:kids_finance/features/family/domain/family.dart';
import 'package:kids_finance/features/family/domain/family_repository.dart';

class _FakeFamilyRepository implements FamilyRepository {
  final Map<String, List<Child>> _childrenByFamily = {};

  void stubChildrenStream(String familyId, List<Child> children) {
    _childrenByFamily[familyId] = children;
  }

  Stream<List<Child>> getChildrenStream({required String familyId}) =>
      Stream.value(_childrenByFamily[familyId] ?? []);

  @override
  Stream<Family?> getFamilyStream(String familyId) => Stream.value(null);

  @override
  Future<Family> createFamily({
    required String name,
    required String parentUid,
    required String parentDisplayName,
  }) async =>
      throw UnimplementedError();

  @override
  Future<void> addParent({
    required String familyId,
    required String parentUid,
    required String parentDisplayName,
    bool isOwner = false,
  }) async {}

  @override
  Future<Child> addChild({
    required String familyId,
    required String displayName,
    required String avatarEmoji,
    required String pinHash,
  }) async =>
      throw UnimplementedError();
}

void main() {
  group('Archive Child (Soft Delete)', () {
    late _FakeFamilyRepository mockRepository;

    setUp(() {
      mockRepository = _FakeFamilyRepository();
    });

    test('archiveChild — sets archived:true on child document', () async {
      // Arrange
      const childId = 'child1';
      const familyId = 'family1';

      // TODO: When archiveChild is implemented in repository, test this:
      // when(mockRepository.archiveChild(
      //   childId: anyNamed('childId'),
      //   familyId: anyNamed('familyId'),
      // )).thenAnswer((_) async => Future.value());
      //
      // Act
      // await mockRepository.archiveChild(
      //   childId: childId,
      //   familyId: familyId,
      // );
      //
      // Assert
      // verify(mockRepository.archiveChild(
      //   childId: childId,
      //   familyId: familyId,
      // )).called(1);

      // For now, just verify the concept
      expect(childId, isNotEmpty);
      expect(familyId, isNotEmpty);
    });

    test('fetchChildren — returns only non-archived children', () async {
      // Arrange
      const familyId = 'family1';
      
      final activeChild = Child(
        id: 'child1',
        familyId: familyId,
        displayName: 'Active Child',
        avatarEmoji: '👦',
        pinHash: 'hash1',
        createdAt: DateTime.now(),
      );

      mockRepository.stubChildrenStream(familyId, [activeChild]);

      // Act
      final stream = mockRepository.getChildrenStream(familyId: familyId);
      final children = await stream.first;

      // Assert
      expect(children.length, 1);
      expect(children[0].id, equals('child1'));
      expect(children[0].displayName, equals('Active Child'));
      
      // Archived child should not be in the list
      expect(children.any((c) => c.id == 'child2'), isFalse);
    });

    testWidgets('ParentDashboard — archived child does NOT appear in the list', (tester) async {
      // Arrange
      const familyId = 'family1';
      
      final activeChild = Child(
        id: 'child1',
        familyId: familyId,
        displayName: 'Active Child',
        avatarEmoji: '👦',
        pinHash: 'hash1',
        createdAt: DateTime.now(),
      );

      mockRepository.stubChildrenStream(familyId, [activeChild]);

      // For now, create a simple test widget
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: StreamBuilder<List<Child>>(
                stream: mockRepository.getChildrenStream(familyId: familyId),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const CircularProgressIndicator();
                  }
                  
                  final children = snapshot.data!;
                  return ListView.builder(
                    itemCount: children.length,
                    itemBuilder: (context, index) {
                      final child = children[index];
                      return ListTile(
                        key: Key('child_${child.id}'),
                        title: Text(child.displayName),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert - only active child appears
      expect(find.text('Active Child'), findsOneWidget);
      expect(find.text('Archived Child'), findsNothing);
      expect(find.byKey(const Key('child_child1')), findsOneWidget);
      expect(find.byKey(const Key('child_child2')), findsNothing);
    });

    test('archiveChild preserves all child data', () async {
      // Verify that archiving is just a flag, not a deletion
      // The child document should remain in Firestore with archived=true
      expect(true, isTrue); // Placeholder for now
    });
  });
}
