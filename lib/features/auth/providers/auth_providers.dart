/// Riverpod providers for authentication and user state.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/app_user.dart';
import '../data/auth_service.dart';
import '../data/pin_service.dart';

/// Provider for AuthService
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

/// Provider for PinService
final pinServiceProvider = Provider<PinService>((ref) {
  return PinService();
});

/// Watches Firebase auth state and emits User or null
final firebaseAuthStateProvider =
    StreamProvider<firebase_auth.User?>((ref) {
  return firebase_auth.FirebaseAuth.instance.authStateChanges();
});

/// Stream provider for the current family ID from user profile
final currentFamilyIdProvider = StreamProvider<String?>((ref) {
  final authState = ref.watch(firebaseAuthStateProvider);
  final user = authState.valueOrNull;
  
  if (user == null) return Stream.value(null);
  
  return FirebaseFirestore.instance
      .collection('userProfiles')
      .doc(user.uid)
      .snapshots()
      .map((snapshot) {
    if (!snapshot.exists) return null;
    return snapshot.data()?['familyId'] as String?;
  });
});

/// Provider for the current user's role
final appUserRoleProvider = Provider<AppUserRole>((ref) {
  final authState = ref.watch(firebaseAuthStateProvider);
  final user = authState.valueOrNull;
  
  if (user == null) return AppUserRole.unauthenticated;
  
  // TODO: Fetch from Firestore user profile
  // For now, default to parent
  return AppUserRole.parent;
});

/// State provider for the currently active child (when in child mode)
final activeChildProvider = StateProvider<String?>((ref) => null);
