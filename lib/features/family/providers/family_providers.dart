import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../domain/family.dart';
import '../domain/parent_user.dart';
import '../domain/family_repository.dart';
import '../data/firebase_family_repository.dart';

part 'family_providers.g.dart';

/// Repository provider
@riverpod
FamilyRepository familyRepository(FamilyRepositoryRef ref) {
  return FirebaseFamilyRepository(firestore: FirebaseFirestore.instance);
}

/// Stream provider for the current family
/// Requires familyId to be known (from auth or user profile)
@riverpod
Stream<Family?> family(FamilyRef ref, String familyId) {
  final repository = ref.watch(familyRepositoryProvider);
  return repository.getFamilyStream(familyId);
}

/// Stream provider for the current user's profile
@riverpod
Stream<ParentUser?> currentUserProfile(CurrentUserProfileRef ref, String uid) {
  return FirebaseFirestore.instance
      .collection('userProfiles')
      .doc(uid)
      .snapshots()
      .map((snapshot) {
    if (!snapshot.exists) return null;
    return ParentUser.fromJson(snapshot.data()!);
  });
}
