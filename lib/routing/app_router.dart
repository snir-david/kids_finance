/// Application routing configuration using GoRouter.
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/parent_home_screen.dart';
import '../features/auth/presentation/child_home_screen.dart';
import '../features/auth/presentation/child_pin_screen.dart';
import '../features/auth/providers/auth_providers.dart';
import '../features/auth/domain/app_user.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(firebaseAuthStateProvider);

  return GoRouter(
    initialLocation: '/splash',
    redirect: (BuildContext context, GoRouterState state) {
      final isLoggedIn = authState.valueOrNull != null;
      final currentLocation = state.matchedLocation;
      final userRole = ref.read(appUserRoleProvider);

      // Not authenticated: redirect to login
      if (!isLoggedIn && currentLocation != '/login') {
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
