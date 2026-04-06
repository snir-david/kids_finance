import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' hide Family;
import 'package:kids_finance/features/auth/presentation/parent_home_screen.dart';
import 'package:kids_finance/features/auth/presentation/child_home_screen.dart';
import 'package:kids_finance/features/auth/providers/auth_providers.dart';
import 'package:kids_finance/features/children/providers/children_providers.dart';
import 'package:kids_finance/features/buckets/providers/buckets_providers.dart';
import 'package:kids_finance/features/transactions/providers/transaction_providers.dart';
import 'package:kids_finance/features/family/providers/family_providers.dart';
import 'package:kids_finance/features/children/domain/child.dart';
import 'package:kids_finance/features/buckets/domain/bucket.dart';
import 'package:kids_finance/features/family/domain/family.dart' as app_family;

void main() {
  group('ParentHomeScreen', () {
    testWidgets('shows loading when family data is loading', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentFamilyIdProvider.overrideWith((ref) => const Stream.empty()),
            firebaseAuthStateProvider.overrideWith((ref) => Stream.value(null)),
          ],
          child: const MaterialApp(home: ParentHomeScreen()),
        ),
      );

      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows "No family found" when familyId is null', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentFamilyIdProvider.overrideWith((ref) => Stream.value(null)),
            firebaseAuthStateProvider.overrideWith((ref) => Stream.value(null)),
          ],
          child: const MaterialApp(home: ParentHomeScreen()),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('No family found'), findsOneWidget);
    });

    testWidgets('shows loading when children are loading', (tester) async {
      final fakeFamily = app_family.Family(
        id: 'family1',
        name: 'Smith Family',
        parentIds: ['user1'],
        childIds: [],
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentFamilyIdProvider.overrideWith((ref) => Stream.value('family1')),
            firebaseAuthStateProvider.overrideWith((ref) => Stream.value(null)),
            familyProvider('family1').overrideWith((ref) => Stream.value(fakeFamily)),
            childrenProvider('family1').overrideWith((ref) => const Stream.empty()),
          ],
          child: const MaterialApp(home: ParentHomeScreen()),
        ),
      );

      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows empty state when no children', (tester) async {
      final fakeFamily = app_family.Family(
        id: 'family1',
        name: 'Smith Family',
        parentIds: ['user1'],
        childIds: [],
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentFamilyIdProvider.overrideWith((ref) => Stream.value('family1')),
            firebaseAuthStateProvider.overrideWith((ref) => Stream.value(null)),
            familyProvider('family1').overrideWith((ref) => Stream.value(fakeFamily)),
            childrenProvider('family1').overrideWith((ref) => Stream.value([])),
          ],
          child: const MaterialApp(home: ParentHomeScreen()),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('No children yet'), findsOneWidget);
      expect(find.text('Add your first child to get started'), findsOneWidget);
    });

    testWidgets('shows family name in app bar', (tester) async {
      final fakeFamily = app_family.Family(
        id: 'family1',
        name: 'Johnson Family',
        parentIds: ['user1'],
        childIds: [],
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentFamilyIdProvider.overrideWith((ref) => Stream.value('family1')),
            firebaseAuthStateProvider.overrideWith((ref) => Stream.value(null)),
            familyProvider('family1').overrideWith((ref) => Stream.value(fakeFamily)),
            childrenProvider('family1').overrideWith((ref) => Stream.value([])),
          ],
          child: const MaterialApp(home: ParentHomeScreen()),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Johnson Family'), findsOneWidget);
    });
  });

  group('ChildHomeScreen', () {
    testWidgets('shows "No child logged in" when activeChild is null', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            activeChildProvider.overrideWith((ref) => null),
          ],
          child: const MaterialApp(home: ChildHomeScreen()),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('No child logged in'), findsOneWidget);
    });

    testWidgets('shows loading when family data is loading', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            activeChildProvider.overrideWith((ref) => 'child1'),
            currentFamilyIdProvider.overrideWith((ref) => const Stream.empty()),
          ],
          child: const MaterialApp(home: ChildHomeScreen()),
        ),
      );

      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows greeting with child name', (tester) async {
      final fakeChild = Child(
        id: 'child1',
        familyId: 'family1',
        displayName: 'Alex',
        avatarEmoji: '👦',
        pinHash: 'hash123',
        createdAt: DateTime.now(),
      );

      final fakeBuckets = [
        Bucket(
          id: 'b1',
          childId: 'child1',
          familyId: 'family1',
          type: BucketType.money,
          balance: 10.00,
          lastUpdatedAt: DateTime.now(),
        ),
        Bucket(
          id: 'b2',
          childId: 'child1',
          familyId: 'family1',
          type: BucketType.investment,
          balance: 5.00,
          lastUpdatedAt: DateTime.now(),
        ),
        Bucket(
          id: 'b3',
          childId: 'child1',
          familyId: 'family1',
          type: BucketType.charity,
          balance: 2.50,
          lastUpdatedAt: DateTime.now(),
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            activeChildProvider.overrideWith((ref) => 'child1'),
            currentFamilyIdProvider.overrideWith((ref) => Stream.value('family1')),
            childProvider(
              (childId: 'child1', familyId: 'family1'),
            ).overrideWith((ref) => Stream.value(fakeChild)),
            childBucketsProvider(
              (childId: 'child1', familyId: 'family1'),
            ).overrideWith((ref) => Stream.value(fakeBuckets)),
            recentTransactionsProvider(
              (childId: 'child1', familyId: 'family1'),
            ).overrideWith((ref) => Stream.value([])),
          ],
          child: const MaterialApp(home: ChildHomeScreen()),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Hi Alex! 👋'), findsOneWidget);
    });

    testWidgets('shows total money card', (tester) async {
      final fakeChild = Child(
        id: 'child1',
        familyId: 'family1',
        displayName: 'Emma',
        avatarEmoji: '👧',
        pinHash: 'hash123',
        createdAt: DateTime.now(),
      );

      final fakeBuckets = [
        Bucket(
          id: 'b1',
          childId: 'child1',
          familyId: 'family1',
          type: BucketType.money,
          balance: 25.50,
          lastUpdatedAt: DateTime.now(),
        ),
        Bucket(
          id: 'b2',
          childId: 'child1',
          familyId: 'family1',
          type: BucketType.investment,
          balance: 10.00,
          lastUpdatedAt: DateTime.now(),
        ),
        Bucket(
          id: 'b3',
          childId: 'child1',
          familyId: 'family1',
          type: BucketType.charity,
          balance: 5.00,
          lastUpdatedAt: DateTime.now(),
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            activeChildProvider.overrideWith((ref) => 'child1'),
            currentFamilyIdProvider.overrideWith((ref) => Stream.value('family1')),
            childProvider(
              (childId: 'child1', familyId: 'family1'),
            ).overrideWith((ref) => Stream.value(fakeChild)),
            childBucketsProvider(
              (childId: 'child1', familyId: 'family1'),
            ).overrideWith((ref) => Stream.value(fakeBuckets)),
            recentTransactionsProvider(
              (childId: 'child1', familyId: 'family1'),
            ).overrideWith((ref) => Stream.value([])),
          ],
          child: const MaterialApp(home: ChildHomeScreen()),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Total Money'), findsOneWidget);
      expect(find.text('\$40.50'), findsOneWidget);
    });

    testWidgets('shows three bucket cards with correct balances', (tester) async {
      final fakeChild = Child(
        id: 'child1',
        familyId: 'family1',
        displayName: 'Jordan',
        avatarEmoji: '🧒',
        pinHash: 'hash123',
        createdAt: DateTime.now(),
      );

      final fakeBuckets = [
        Bucket(
          id: 'b1',
          childId: 'child1',
          familyId: 'family1',
          type: BucketType.money,
          balance: 15.00,
          lastUpdatedAt: DateTime.now(),
        ),
        Bucket(
          id: 'b2',
          childId: 'child1',
          familyId: 'family1',
          type: BucketType.investment,
          balance: 20.00,
          lastUpdatedAt: DateTime.now(),
        ),
        Bucket(
          id: 'b3',
          childId: 'child1',
          familyId: 'family1',
          type: BucketType.charity,
          balance: 3.00,
          lastUpdatedAt: DateTime.now(),
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            activeChildProvider.overrideWith((ref) => 'child1'),
            currentFamilyIdProvider.overrideWith((ref) => Stream.value('family1')),
            childProvider(
              (childId: 'child1', familyId: 'family1'),
            ).overrideWith((ref) => Stream.value(fakeChild)),
            childBucketsProvider(
              (childId: 'child1', familyId: 'family1'),
            ).overrideWith((ref) => Stream.value(fakeBuckets)),
            recentTransactionsProvider(
              (childId: 'child1', familyId: 'family1'),
            ).overrideWith((ref) => Stream.value([])),
          ],
          child: const MaterialApp(home: ChildHomeScreen()),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Money'), findsOneWidget);
      expect(find.text('Savings'), findsOneWidget);
      expect(find.text('Charity'), findsOneWidget);
      
      expect(find.text('\$15.00'), findsOneWidget);
      expect(find.text('\$20.00'), findsOneWidget);
      expect(find.text('\$3.00'), findsOneWidget);
    });

    testWidgets('shows bucket emojis', (tester) async {
      final fakeChild = Child(
        id: 'child1',
        familyId: 'family1',
        displayName: 'Sam',
        avatarEmoji: '😊',
        pinHash: 'hash123',
        createdAt: DateTime.now(),
      );

      final fakeBuckets = [
        Bucket(
          id: 'b1',
          childId: 'child1',
          familyId: 'family1',
          type: BucketType.money,
          balance: 0.00,
          lastUpdatedAt: DateTime.now(),
        ),
        Bucket(
          id: 'b2',
          childId: 'child1',
          familyId: 'family1',
          type: BucketType.investment,
          balance: 0.00,
          lastUpdatedAt: DateTime.now(),
        ),
        Bucket(
          id: 'b3',
          childId: 'child1',
          familyId: 'family1',
          type: BucketType.charity,
          balance: 0.00,
          lastUpdatedAt: DateTime.now(),
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            activeChildProvider.overrideWith((ref) => 'child1'),
            currentFamilyIdProvider.overrideWith((ref) => Stream.value('family1')),
            childProvider(
              (childId: 'child1', familyId: 'family1'),
            ).overrideWith((ref) => Stream.value(fakeChild)),
            childBucketsProvider(
              (childId: 'child1', familyId: 'family1'),
            ).overrideWith((ref) => Stream.value(fakeBuckets)),
            recentTransactionsProvider(
              (childId: 'child1', familyId: 'family1'),
            ).overrideWith((ref) => Stream.value([])),
          ],
          child: const MaterialApp(home: ChildHomeScreen()),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('💰'), findsOneWidget);
      expect(find.text('📈'), findsOneWidget);
      expect(find.text('❤️'), findsOneWidget);
    });
  });
}
