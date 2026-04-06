/// Application routing configuration using GoRouter.
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/family_setup_screen.dart';
import '../features/auth/presentation/parent_home_screen.dart';
import '../features/auth/presentation/child_home_screen.dart';
import '../features/auth/presentation/child_pin_screen.dart';
import '../features/auth/providers/auth_providers.dart';
import '../features/auth/domain/app_user.dart';
import '../features/transactions/presentation/transaction_history_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(firebaseAuthStateProvider);
  final userRoleAsync = ref.watch(appUserRoleProvider);

  return GoRouter(
    initialLocation: '/splash',
    redirect: (BuildContext context, GoRouterState state) {
      final isLoggedIn = authState.valueOrNull != null;
      final currentLocation = state.matchedLocation;
      final userRole = userRoleAsync.valueOrNull ?? AppUserRole.unauthenticated;

      // Not authenticated: redirect to login (but allow family-setup)
      if (!isLoggedIn && currentLocation != '/login' && currentLocation != '/family-setup') {
        return '/login';
      }

      // Authenticated but on login page: redirect based on role
      if (isLoggedIn && currentLocation == '/login') {
        if (userRole == AppUserRole.parent) {
          return '/parent-home';
        } else if (userRole == AppUserRole.child) {
          // Child needs PIN verification
          return '/child-pin';
        }
        // Still loading role — stay on splash briefly
        return '/splash';
      }

      // Allow navigation
      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/family-setup',
        builder: (context, state) => const FamilySetupScreen(),
      ),
      GoRoute(
        path: '/parent-home',
        builder: (context, state) => const ParentHomeScreen(),
      ),
      GoRoute(
        path: '/child-home',
        builder: (context, state) => const ChildHomeScreen(),
      ),
      GoRoute(
        path: '/child-pin',
        builder: (context, state) => const ChildPinScreen(),
      ),
      GoRoute(
        path: '/transaction-history',
        builder: (context, state) {
          final extra = state.extra as ({String childId, String familyId, String childName});
          return TransactionHistoryScreen(
            childId: extra.childId,
            familyId: extra.familyId,
            childName: extra.childName,
          );
        },
      ),
    ],
  );
});

// Placeholder screens
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
