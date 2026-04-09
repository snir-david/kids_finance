/// Application routing configuration using GoRouter.
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/family_setup_screen.dart';
import '../features/auth/presentation/parent_home_screen.dart';
import '../features/auth/presentation/child_home_screen.dart';
import '../features/auth/presentation/child_picker_screen.dart';
import '../features/auth/presentation/forgot_password_screen.dart';
import '../features/auth/providers/auth_providers.dart';
import '../features/auth/domain/app_user.dart';
import '../features/settings/presentation/settings_screen.dart';
import '../features/transactions/presentation/transaction_history_screen.dart';
import '../features/badges/presentation/screens/badges_screen.dart';

/// A [ChangeNotifier] that tells GoRouter to re-evaluate its redirect whenever
/// the Firebase auth state or the user's Firestore role changes.
///
/// Using [refreshListenable] keeps the [GoRouter] instance STABLE — it is
/// created once and never recreated. Without this, wrapping [GoRouter] in a
/// Riverpod [Provider] that calls [ref.watch] causes a new router instance
/// to be returned on every state change, which resets the navigation stack
/// to [initialLocation] and produces the classic "stuck on splash" bug.
class _RouterRefreshNotifier extends ChangeNotifier {
  _RouterRefreshNotifier(Ref ref) {
    // Re-trigger GoRouter's redirect whenever auth or role state changes.
    ref.listen<AsyncValue>(
      firebaseAuthStateProvider,
      (_, __) => notifyListeners(),
    );
    ref.listen<AsyncValue>(
      appUserRoleProvider,
      (_, __) => notifyListeners(),
    );
  }
}

final appRouterProvider = Provider<GoRouter>((ref) {
  // Create the notifier and dispose it with the provider.
  final notifier = _RouterRefreshNotifier(ref);
  ref.onDispose(notifier.dispose);

  return GoRouter(
    initialLocation: '/splash',
    // GoRouter calls redirect whenever notifier fires — the router itself is
    // never recreated, only the redirect logic re-runs.
    refreshListenable: notifier,
    redirect: (BuildContext context, GoRouterState state) {
      // Use ref.read (not ref.watch) — reading stable state, not subscribing.
      final isLoggedIn = ref.read(firebaseAuthStateProvider).value != null;
      final userRole =
          ref.read(appUserRoleProvider).value ?? AppUserRole.unauthenticated;
      final currentLocation = state.matchedLocation;

      // ── Unauthenticated ──────────────────────────────────────────────────
      // Only /login, /family-setup, and /forgot-password are accessible without an account.
      if (!isLoggedIn) {
        if (currentLocation == '/login' ||
            currentLocation == '/family-setup' ||
            currentLocation == '/forgot-password') {
          return null; // Allow
        }
        return '/login';
      }

      // ── Authenticated ─────────────────────────────────────────────────────
      // If the user is logged in and still on an auth-only screen (login,
      // splash, or family-setup), redirect them based on their role.
      // This covers:
      //   • Normal login → straight to home
      //   • Family creation → role becomes 'parent' → auto-redirect out of
      //     /family-setup to /parent-home (no explicit context.go() needed)
      //   • Cold start while already logged in → /splash redirects to home
      if (currentLocation == '/login' ||
          currentLocation == '/splash' ||
          currentLocation == '/family-setup') {
        if (userRole == AppUserRole.parent) return '/parent-home';
        if (userRole == AppUserRole.child) return '/child-picker';
        // Role not yet loaded (Firestore profile not written yet).
        // Return null to stay on the current screen; when appUserRoleProvider
        // emits the real role, notifier fires and this redirect runs again.
        return null;
      }

      // Allow all other navigation.
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
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
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
        path: '/child-picker',
        builder: (context, state) => const ChildPickerScreen(),
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
      GoRoute(
        path: '/badges',
        builder: (context, state) {
          final extra = state.extra as ({String childId, String familyId});
          return BadgesScreen(
            childId: extra.childId,
            familyId: extra.familyId,
          );
        },
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
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
