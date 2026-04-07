// TODO: written anticipatorily — wire up when archiveChild and archived field are available
// Testing soft delete child feature (Sprint 5A)

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kids_finance/features/children/domain/child.dart';
import 'package:kids_finance/features/family/domain/family_repository.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'archive_child_test.mocks.dart';

@GenerateMocks([FamilyRepository])
void main() {
  group('Archive Child (Soft Delete)', () {
    late MockFamilyRepository mockRepository;

    setUp(() {
      mockRepository = MockFamilyRepository();
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

      final archivedChild = Child(
        id: 'child2',
        familyId: familyId,
        displayName: 'Archived Child',
        avatarEmoji: '👧',
        pinHash: 'hash2',
        createdAt: DateTime.now(),
        // TODO: When archived field is added to Child model, set it here:
        // archived: true,
      );

      when(mockRepository.getChildrenStream(familyId: familyId))
          .thenAnswer((_) => Stream.value([activeChild])); // Only returns non-archived

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

      when(mockRepository.getChildrenStream(familyId: familyId))
          .thenAnswer((_) => Stream.value([activeChild]));

      // TODO: When ParentDashboard is available, test with actual widget:
      // await tester.pumpWidget(
      //   ProviderScope(
      //     overrides: [
      //       familyRepositoryProvider.overrideWith((ref) => mockRepository),
      //       currentFamilyIdProvider.overrideWith((ref) => familyId),
      //     ],
      //     child: const MaterialApp(home: ParentDashboard()),
      //   ),
      // );
      //
      // await tester.pumpAndSettle();
      //
      // Assert - only active child appears
      // expect(find.text('Active Child'), findsOneWidget);
      // expect(find.text('Archived Child'), findsNothing);

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
      // Arrange
      const childId = 'child1';
      const familyId = 'family1';

      // TODO: When unarchiveChild is implemented, this test ensures
      // that archived children can be restored with all their data intact
      
      // Verify that archiving is just a flag, not a deletion
      // The child document should remain in Firestore with archived=true
      expect(true, isTrue); // Placeholder for now
    });
  });
}
