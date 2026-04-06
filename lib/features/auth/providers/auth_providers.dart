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
  final user = authState.value;
  
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

/// Stream provider for the current user's role from Firestore userProfiles
final appUserRoleProvider = StreamProvider<AppUserRole>((ref) {
  final authState = ref.watch(firebaseAuthStateProvider);
  final user = authState.value;

  if (user == null) return Stream.value(AppUserRole.unauthenticated);

  return FirebaseFirestore.instance
      .collection('userProfiles')
      .doc(user.uid)
      .snapshots()
      .map((snapshot) {
    if (!snapshot.exists) return AppUserRole.unauthenticated;
    final roleStr = snapshot.data()?['role'] as String?;
    return AppUserRole.fromJson(roleStr ?? 'unauthenticated');
  });
});

/// Notifier for the currently active child (when in child mode)
class ActiveChildNotifier extends Notifier<String?> {
  ActiveChildNotifier([this._initial]);
  final String? _initial;

  @override
  String? build() => _initial;

  void setState(String? value) => state = value;
}

/// State provider for the currently active child (when in child mode)
final activeChildProvider =
    NotifierProvider<ActiveChildNotifier, String?>(ActiveChildNotifier.new);
