import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../children/providers/children_providers.dart';
import 'auth_providers.dart';

/// Session validity states for a child's authenticated session.
enum SessionState {
  /// Child has a valid, non-expired session.
  valid,

  /// Child's session has expired — redirect to PIN entry.
  expired,

  /// No child is currently authenticated.
  notAuthenticated,
}

/// Watches the active child's [Child.sessionExpiresAt] and returns the
/// current [SessionState].
///
/// Every child-mode screen should watch this provider and redirect to
/// `/child-pin` whenever the state is [SessionState.expired].
///
/// Session expiry is stored in Firestore (`sessionExpiresAt` field) and
/// set to 24 hours after a successful PIN entry.
final childSessionValidProvider = Provider<SessionState>((ref) {
  final childId = ref.watch(activeChildProvider);
  if (childId == null) return SessionState.notAuthenticated;

  final familyId = ref.watch(currentFamilyIdProvider).value;
  if (familyId == null) return SessionState.notAuthenticated;

  final childAsync = ref.watch(
    childProvider((childId: childId, familyId: familyId)),
  );

  return childAsync.when(
    data: (child) {
      if (child == null) return SessionState.notAuthenticated;
      final expiresAt = child.sessionExpiresAt;
      if (expiresAt == null) return SessionState.expired;
      if (DateTime.now().isAfter(expiresAt)) return SessionState.expired;
      return SessionState.valid;
    },
    // Hold state as valid while Firestore data is loading to avoid
    // spurious redirects on screen initialisation.
    loading: () => SessionState.valid,
    error: (_, __) => SessionState.notAuthenticated,
  );
});
