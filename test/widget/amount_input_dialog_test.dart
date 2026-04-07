// Testing zero-amount validation fix (Sprint 5A)
// Tests for AmountInputDialog to ensure zero and empty values are properly handled

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kids_finance/core/widgets/amount_input_dialog.dart';

void main() {
  group('AmountInputDialog - Zero Amount Validation', () {
    testWidgets('Money dialog — submit button disabled when amount = 0', (tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () async {
                    await AmountInputDialog.show(
                      context,
                      title: 'Add Money',
                      isMultiplier: false,
                    );
                  },
                  child: const Text('Show Dialog'),
                );
              },
            ),
          ),
        ),
      );

      // Act - Open dialog
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Enter zero amount
      await tester.enterText(find.byType(TextField), '0');
      await tester.pumpAndSettle();

      // Assert - Confirm button should be disabled
      final confirmButton = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Confirm'),
      );
      expect(confirmButton.onPressed, isNull, reason: 'Button should be disabled for zero amount');
    });

    testWidgets('Money dialog — submit button disabled when amount field is empty', (tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () async {
                    await AmountInputDialog.show(
                      context,
                      title: 'Add Money',
                      isMultiplier: false,
                    );
                  },
                  child: const Text('Show Dialog'),
                );
              },
            ),
          ),
        ),
      );

      // Act - Open dialog
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Leave field empty (don't enter anything)
      
      // Assert - Confirm button should be disabled
      final confirmButton = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Confirm'),
      );
      expect(confirmButton.onPressed, isNull, reason: 'Button should be disabled when field is empty');
    });

    testWidgets('Money dialog — submit button enabled when amount > 0', (tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () async {
                    await AmountInputDialog.show(
                      context,
                      title: 'Add Money',
                      isMultiplier: false,
                    );
                  },
                  child: const Text('Show Dialog'),
                );
              },
            ),
          ),
        ),
      );

      // Act - Open dialog
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Enter valid amount
      await tester.enterText(find.byType(TextField), '25.50');
      await tester.pumpAndSettle();

      // Assert - Confirm button should be enabled
      final confirmButton = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Confirm'),
      );
      expect(confirmButton.onPressed, isNotNull, reason: 'Button should be enabled for valid amount');
    });

    testWidgets('Investment dialog — submit button disabled when multiplier = 0', (tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () async {
                    await AmountInputDialog.show(
                      context,
                      title: 'Multiply Investment',
                      isMultiplier: true,
                    );
                  },
                  child: const Text('Show Dialog'),
                );
              },
            ),
          ),
        ),
      );

      // Act - Open dialog
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Enter zero multiplier
      await tester.enterText(find.byType(TextField), '0');
      await tester.pumpAndSettle();

      // Assert - Confirm button should be disabled
      final confirmButton = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Confirm'),
      );
      expect(confirmButton.onPressed, isNull, reason: 'Button should be disabled for zero multiplier');
    });

    testWidgets('Investment dialog — submit button disabled when multiplier field is empty', (tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () async {
                    await AmountInputDialog.show(
                      context,
                      title: 'Multiply Investment',
                      isMultiplier: true,
                    );
                  },
                  child: const Text('Show Dialog'),
                );
              },
            ),
          ),
        ),
      );

      // Act - Open dialog
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Leave field empty
      
      // Assert - Confirm button should be disabled
      final confirmButton = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Confirm'),
      );
      expect(confirmButton.onPressed, isNull, reason: 'Button should be disabled when field is empty');
    });

    testWidgets('Investment dialog — submit button enabled when multiplier > 0', (tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () async {
                    await AmountInputDialog.show(
                      context,
                      title: 'Multiply Investment',
                      isMultiplier: true,
                    );
                  },
                  child: const Text('Show Dialog'),
                );
              },
            ),
          ),
        ),
      );

      // Act - Open dialog
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Enter valid multiplier
      await tester.enterText(find.byType(TextField), '2.5');
      await tester.pumpAndSettle();

      // Assert - Confirm button should be enabled
      final confirmButton = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Confirm'),
      );
      expect(confirmButton.onPressed, isNotNull, reason: 'Button should be enabled for valid multiplier');
    });

    testWidgets('Money dialog shows error message for zero amount', (tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () async {
                    await AmountInputDialog.show(
                      context,
                      title: 'Add Money',
                      isMultiplier: false,
                    );
                  },
                  child: const Text('Show Dialog'),
                );
              },
            ),
          ),
        ),
      );

      // Act - Open dialog
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Enter zero amount
      await tester.enterText(find.byType(TextField), '0');
      await tester.pumpAndSettle();

      // Assert - Error message should appear
      expect(find.text('Amount must be at least 0.01'), findsOneWidget);
    });

    testWidgets('Investment dialog shows error message for zero multiplier', (tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () async {
                    await AmountInputDialog.show(
                      context,
                      title: 'Multiply Investment',
                      isMultiplier: true,
                    );
                  },
                  child: const Text('Show Dialog'),
                );
              },
            ),
          ),
        ),
      );

      // Act - Open dialog
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Enter zero multiplier
      await tester.enterText(find.byType(TextField), '0');
      await tester.pumpAndSettle();

      // Assert - Error message should appear
      expect(find.text('Multiplier must be greater than 0'), findsOneWidget);
    });
  });
}

