# Data Layer Setup Guide

**Maintained by:** JARVIS (Backend Dev)
**Updated:** 2026-04-08 (Sprints 5A-5D)

---

## What Has Been Built

### Domain Layer
- Family, Child, Bucket, Transaction, AppUser models — plain Dart + Equatable (no Freezed)
- Repository interfaces for all four feature areas
- Firebase implementations for all four repositories

### Offline Layer
- Hive-backed OfflineQueue with 24h TTL
- SyncEngine that replays operations on reconnect
- ConnectivityService (connectivity_plus 6.x)
- Conflict detection + user-prompt resolution for bucket balance writes

### Auth Layer
- Firebase Auth for parents (email/password)
- bcrypt PIN auth for children (4-6 digits)
- PinAttemptTracker: 5 failures -> 15min lockout (FlutterSecureStorage)
- 24h child sessions stored locally + in Firestore

### Cloud Functions
- createFamily, addFundsToChild, multiplyBucket, distributeFunds (TypeScript in /functions)

---

## Developer Setup

### 1. Install Flutter Dependencies

```bash
flutter pub get
```

DO NOT run build_runner. The project does NOT use Freezed, riverpod_generator, or hive_generator.
These are incompatible with Flutter 3.41.6 + Dart 3.11.4. All code generation artifacts are
hand-written.

If you see advice to run:
  flutter pub run build_runner build --delete-conflicting-outputs
...IGNORE IT for this project.

### 2. Hive Setup (Manual TypeAdapter)

Hive is used for the offline queue. The TypeAdapter for PendingOperation is hand-written in:
  lib/core/offline/pending_operation.dart

The adapter is registered in:
  lib/core/offline/hive_setup.dart

initHive() is called in lib/main.dart before runApp(). No further action needed.

DO NOT add hive_generator or build_runner to dev_dependencies -- this breaks the project.

### 3. Firebase Emulator Setup

The firebase.json already has the emulator block configured:

| Service   | Port |
|-----------|------|
| Firestore | 8080 |
| Auth      | 9099 |
| Functions | 5001 |
| UI        | 4000 |

To start the emulator and seed test data (Windows):
```powershell
.\scripts\seed_emulator.ps1
```

To start the emulator (Linux/macOS):
```bash
./scripts/seed_emulator.sh
```

To connect the Flutter app to the emulator, call setupFirebaseEmulator() in your test setup:
```dart
// integration_test/test_helpers/firebase_test_setup.dart
await setupFirebaseEmulator();
```

### 4. Firebase Production Setup

If setting up from scratch (not using emulator):
1. Run: flutterfire configure
   This generates lib/firebase_options.dart (already in .gitignore)
   Use lib/firebase_options.dart.example as a reference template
2. Deploy rules: firebase deploy --only firestore:rules
3. Deploy functions: cd functions && npm install && firebase deploy --only functions

### 5. Firestore Composite Index

Create this index in Firebase Console -> Firestore -> Indexes:

Collection: families/{familyId}/transactions
Fields:
  - childId (Ascending)
  - performedAt (Descending)

This enables per-child transaction history queries. Without it, those queries will fail.

### 6. Verify Dependencies in pubspec.yaml

Required packages (already added):
- flutter_riverpod
- cloud_firestore
- firebase_auth
- flutter_secure_storage
- bcrypt
- connectivity_plus: ^6.0.0
- hive: ^2.2.3
- hive_flutter: ^1.1.0
- equatable

Dev dependencies (already added):
- integration_test (from Flutter SDK)

NOT required (do not add):
- build_runner
- freezed / freezed_annotation
- riverpod_generator / riverpod_annotation
- hive_generator
- json_serializable / json_annotation

---

## Usage Examples

### Watch a child's buckets (real-time)
```dart
final bucketsAsync = ref.watch(childBucketsProvider(
  (childId: childId, familyId: familyId),
));

bucketsAsync.when(
  data: (buckets) => /* Show buckets */,
  loading: () => /* Loading indicator */,
  error: (error, _) => /* Error message */,
);
```

### Distribute funds across buckets
```dart
await ref.read(bucketRepositoryProvider).distributeFunds(
  familyId: familyId,
  childId: childId,
  moneyAmount: 10.0,
  investmentAmount: 5.0,
  charityAmount: 5.0,
  performedByUid: currentUser.uid,
  note: 'Weekly allowance',
);
```

### Multiply investment
```dart
await ref.read(bucketRepositoryProvider).multiplyInvestment(
  childId: childId,
  familyId: familyId,
  multiplier: 2.0,
  performedByUid: currentUser.uid,
  note: 'Great job saving!',
);
// Throws ArgumentError if multiplier <= 0
```

### Archive a child (soft delete)
```dart
await ref.read(childRepositoryProvider).archiveChild(
  familyId: familyId,
  childId: childId,
);
// Child now has archived: true; filtered from childrenProvider automatically
```

---

## Troubleshooting

### Compilation Errors
If you see errors about missing .freezed.dart or .g.dart files:
1. These should NOT exist in this project
2. Delete any .freezed.dart or .g.dart files if found
3. Run: flutter clean && flutter pub get

### Firestore Timestamp Errors
If you see: "type 'String' is not a subtype of type 'Timestamp' in type cast"
- A repository is writing DateTime as ISO string instead of Timestamp.fromDate()
- Find the write and change: DateTime.now().toIso8601String()
  to: Timestamp.fromDate(DateTime.now())
- The fromJson methods have a dual-type guard but the bug is on the write side

### Hive Errors
If you see HiveError about unregistered adapter:
1. Confirm initHive() is called in main.dart before runApp()
2. Confirm PendingOperationAdapter is registered in hive_setup.dart
3. Do NOT add any hive_generator annotations or run build_runner

### Offline Queue Not Syncing
1. Check ConnectivityService is injected into BucketRepository and ChildRepository
2. Confirm autoSyncProvider is being watched in the app
3. Check SyncEngine is initialized via syncEngineProvider

### Firestore Permission Errors
1. Check security rules allow the operation (firestore.rules)
2. Verify user is authenticated (Firebase Auth for parents, PIN session for children)
3. Verify familyId/childId are correct
4. Use the emulator with its UI (port 4000) to inspect data

---

## Documentation Map

- Firestore schema: FIRESTORE_DATA_MODEL.md
- Architecture: docs/architecture.md
- Sprint decisions: .squad/agents/jarvis/history.md
- Security posture: AUTH_SECURITY_PHASE1_COMPLETE.md
