// TODO: written anticipatorily — wire up when CelebrationOverlay widget is available
// Testing celebration animations feature (Sprint 5A)

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// TODO: Import when available
// import 'package:kids_finance/core/widgets/celebration_overlay.dart';

enum CelebrationType {
  money,
  investment,
  charity,
}

// TODO: Remove this mock class when actual CelebrationOverlay is available
class CelebrationOverlay extends StatelessWidget {
  const CelebrationOverlay({
    super.key,
    required this.type,
    required this.amount,
    this.onComplete,
  });

  final CelebrationType type;
  final double amount;
  final VoidCallback? onComplete;

  @override
  Widget build(BuildContext context) {
    String emoji;
    String message;
    
    switch (type) {
      case CelebrationType.money:
        emoji = '💰';
        message = 'Money Added!';
        break;
      case CelebrationType.investment:
        emoji = '📈';
        message = 'Investment Multiplied!';
        break;
      case CelebrationType.charity:
        emoji = '❤️';
        message = 'Charity Donated!';
        break;
    }

    return Material(
      child: Center(
        key: Key('celebration_overlay_${type.name}'),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              emoji,
              style: const TextStyle(fontSize: 64),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: const TextStyle(fontSize: 24),
            ),
            const SizedBox(height: 8),
            Text(
              '\$${amount.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}

void main() {
  group('CelebrationOverlay Widget', () {
    testWidgets('CelebrationOverlay with CelebrationType.money — renders without error, finds key/text', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        const MaterialApp(
          home: CelebrationOverlay(
            type: CelebrationType.money,
            amount: 25.50,
          ),
        ),
      );

      // Wait for any animations to settle (if they exist)
      await tester.pumpAndSettle();

      // Assert
      expect(find.byKey(const Key('celebration_overlay_money')), findsOneWidget);
      expect(find.text('💰'), findsOneWidget);
      expect(find.text('Money Added!'), findsOneWidget);
      expect(find.text('\$25.50'), findsOneWidget);
    });

    testWidgets('CelebrationOverlay with CelebrationType.investment — renders without error', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        const MaterialApp(
          home: CelebrationOverlay(
            type: CelebrationType.investment,
            amount: 100.00,
          ),
        ),
      );

      // Wait for any animations to settle
      await tester.pumpAndSettle();

      // Assert
      expect(find.byKey(const Key('celebration_overlay_investment')), findsOneWidget);
      expect(find.text('📈'), findsOneWidget);
      expect(find.text('Investment Multiplied!'), findsOneWidget);
      expect(find.text('\$100.00'), findsOneWidget);
    });

    testWidgets('CelebrationOverlay with CelebrationType.charity — renders without error', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        const MaterialApp(
          home: CelebrationOverlay(
            type: CelebrationType.charity,
            amount: 15.75,
          ),
        ),
      );

      // Wait for any animations to settle
      await tester.pumpAndSettle();

      // Assert
      expect(find.byKey(const Key('celebration_overlay_charity')), findsOneWidget);
      expect(find.text('❤️'), findsOneWidget);
      expect(find.text('Charity Donated!'), findsOneWidget);
      expect(find.text('\$15.75'), findsOneWidget);
    });

    testWidgets('CelebrationOverlay displays correct emoji for money type', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        const MaterialApp(
          home: CelebrationOverlay(
            type: CelebrationType.money,
            amount: 50.00,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert - Money should have coin emoji
      expect(find.text('💰'), findsOneWidget);
      expect(find.text('📈'), findsNothing);
      expect(find.text('❤️'), findsNothing);
    });

    testWidgets('CelebrationOverlay displays correct emoji for investment type', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        const MaterialApp(
          home: CelebrationOverlay(
            type: CelebrationType.investment,
            amount: 200.00,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert - Investment should have chart emoji
      expect(find.text('📈'), findsOneWidget);
      expect(find.text('💰'), findsNothing);
      expect(find.text('❤️'), findsNothing);
    });

    testWidgets('CelebrationOverlay displays correct emoji for charity type', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        const MaterialApp(
          home: CelebrationOverlay(
            type: CelebrationType.charity,
            amount: 30.00,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert - Charity should have heart emoji
      expect(find.text('❤️'), findsOneWidget);
      expect(find.text('💰'), findsNothing);
      expect(find.text('📈'), findsNothing);
    });
  });
}
