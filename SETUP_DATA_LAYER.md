# Data Layer Setup Guide

## What Was Implemented

JARVIS has completed the Phase 1 data layer implementation:

✅ **Domain Models** (5 files)
- Family, ParentUser, Child, Bucket, Transaction
- All use Freezed for immutability + JSON serialization

✅ **Repository Interfaces** (4 files)
- FamilyRepository, ChildRepository, BucketRepository, TransactionRepository
- Abstract interfaces defining all data operations

✅ **Firebase Implementations** (4 files)
- Complete Firestore implementations for all repositories
- Atomic transactions for bucket mutations
- Batch writes for multi-document creates

✅ **Riverpod Providers** (4 files)
- Family, Children, Buckets, Transaction providers
- Stream providers for real-time data
- Computed providers for derived state

## Next Steps

### 1. Code Generation (REQUIRED)

The code **will not compile** until you run code generation. Run this command:

```bash
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
```

This generates:
- `*.freezed.dart` — Freezed model implementations
- `*.g.dart` — JSON serialization code
- `*_providers.g.dart` — Riverpod provider implementations

### 2. Create Firestore Index

In Firebase Console > Firestore > Indexes, create:

**Collection:** `families/{familyId}/transactions`  
**Fields:**
- `childId` (Ascending)
- `performedAt` (Descending)

This enables efficient transaction queries by child.

### 3. Verify Dependencies

All required packages are already in `pubspec.yaml`:
- ✅ flutter_riverpod
- ✅ riverpod_annotation
- ✅ cloud_firestore
- ✅ freezed_annotation
- ✅ json_annotation
- ✅ build_runner (dev)
- ✅ freezed (dev)
- ✅ json_serializable (dev)
- ✅ riverpod_generator (dev)

### 4. Security Rules (Fury's Domain)

Update `firestore.rules` to match the new collection structure:

```
/families/{familyId}
/families/{familyId}/children/{childId}
/families/{familyId}/children/{childId}/buckets/{bucketType}
/families/{familyId}/transactions/{txnId}
/userProfiles/{uid}
```

### 5. UI Integration (Rhodey/Pepper's Domain)

Use the providers in your screens:

```dart
// Watch child's buckets
final bucketsAsync = ref.watch(childBucketsProvider(
  childId: childId,
  familyId: familyId,
));

bucketsAsync.when(
  data: (buckets) => /* Show buckets */,
  loading: () => /* Loading indicator */,
  error: (error, _) => /* Error message */,
);

// Multiply investment
await ref.read(bucketRepositoryProvider).multiplyInvestment(
  childId: childId,
  familyId: familyId,
  multiplier: 2.0,
  performedByUid: currentUser.uid,
  note: 'Well done!',
);
```

### 6. Testing (Happy's Domain)

Write unit tests for repositories and providers:

```dart
test('multiplyInvestment rejects zero multiplier', () async {
  final repository = FirebaseBucketRepository(
    firestore: FakeFirebaseFirestore(),
  );
  
  expect(
    () => repository.multiplyInvestment(
      childId: 'child1',
      familyId: 'family1',
      multiplier: 0.0,  // Invalid!
      performedByUid: 'parent1',
    ),
    throwsArgumentError,
  );
});
```

## Troubleshooting

### Build Errors After Code Generation

If you see errors like "The getter 'toJson' isn't defined":
1. Make sure you ran `build_runner`
2. Check that `part` directives are correct in model files
3. Clean and rebuild: `flutter clean && flutter pub get`

### Import Errors

If imports show red:
1. Ensure all dependencies are in `pubspec.yaml`
2. Run `flutter pub get`
3. Restart your IDE

### Firestore Permission Errors

If writes fail in the app:
1. Check security rules allow the operation
2. Verify user is authenticated
3. Check familyId/childId are correct

## Key Implementation Notes

### Investment Multiplier Validation
- **MUST be > 0** (throws ArgumentError otherwise)
- This is a HARD requirement per team decision

### Transaction Immutability
- All transactions are IMMUTABLE
- Create new transaction, never update existing
- Archive old transactions with `archiveOldTransactions()`

### Atomic Operations
- All bucket mutations use Firestore transactions
- Bucket update + transaction log are atomic
- No partial updates possible

### Offline Support
- Firestore SDK handles offline persistence automatically
- Writes queue locally, sync when online
- Conflicts use last-write-wins (may need user prompt later)

## Documentation

- **Full Data Layer Docs:** `lib/DATA_LAYER.md`
- **Architecture:** `docs/architecture.md`
- **Firestore Model:** `FIRESTORE_DATA_MODEL.md`
- **Implementation Decisions:** `.squad/decisions/inbox/jarvis-phase1.md`
- **JARVIS History:** `.squad/agents/jarvis/history.md`

## Questions?

- Architecture/pattern questions → Stark
- Security/auth questions → Fury
- UI integration questions → Rhodey/Pepper
- Testing questions → Happy
- Backend/Firestore questions → JARVIS

---

**Status:** ✅ Phase 1 complete, pending code generation
**Next Phase:** UI integration + security rules
