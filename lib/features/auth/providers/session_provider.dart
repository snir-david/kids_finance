import 'package:flutter_riverpod/flutter_riverpod.dart';
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

/// Tracks whether a child is currently active (selected from the picker).
/// Returns [SessionState.valid] when a child is active, [SessionState.notAuthenticated] otherwise.
final childSessionValidProvider = Provider<SessionState>((ref) {
  final childId = ref.watch(activeChildProvider);
  if (childId == null) return SessionState.notAuthenticated;
  return SessionState.valid;
});
