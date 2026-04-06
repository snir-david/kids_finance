import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kids_finance/core/widgets/bucket_card.dart';
import 'package:kids_finance/core/widgets/child_avatar.dart';
import 'package:kids_finance/core/widgets/loading_overlay.dart';
import 'package:kids_finance/core/widgets/error_display.dart';
import 'package:kids_finance/features/buckets/domain/bucket.dart';

void main() {
  group('BucketCard', () {
    testWidgets('shows money bucket with correct color and balance', (tester) async {
      final bucket = Bucket(
        id: 'b1',
        childId: 'c1',
        familyId: 'f1',
        type: BucketType.money,
        balance: 25.50,
        lastUpdatedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BucketCard(bucket: bucket, isKidMode: false),
          ),
        ),
      );

      expect(find.text('\$25.50'), findsOneWidget);
      expect(find.text('💰'), findsOneWidget);
      expect(find.text('Money'), findsOneWidget);
    });

    testWidgets('shows investment bucket with blue color', (tester) async {
      final bucket = Bucket(
        id: 'b2',
        childId: 'c1',
        familyId: 'f1',
        type: BucketType.investment,
        balance: 100.00,
        lastUpdatedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BucketCard(bucket: bucket, isKidMode: false),
          ),
        ),
      );

      expect(find.text('\$100.00'), findsOneWidget);
      expect(find.text('📈'), findsOneWidget);
      expect(find.text('Investments'), findsOneWidget);
    });

    testWidgets('shows charity bucket with pink color', (tester) async {
      final bucket = Bucket(
        id: 'b3',
        childId: 'c1',
        familyId: 'f1',
        type: BucketType.charity,
        balance: 5.25,
        lastUpdatedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BucketCard(bucket: bucket, isKidMode: false),
          ),
        ),
      );

      expect(find.text('\$5.25'), findsOneWidget);
      expect(find.text('❤️'), findsOneWidget);
      expect(find.text('Charity'), findsOneWidget);
    });

    testWidgets('calls onTap when tapped', (tester) async {
      bool tapped = false;
      final bucket = Bucket(
        id: 'b1',
        childId: 'c1',
        familyId: 'f1',
        type: BucketType.money,
        balance: 10.00,
        lastUpdatedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BucketCard(
              bucket: bucket,
              isKidMode: false,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(BucketCard));
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
    });

    testWidgets('kid mode shows larger layout', (tester) async {
      final bucket = Bucket(
        id: 'b1',
        childId: 'c1',
        familyId: 'f1',
        type: BucketType.money,
        balance: 50.00,
        lastUpdatedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BucketCard(bucket: bucket, isKidMode: true),
          ),
        ),
      );

      // Wait for animation to complete
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      // Kid mode should show emoji, balance, and label
      expect(find.text('💰'), findsOneWidget);
      expect(find.text('\$50.00'), findsOneWidget);
      expect(find.text('Money'), findsOneWidget);
    });

    testWidgets('parent mode shows compact layout with chevron', (tester) async {
      final bucket = Bucket(
        id: 'b1',
        childId: 'c1',
        familyId: 'f1',
        type: BucketType.money,
        balance: 75.99,
        lastUpdatedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BucketCard(bucket: bucket, isKidMode: false),
          ),
        ),
      );

      // Parent mode should show chevron icon
      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
      expect(find.text('💰'), findsOneWidget);
      expect(find.text('\$75.99'), findsOneWidget);
    });
  });

  group('ChildAvatar', () {
    testWidgets('shows emoji and name in medium size', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ChildAvatar(
              emoji: '👦',
              name: 'Alex',
              size: AvatarSize.medium,
            ),
          ),
        ),
      );

      expect(find.text('👦'), findsOneWidget);
      expect(find.text('Alex'), findsOneWidget);
    });

    testWidgets('shows selected border when isSelected=true', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ChildAvatar(
              emoji: '👧',
              name: 'Emma',
              isSelected: true,
            ),
          ),
        ),
      );

      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(ChildAvatar),
          matching: find.byType(Container),
        ).first,
      );

      final decoration = container.decoration as BoxDecoration;
      expect(decoration.border, isNotNull);
    });

    testWidgets('calls onTap when tapped', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChildAvatar(
              emoji: '👦',
              name: 'Alex',
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(InkWell));
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
    });

    testWidgets('small size hides name', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ChildAvatar(
              emoji: '👧',
              name: 'Emma',
              size: AvatarSize.small,
            ),
          ),
        ),
      );

      expect(find.text('👧'), findsOneWidget);
      expect(find.text('Emma'), findsNothing);
    });

    testWidgets('large size shows larger emoji and text', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ChildAvatar(
              emoji: '🧒',
              name: 'Jordan',
              size: AvatarSize.large,
            ),
          ),
        ),
      );

      expect(find.text('🧒'), findsOneWidget);
      expect(find.text('Jordan'), findsOneWidget);
    });
  });

  group('LoadingOverlay', () {
    testWidgets('shows CircularProgressIndicator', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LoadingOverlay(),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows message when provided', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LoadingOverlay(message: 'Loading data...'),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Loading data...'), findsOneWidget);
    });

    testWidgets('does not show message when not provided', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LoadingOverlay(),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byType(Text), findsNothing);
    });
  });

  group('ErrorDisplay', () {
    testWidgets('shows error message', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ErrorDisplay(message: 'Something went wrong'),
          ),
        ),
      );

      expect(find.text('Something went wrong'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('shows retry button when onRetry provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ErrorDisplay(
              message: 'Network error',
              onRetry: () {},
            ),
          ),
        ),
      );

      expect(find.text('Network error'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
      expect(find.byIcon(Icons.refresh), findsOneWidget);
    });

    testWidgets('does not show retry button when onRetry is null', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ErrorDisplay(message: 'Error occurred'),
          ),
        ),
      );

      expect(find.text('Error occurred'), findsOneWidget);
      expect(find.text('Retry'), findsNothing);
      expect(find.byIcon(Icons.refresh), findsNothing);
    });

    testWidgets('calls onRetry when retry tapped', (tester) async {
      bool retried = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ErrorDisplay(
              message: 'Failed to load',
              onRetry: () => retried = true,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      expect(retried, isTrue);
    });
  });
}
