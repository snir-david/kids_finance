import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:bcrypt/bcrypt.dart';

// Creates a family document in the emulator and returns its ID.
Future<String> createTestFamily() async {
  final ref = await FirebaseFirestore.instance.collection('families').add({
    'name': 'Test Family',
    'createdAt': FieldValue.serverTimestamp(),
    'parentIds': [],
    'childIds': [],
  });
  return ref.id;
}

// Creates a Firebase Auth user and adds them as a parent member of [familyId].
// Returns the Firebase UID.
Future<String> createTestParent(
  String familyId, {
  String email = 'parent@example.com',
  String password = 'password123',
}) async {
  final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
    email: email,
    password: password,
  );
  final uid = credential.user!.uid;

  final batch = FirebaseFirestore.instance.batch();
  batch.set(
    FirebaseFirestore.instance.collection('familyMembers').doc(uid),
    {
      'familyId': familyId,
      'role': 'parent',
      'uid': uid,
      'email': email,
      'joinedAt': FieldValue.serverTimestamp(),
    },
  );
  batch.update(
    FirebaseFirestore.instance.collection('families').doc(familyId),
    {
      'parentIds': FieldValue.arrayUnion([uid]),
    },
  );
  await batch.commit();

  return uid;
}

// Creates a child document under [familyId] with a bcrypt-hashed PIN.
// Returns the child document ID.
Future<String> createTestChild(
  String familyId, {
  String name = 'Test Child',
  String pin = '1234',
}) async {
  final hashedPin = BCrypt.hashpw(pin, BCrypt.gensalt());
  final ref = await FirebaseFirestore.instance.collection('children').add({
    'familyId': familyId,
    'displayName': name,
    'pinHash': hashedPin,
    'avatar': 'default',
    'archived': false,
    'createdAt': FieldValue.serverTimestamp(),
  });

  await FirebaseFirestore.instance.collection('families').doc(familyId).update({
    'childIds': FieldValue.arrayUnion([ref.id]),
  });

  return ref.id;
}

// Creates 3 bucket documents (Money, Investment, Charity) for a child.
Future<void> createTestBuckets(String familyId, String childId) async {
  final buckets = [
    {'type': 'money', 'balance': 10.0},
    {'type': 'investment', 'balance': 5.0},
    {'type': 'charity', 'balance': 2.0},
  ];

  final batch = FirebaseFirestore.instance.batch();
  for (final bucket in buckets) {
    final ref = FirebaseFirestore.instance.collection('buckets').doc();
    batch.set(ref, {
      ...bucket,
      'childId': childId,
      'familyId': familyId,
      'lastUpdatedAt': FieldValue.serverTimestamp(),
    });
  }
  await batch.commit();
}

// Deletes all test data for [familyId] — use in tearDown to keep the emulator clean.
Future<void> cleanupTestData(String familyId) async {
  final firestore = FirebaseFirestore.instance;

  Future<void> deleteCollection(Query query) async {
    final snapshot = await query.get();
    final batch = firestore.batch();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    if (snapshot.docs.isNotEmpty) await batch.commit();
  }

  await deleteCollection(
    firestore.collection('buckets').where('familyId', isEqualTo: familyId),
  );
  await deleteCollection(
    firestore.collection('children').where('familyId', isEqualTo: familyId),
  );
  await deleteCollection(
    firestore.collection('familyMembers').where('familyId', isEqualTo: familyId),
  );
  await firestore.collection('families').doc(familyId).delete();

  // Sign out any authenticated test user.
  if (FirebaseAuth.instance.currentUser != null) {
    await FirebaseAuth.instance.currentUser!.delete();
  }
}
