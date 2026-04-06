import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kids_finance/features/auth/presentation/login_screen.dart';
import 'package:kids_finance/features/auth/presentation/family_setup_screen.dart';

void main() {
  group('LoginScreen', () {
    testWidgets('renders email and password fields', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: LoginScreen()),
        ),
      );

      expect(find.byType(TextFormField), findsNWidgets(2));
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
    });

    testWidgets('renders Google sign-in button', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: LoginScreen()),
        ),
      );

      expect(find.text('Continue with Google'), findsOneWidget);
    });

    testWidgets('shows sign in button', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: LoginScreen()),
        ),
      );

      expect(find.text('Sign In'), findsOneWidget);
    });

    testWidgets('shows app title and subtitle', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: LoginScreen()),
        ),
      );

      expect(find.text('KidsFinance 💰'), findsOneWidget);
      expect(find.text('Teaching kids about money'), findsOneWidget);
    });

    testWidgets('password visibility toggle is present', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: LoginScreen()),
        ),
      );

      // Should have visibility icon
      expect(find.byIcon(Icons.visibility), findsOneWidget);

      // Tap visibility toggle
      await tester.tap(find.byIcon(Icons.visibility));
      await tester.pump();

      // Should now show visibility_off icon
      expect(find.byIcon(Icons.visibility_off), findsOneWidget);
    });

    testWidgets('shows family setup link', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: LoginScreen()),
        ),
      );

      expect(find.text('New family? Set up here'), findsOneWidget);
    });
  });

  group('FamilySetupScreen', () {
    testWidgets('renders family name input', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: FamilySetupScreen()),
        ),
      );

      expect(find.text('Family Name'), findsOneWidget);
      expect(find.byType(TextFormField), findsOneWidget);
    });

    testWidgets('shows welcome message', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: FamilySetupScreen()),
        ),
      );

      expect(find.text('Welcome to KidsFinance! 🎉'), findsOneWidget);
      expect(find.text("Let's create your family profile"), findsOneWidget);
    });

    testWidgets('shows family icon', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: FamilySetupScreen()),
        ),
      );

      expect(find.byIcon(Icons.family_restroom), findsOneWidget);
    });

    testWidgets('shows create family button', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: FamilySetupScreen()),
        ),
      );

      expect(find.text('Create Family'), findsOneWidget);
    });

    testWidgets('shows helpful footer text', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: FamilySetupScreen()),
        ),
      );

      expect(
        find.text('You can add children and other parents after creating your family.'),
        findsOneWidget,
      );
    });
  });
}
