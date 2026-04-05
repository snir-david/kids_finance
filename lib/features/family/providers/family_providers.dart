/// Riverpod providers for family-related functionality.
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/family.dart' as domain;
import '../domain/parent_user.dart';
import '../domain/family_repository.dart';
import '../data/firebase_family_repository.dart';

/// Repository provider
final familyRepositoryProvider = Provider<FamilyRepository>((ref) {
  return FirebaseFamilyRepository(firestore: FirebaseFirestore.instance);
});

/// Stream provider for the current family
/// Requires familyId to be known (from auth or user profile)
final familyProvider =
    StreamProvider.family<domain.Family?, String>((ref, familyId) {
  final repository = ref.watch(familyRepositoryProvider);
  return repository.getFamilyStream(familyId);
});

/// Stream provider for the current user's profile
final currentUserProfileProvider =
    StreamProvider.family<ParentUser?, String>((ref, uid) {
  return FirebaseFirestore.instance
      .collection('userProfiles')
      .doc(uid)
      .snapshots()
      .map((snapshot) {
    if (!snapshot.exists) return null;
    return ParentUser.fromJson(snapshot.data()!);
  });
});
