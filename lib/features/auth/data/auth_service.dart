import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<UserCredential> signInWithEmailPassword(
    String email,
    String password,
  ) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  Future<UserCredential> signInWithGoogle() async {
    // TODO: Google Sign-In requires additional setup (SHA-1, google-services.json).
    // Currently disabled — use email/password sign-in instead.
    throw Exception('Google Sign-In is not yet configured. Please use email and password.');
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  User? getCurrentUser() {
    return _auth.currentUser;
  }

  Stream<User?> authStateChanges() {
    return _auth.authStateChanges();
  }

  /// Creates a new family document and the creator's user-profile document
  /// as a single atomic Firestore batch write.
  ///
  /// [familyName] is the human-readable family name (e.g. "The Smith Family").
  /// It is stored on the family document, not on the user profile.
  Future<void> createFamily(String familyName) async {
    var user = getCurrentUser();
    if (user == null) {
      // Sign-up just completed; wait for the auth state stream to emit the
      // authenticated user.  Using `.first` is unsafe here because the stream
      // may immediately re-emit `null` (the previous unauthenticated state)
      // before emitting the newly signed-in user.  `.firstWhere` skips nulls.
      user = await _auth.authStateChanges().firstWhere((u) => u != null);
      if (user == null) {
        throw Exception('No authenticated user');
      }
    }

    final familyId = _firestore.collection('families').doc().id;

    // Derive a display name for the user's profile from their Firebase account.
    // For email/password sign-up, user.displayName is always null, so we fall
    // back to the local part of the email address (e.g. "jane" from "jane@…").
    final userDisplayName = user.displayName ??
        (user.email?.split('@').firstOrNull ?? 'Parent');

    final batch = _firestore.batch();

    batch.set(_firestore.collection('families').doc(familyId), {
      'name': familyName,
      'parentIds': [user.uid],
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'schemaVersion': '1.0.0',
    });

    batch.set(_firestore.collection('userProfiles').doc(user.uid), {
      'email': user.email,
      'displayName': userDisplayName, // user's own name, NOT the family name
      'familyId': familyId,
      'role': 'parent',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  Future<UserCredential> createAccountWithEmailPassword(
    String email,
    String password,
  ) async {
    try {
      return await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  Future<void> sendEmailVerification() async {
    final user = getCurrentUser();
    if (user != null && !user.emailVerified) {
      await user.sendEmailVerification();
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  Exception _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return Exception('No user found with this email');
      case 'wrong-password':
        return Exception('Incorrect password');
      case 'email-already-in-use':
        return Exception('An account already exists with this email');
      case 'invalid-email':
        return Exception('Invalid email address');
      case 'weak-password':
        return Exception('Password is too weak');
      case 'user-disabled':
        return Exception('This account has been disabled');
      default:
        return Exception('Authentication error: ${e.message}');
    }
  }
}
