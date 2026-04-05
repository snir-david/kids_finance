import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../domain/app_user.dart';

part 'auth_providers.g.dart';

/// Watches Firebase auth state and emits AppUser or null
@riverpod
Stream<AppUser?> authState(AuthStateRef ref) {
  return FirebaseAuth.instance.authStateChanges().map((firebaseUser) {
    if (firebaseUser == null) return null;
    
    // TODO: Fetch user role from Firestore user profile
    // For now, return a basic AppUser
    return AppUser(
      id: firebaseUser.uid,
      email: firebaseUser.email ?? '',
      role: 'parent', // Placeholder - will be fetched from Firestore
    );
  });
}

/// Current authenticated user provider
@riverpod
AppUser? currentUser(CurrentUserRef ref) {
  final authState = ref.watch(authStateProvider);
  return authState.valueOrNull;
}
