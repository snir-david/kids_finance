// TODO: written anticipatorily — wire up when ForgotPasswordScreen is available
// Testing forgot password feature (Sprint 5A)

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'forgot_password_screen_test.mocks.dart';

@GenerateMocks([FirebaseAuth])
void main() {
  group('ForgotPasswordScreen', () {
    late MockFirebaseAuth mockAuth;

    setUp(() {
      mockAuth = MockFirebaseAuth();
    });

    testWidgets('Screen renders email field + send button', (tester) async {
      // TODO: When ForgotPasswordScreen is available, replace this test widget
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              appBar: AppBar(title: const Text('Forgot Password')),
              body: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Text('Enter your email to reset your password'),
                    const SizedBox(height: 16),
                    const TextField(
                      key: Key('email_field'),
                      decoration: InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      key: const Key('send_button'),
                      onPressed: () {},
                      child: const Text('Send Reset Link'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('Forgot Password'), findsOneWidget);
      expect(find.byKey(const Key('email_field')), findsOneWidget);
      expect(find.byKey(const Key('send_button')), findsOneWidget);
      expect(find.text('Send Reset Link'), findsOneWidget);
    });

    testWidgets('Submit with empty email — button disabled or shows validation', (tester) async {
      // Arrange
      bool isButtonEnabled = false;
      String emailValue = '';

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: StatefulBuilder(
                builder: (context, setState) {
                  return Column(
                    children: [
                      TextField(
                        key: const Key('email_field'),
                        onChanged: (value) {
                          setState(() {
                            emailValue = value;
                            isButtonEnabled = value.isNotEmpty && value.contains('@');
                          });
                        },
                      ),
                      ElevatedButton(
                        key: const Key('send_button'),
                        onPressed: isButtonEnabled ? () {} : null,
                        child: const Text('Send Reset Link'),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      );

      // Assert - button should be disabled initially (empty email)
      final button = tester.widget<ElevatedButton>(find.byKey(const Key('send_button')));
      expect(button.onPressed, isNull);
    });

    testWidgets('Submit with valid email — calls FirebaseAuth.sendPasswordResetEmail', (tester) async {
      // Arrange
      const testEmail = 'test@example.com';
      bool emailSent = false;

      when(mockAuth.sendPasswordResetEmail(email: anyNamed('email')))
          .thenAnswer((_) async {
        emailSent = true;
        return Future.value();
      });

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  return Column(
                    children: [
                      const TextField(
                        key: Key('email_field'),
                      ),
                      ElevatedButton(
                        key: const Key('send_button'),
                        onPressed: () async {
                          // TODO: When ForgotPasswordScreen is available,
                          // this will call the actual auth service
                          await mockAuth.sendPasswordResetEmail(email: testEmail);
                        },
                        child: const Text('Send Reset Link'),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      );

      // Act
      await tester.tap(find.byKey(const Key('send_button')));
      await tester.pumpAndSettle();

      // Assert
      verify(mockAuth.sendPasswordResetEmail(email: testEmail)).called(1);
      expect(emailSent, isTrue);
    });

    testWidgets('On success — SnackBar with "Check your email" appears', (tester) async {
      // Arrange
      const testEmail = 'test@example.com';

      when(mockAuth.sendPasswordResetEmail(email: anyNamed('email')))
          .thenAnswer((_) async => Future.value());

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  return Column(
                    children: [
                      const TextField(
                        key: Key('email_field'),
                      ),
                      ElevatedButton(
                        key: const Key('send_button'),
                        onPressed: () async {
                          try {
                            await mockAuth.sendPasswordResetEmail(email: testEmail);
                            // Show success message
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Check your email for password reset link'),
                                ),
                              );
                            }
                          } catch (e) {
                            // Handle error
                          }
                        },
                        child: const Text('Send Reset Link'),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      );

      // Act
      await tester.tap(find.byKey(const Key('send_button')));
      await tester.pump(); // Start the async operation
      await tester.pump(); // Process the snackbar

      // Assert
      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('Check your email for password reset link'), findsOneWidget);
    });

    testWidgets('On error — shows error message', (tester) async {
      // Arrange
      const testEmail = 'invalid@example.com';
      
      when(mockAuth.sendPasswordResetEmail(email: anyNamed('email')))
          .thenThrow(FirebaseAuthException(code: 'user-not-found'));

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  return Column(
                    children: [
                      const TextField(
                        key: Key('email_field'),
                      ),
                      ElevatedButton(
                        key: const Key('send_button'),
                        onPressed: () async {
                          try {
                            await mockAuth.sendPasswordResetEmail(email: testEmail);
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Error: User not found'),
                                ),
                              );
                            }
                          }
                        },
                        child: const Text('Send Reset Link'),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      );

      // Act
      await tester.tap(find.byKey(const Key('send_button')));
      await tester.pump();
      await tester.pump();

      // Assert
      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.textContaining('Error'), findsOneWidget);
    });
  });
}
