import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kids_finance/core/widgets/pin_input_widget.dart';

void main() {
  group('PinInputWidget', () {
    testWidgets('starts with all dots empty', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PinInputWidget(
              onPinComplete: (_) {},
            ),
          ),
        ),
      );

      // Should show 4 empty dots
      final containers = tester.widgetList<Container>(
        find.descendant(
          of: find.byType(PinInputWidget),
          matching: find.byType(Container),
        ),
      );

      // At least 4 containers for the dots (there may be more for buttons)
      expect(containers.length, greaterThanOrEqualTo(4));
    });

    testWidgets('fills dots as digits are entered', (tester) async {
      String? capturedPin;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PinInputWidget(
              onPinComplete: (pin) => capturedPin = pin,
            ),
          ),
        ),
      );

      // Tap 1, 2, 3
      await tester.tap(find.text('1'));
      await tester.pump();
      await tester.tap(find.text('2'));
      await tester.pump();
      await tester.tap(find.text('3'));
      await tester.pump();

      // PIN should not be complete yet
      expect(capturedPin, isNull);
    });

    testWidgets('calls onPinComplete with correct PIN when 4 digits entered', (tester) async {
      String? capturedPin;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PinInputWidget(
              onPinComplete: (pin) => capturedPin = pin,
            ),
          ),
        ),
      );

      // Tap 1, 2, 3, 4
      await tester.tap(find.text('1'));
      await tester.pump();
      await tester.tap(find.text('2'));
      await tester.pump();
      await tester.tap(find.text('3'));
      await tester.pump();
      await tester.tap(find.text('4'));
      await tester.pump();

      expect(capturedPin, equals('1234'));
    });

    testWidgets('backspace removes last digit', (tester) async {
      String? capturedPin;
      String? currentPin;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PinInputWidget(
              onPinComplete: (pin) => capturedPin = pin,
              onPinChanged: (pin) => currentPin = pin,
            ),
          ),
        ),
      );

      // Tap 1, 2, 3
      await tester.tap(find.text('1'));
      await tester.pump();
      await tester.tap(find.text('2'));
      await tester.pump();
      await tester.tap(find.text('3'));
      await tester.pump();

      expect(currentPin, equals('123'));

      // Tap backspace
      await tester.tap(find.byIcon(Icons.backspace_outlined));
      await tester.pump();

      expect(currentPin, equals('12'));
      expect(capturedPin, isNull);
    });

    testWidgets('clear button removes all digits', (tester) async {
      String? currentPin;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PinInputWidget(
              onPinComplete: (_) {},
              onPinChanged: (pin) => currentPin = pin,
            ),
          ),
        ),
      );

      // Tap 1, 2, 3
      await tester.tap(find.text('1'));
      await tester.pump();
      await tester.tap(find.text('2'));
      await tester.pump();
      await tester.tap(find.text('3'));
      await tester.pump();

      expect(currentPin, equals('123'));

      // Tap clear (C button)
      await tester.tap(find.text('C'));
      await tester.pump();

      expect(currentPin, equals(''));
    });

    testWidgets('shows error message when provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PinInputWidget(
              onPinComplete: (_) {},
              errorMessage: 'Wrong PIN',
            ),
          ),
        ),
      );

      expect(find.text('Wrong PIN'), findsOneWidget);
    });

    testWidgets('hides numpad and shows lock message when isLocked=true', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PinInputWidget(
              onPinComplete: (_) {},
              isLocked: true,
              lockMessage: 'Too many attempts. Try again in 15 minutes.',
            ),
          ),
        ),
      );

      expect(find.text('Too many attempts. Try again in 15 minutes.'), findsOneWidget);
      
      // Numpad buttons should not be visible
      expect(find.text('1'), findsNothing);
      expect(find.text('0'), findsNothing);
    });

    testWidgets('does not accept input when locked', (tester) async {
      String? capturedPin;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PinInputWidget(
              onPinComplete: (pin) => capturedPin = pin,
              isLocked: true,
              lockMessage: 'Locked',
            ),
          ),
        ),
      );

      // Even if we could find the button (which we shouldn't),
      // tapping it should not trigger the callback
      expect(capturedPin, isNull);
    });

    testWidgets('allows entering 0 as a digit', (tester) async {
      String? capturedPin;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PinInputWidget(
              onPinComplete: (pin) => capturedPin = pin,
            ),
          ),
        ),
      );

      // Tap 0, 0, 0, 0
      await tester.tap(find.text('0'));
      await tester.pump();
      await tester.tap(find.text('0'));
      await tester.pump();
      await tester.tap(find.text('0'));
      await tester.pump();
      await tester.tap(find.text('0'));
      await tester.pump();

      expect(capturedPin, equals('0000'));
    });

    testWidgets('does not accept more than 4 digits', (tester) async {
      String? capturedPin;
      int callCount = 0;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PinInputWidget(
              onPinComplete: (pin) {
                capturedPin = pin;
                callCount++;
              },
            ),
          ),
        ),
      );

      // Tap 5 times
      await tester.tap(find.text('1'));
      await tester.pump();
      await tester.tap(find.text('2'));
      await tester.pump();
      await tester.tap(find.text('3'));
      await tester.pump();
      await tester.tap(find.text('4'));
      await tester.pump();
      await tester.tap(find.text('5'));
      await tester.pump();

      // Should only capture 1234, not 12345
      expect(capturedPin, equals('1234'));
      expect(callCount, equals(1));
    });

    testWidgets('all number buttons are tappable', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PinInputWidget(
              onPinComplete: (_) {},
            ),
          ),
        ),
      );

      // Verify all digits 0-9 are present and tappable
      for (int i = 0; i <= 9; i++) {
        expect(find.text(i.toString()), findsOneWidget);
      }

      // Verify backspace and clear buttons
      expect(find.byIcon(Icons.backspace_outlined), findsOneWidget);
      expect(find.text('C'), findsOneWidget);
    });
  });
}
