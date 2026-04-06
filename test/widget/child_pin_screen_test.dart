import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kids_finance/features/auth/presentation/child_pin_screen.dart';
import 'package:kids_finance/features/auth/providers/auth_providers.dart';
import 'package:kids_finance/features/children/providers/children_providers.dart';
import 'package:kids_finance/features/children/domain/child.dart';

void main() {
  group('ChildPinScreen', () {
    setUp(() async {});

    testWidgets('renders PIN dots', (tester) async {
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      final fakeChild = Child(
        id: 'child1',
        familyId: 'family1',
        displayName: 'Alex',
        avatarEmoji: '👦',
        pinHash: 'hash123',
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            selectedChildProvider.overrideWith((ref) => 'child1'),
            currentFamilyIdProvider.overrideWith((ref) => Stream.value('family1')),
            childProvider(
              (childId: 'child1', familyId: 'family1'),
            ).overrideWith((ref) => Stream.value(fakeChild)),
          ],
          child: const MaterialApp(home: ChildPinScreen()),
        ),
      );

      await tester.pumpAndSettle();

      // Should show 4 PIN dots
      final containers = tester.widgetList<Container>(
        find.descendant(
          of: find.byType(ChildPinScreen),
          matching: find.byType(Container),
        ),
      );

      // At least 4 containers for the dots
      expect(containers.length, greaterThanOrEqualTo(4));
    });

    testWidgets('renders numpad', (tester) async {
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      final fakeChild = Child(
        id: 'child1',
        familyId: 'family1',
        displayName: 'Alex',
        avatarEmoji: '👦',
        pinHash: 'hash123',
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            selectedChildProvider.overrideWith((ref) => 'child1'),
            currentFamilyIdProvider.overrideWith((ref) => Stream.value('family1')),
            childProvider(
              (childId: 'child1', familyId: 'family1'),
            ).overrideWith((ref) => Stream.value(fakeChild)),
          ],
          child: const MaterialApp(home: ChildPinScreen()),
        ),
      );

      await tester.pumpAndSettle();

      // Should show all digits 0-9
      for (int i = 0; i <= 9; i++) {
        expect(find.text(i.toString()), findsOneWidget);
      }

      // Should show backspace
      expect(find.byIcon(Icons.backspace_outlined), findsOneWidget);
    });

    testWidgets('shows child name and emoji', (tester) async {
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      final fakeChild = Child(
        id: 'child1',
        familyId: 'family1',
        displayName: 'Emma',
        avatarEmoji: '👧',
        pinHash: 'hash123',
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            selectedChildProvider.overrideWith((ref) => 'child1'),
            currentFamilyIdProvider.overrideWith((ref) => Stream.value('family1')),
            childProvider(
              (childId: 'child1', familyId: 'family1'),
            ).overrideWith((ref) => Stream.value(fakeChild)),
          ],
          child: const MaterialApp(home: ChildPinScreen()),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('👧 Emma'), findsOneWidget);
    });

    testWidgets('shows Enter PIN title', (tester) async {
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      final fakeChild = Child(
        id: 'child1',
        familyId: 'family1',
        displayName: 'Alex',
        avatarEmoji: '👦',
        pinHash: 'hash123',
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            selectedChildProvider.overrideWith((ref) => 'child1'),
            currentFamilyIdProvider.overrideWith((ref) => Stream.value('family1')),
            childProvider(
              (childId: 'child1', familyId: 'family1'),
            ).overrideWith((ref) => Stream.value(fakeChild)),
          ],
          child: const MaterialApp(home: ChildPinScreen()),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.widgetWithText(AppBar, 'Enter PIN'), findsOneWidget);
    });

    testWidgets('shows loading when child data is loading', (tester) async {
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            selectedChildProvider.overrideWith((ref) => 'child1'),
            currentFamilyIdProvider.overrideWith((ref) => Stream.value('family1')),
            childProvider(
              (childId: 'child1', familyId: 'family1'),
            ).overrideWith((ref) => const Stream.empty()),
          ],
          child: const MaterialApp(home: ChildPinScreen()),
        ),
      );

      await tester.pump();

      expect(find.text('Loading...'), findsOneWidget);
    });

    testWidgets('renders without crashing when no child selected', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            selectedChildProvider.overrideWith((ref) => null),
            currentFamilyIdProvider.overrideWith((ref) => Stream.value('family1')),
          ],
          child: MaterialApp.router(
            routerConfig: GoRouter(
              initialLocation: '/child-pin',
              routes: [
                GoRoute(
                  path: '/child-pin',
                  builder: (context, state) => const ChildPinScreen(),
                ),
                GoRoute(
                  path: '/child-picker',
                  builder: (context, state) => const Scaffold(
                    body: Text('Child Picker'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should redirect to child picker - verify we see the picker screen
      expect(find.text('Child Picker'), findsOneWidget);
    });
  });
}
