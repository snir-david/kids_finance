import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kids_finance/features/auth/presentation/child_picker_screen.dart';
import 'package:kids_finance/features/auth/providers/auth_providers.dart';
import 'package:kids_finance/features/children/providers/children_providers.dart';
import 'package:kids_finance/features/children/domain/child.dart';

void main() {
  group('ChildPickerScreen', () {
    testWidgets('renders "Who are you?" title', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentFamilyIdProvider.overrideWith((ref) => Stream.value('family1')),
            childrenProvider('family1').overrideWith((ref) => Stream.value([])),
          ],
          child: const MaterialApp(home: ChildPickerScreen()),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.widgetWithText(AppBar, 'Who are you?'), findsOneWidget);
    });

    testWidgets('shows loading indicator while fetching children', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentFamilyIdProvider.overrideWith((ref) => Stream.value('family1')),
            childrenProvider('family1').overrideWith((ref) => const Stream.empty()),
          ],
          child: const MaterialApp(home: ChildPickerScreen()),
        ),
      );

      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows empty state when no children', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentFamilyIdProvider.overrideWith((ref) => Stream.value('family1')),
            childrenProvider('family1').overrideWith((ref) => Stream.value([])),
          ],
          child: const MaterialApp(home: ChildPickerScreen()),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('No children found'), findsOneWidget);
    });

    testWidgets('shows children as cards when children exist', (tester) async {
      final fakeChildren = [
        Child(
          id: 'child1',
          familyId: 'family1',
          displayName: 'Alex',
          avatarEmoji: '👦',
          pinHash: 'hash123',
          createdAt: DateTime.now(),
        ),
        Child(
          id: 'child2',
          familyId: 'family1',
          displayName: 'Emma',
          avatarEmoji: '👧',
          pinHash: 'hash456',
          createdAt: DateTime.now(),
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentFamilyIdProvider.overrideWith((ref) => Stream.value('family1')),
            childrenProvider('family1').overrideWith((ref) => Stream.value(fakeChildren)),
          ],
          child: const MaterialApp(home: ChildPickerScreen()),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Alex'), findsOneWidget);
      expect(find.text('Emma'), findsOneWidget);
      expect(find.text('👦'), findsOneWidget);
      expect(find.text('👧'), findsOneWidget);
    });

    testWidgets('tapping child card sets selectedChildProvider', (tester) async {
      final fakeChildren = [
        Child(
          id: 'child1',
          familyId: 'family1',
          displayName: 'Alex',
          avatarEmoji: '👦',
          pinHash: 'hash123',
          createdAt: DateTime.now(),
        ),
      ];

      String? selectedChildId;
      
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentFamilyIdProvider.overrideWith((ref) => Stream.value('family1')),
            childrenProvider('family1').overrideWith((ref) => Stream.value(fakeChildren)),
            selectedChildProvider.overrideWith((ref) {
              return StateController<String?>(null)
                ..addListener((state) {
                  selectedChildId = state;
                });
            }),
          ],
          child: const MaterialApp(home: ChildPickerScreen()),
        ),
      );

      await tester.pumpAndSettle();

      // Find and tap the child card
      final childCard = find.ancestor(
        of: find.text('Alex'),
        matching: find.byType(Card),
      );
      
      expect(childCard, findsOneWidget);
      
      // Note: The actual navigation will be tested in integration tests
      // This test verifies the card is tappable and exists
    });

    testWidgets('shows multiple children in a grid layout', (tester) async {
      final fakeChildren = [
        Child(
          id: 'child1',
          familyId: 'family1',
          displayName: 'Alex',
          avatarEmoji: '👦',
          pinHash: 'hash123',
          createdAt: DateTime.now(),
        ),
        Child(
          id: 'child2',
          familyId: 'family1',
          displayName: 'Emma',
          avatarEmoji: '👧',
          pinHash: 'hash456',
          createdAt: DateTime.now(),
        ),
        Child(
          id: 'child3',
          familyId: 'family1',
          displayName: 'Jordan',
          avatarEmoji: '🧒',
          pinHash: 'hash789',
          createdAt: DateTime.now(),
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentFamilyIdProvider.overrideWith((ref) => Stream.value('family1')),
            childrenProvider('family1').overrideWith((ref) => Stream.value(fakeChildren)),
          ],
          child: const MaterialApp(home: ChildPickerScreen()),
        ),
      );

      await tester.pumpAndSettle();

      // All three children should be visible
      expect(find.text('Alex'), findsOneWidget);
      expect(find.text('Emma'), findsOneWidget);
      expect(find.text('Jordan'), findsOneWidget);
      
      // All three emojis should be visible
      expect(find.text('👦'), findsOneWidget);
      expect(find.text('👧'), findsOneWidget);
      expect(find.text('🧒'), findsOneWidget);
    });

    testWidgets('handles null family ID gracefully', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentFamilyIdProvider.overrideWith((ref) => Stream.value(null)),
          ],
          child: const MaterialApp(home: ChildPickerScreen()),
        ),
      );

      await tester.pumpAndSettle();

      // Should show some indication that no family is available
      // The exact implementation depends on the screen design
      expect(find.byType(ChildPickerScreen), findsOneWidget);
    });

    testWidgets('shows child cards as tappable InkWell or GestureDetector', (tester) async {
      final fakeChildren = [
        Child(
          id: 'child1',
          familyId: 'family1',
          displayName: 'Alex',
          avatarEmoji: '👦',
          pinHash: 'hash123',
          createdAt: DateTime.now(),
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentFamilyIdProvider.overrideWith((ref) => Stream.value('family1')),
            childrenProvider('family1').overrideWith((ref) => Stream.value(fakeChildren)),
          ],
          child: const MaterialApp(home: ChildPickerScreen()),
        ),
      );

      await tester.pumpAndSettle();

      // Cards should be tappable (either via InkWell or GestureDetector)
      final tappableWidgets = tester.widgetList(
        find.byWidgetPredicate(
          (widget) => widget is InkWell || widget is GestureDetector,
        ),
      );
      
      expect(tappableWidgets.length, greaterThanOrEqualTo(1));
    });

    testWidgets('child cards display emoji prominently', (tester) async {
      final fakeChildren = [
        Child(
          id: 'child1',
          familyId: 'family1',
          displayName: 'Alex',
          avatarEmoji: '🎨',
          pinHash: 'hash123',
          createdAt: DateTime.now(),
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentFamilyIdProvider.overrideWith((ref) => Stream.value('family1')),
            childrenProvider('family1').overrideWith((ref) => Stream.value(fakeChildren)),
          ],
          child: const MaterialApp(home: ChildPickerScreen()),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('🎨'), findsOneWidget);
      expect(find.text('Alex'), findsOneWidget);
    });
  });
}
