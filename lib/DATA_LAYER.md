# KidsFinance Data Layer

## Overview

This document describes the complete data layer implementation for KidsFinance, including domain models, repositories, and Riverpod providers.

## Architecture

```
┌─────────────────────────────────────────────┐
│           PRESENTATION LAYER                 │
│    (Widgets consume providers via ref)       │
└────────────────────┬────────────────────────┘
                     │ ref.watch()
┌────────────────────▼────────────────────────┐
│            PROVIDERS LAYER                   │
│  (Riverpod providers expose streams/state)   │
└────────────────────┬────────────────────────┘
                     │ repository calls
┌────────────────────▼────────────────────────┐
│          REPOSITORY LAYER                    │
│   (Abstract interfaces + Firebase impls)     │
└────────────────────┬────────────────────────┘
                     │ Firestore SDK
┌────────────────────▼────────────────────────┐
│              FIREBASE                        │
│        (Firestore, Auth, Functions)          │
└─────────────────────────────────────────────┘
```

## Domain Models

All models use `freezed` for immutability and JSON serialization.

### Family (`lib/features/family/domain/family.dart`)
```dart
Family(
  id: String,
  name: String,
  parentIds: List<String>,
  childIds: List<String>,
  createdAt: DateTime,
  schemaVersion: String,
)
```

### ParentUser (`lib/features/family/domain/parent_user.dart`)
```dart
ParentUser(
  uid: String,
  displayName: String,
  familyId: String,
  isOwner: bool,
  createdAt: DateTime,
)
```

### Child (`lib/features/children/domain/child.dart`)
```dart
Child(
  id: String,
  familyId: String,
  displayName: String,
  avatarEmoji: String,
  pinHash: String,
  sessionExpiresAt: DateTime?,
  createdAt: DateTime,
)
```

### Bucket (`lib/features/buckets/domain/bucket.dart`)
```dart
enum BucketType { money, investment, charity }

Bucket(
  id: String,
  childId: String,
  familyId: String,
  type: BucketType,
  balance: double,
  lastUpdatedAt: DateTime,
)
```

### Transaction (`lib/features/transactions/domain/transaction.dart`)
```dart
enum TransactionType {
  moneySet,
  investmentMultiplied,
  charityDonated,
  moneyAdded,
  moneyRemoved,
}

Transaction(
  id: String,
  familyId: String,
  childId: String,
  bucketType: BucketType,
  type: TransactionType,
  amount: double,
  multiplier: double?,
  previousBalance: double,
  newBalance: double,
  note: String?,
  performedByUid: String,
  performedAt: DateTime,
)
```

## Firestore Structure

```
/families/{familyId}
  - name, parentIds[], childIds[], createdAt, schemaVersion
  
  /children/{childId}
    - displayName, avatarEmoji, pinHash, sessionExpiresAt, createdAt
    
    /buckets/{bucketType}  // 'money', 'investment', 'charity'
      - childId, familyId, type, balance, lastUpdatedAt
  
  /transactions/{txnId}
    - childId, bucketType, type, amount, multiplier,
      previousBalance, newBalance, note, performedByUid, performedAt
  
  /archivedTransactions/{txnId}
    - (same schema as transactions, for archived records)

/userProfiles/{uid}
  - uid, displayName, familyId, isOwner, createdAt
```

## Repositories

### FamilyRepository
- `getFamilyStream(familyId)` → Stream<Family?>
- `createFamily(name, parentUid, parentDisplayName)` → Future<Family>
- `addParent(familyId, parentUid, parentDisplayName, isOwner)` → Future<void>
- `addChild(familyId, displayName, avatarEmoji, pinHash)` → Future<Child>

### ChildRepository
- `getChildStream(childId, familyId)` → Stream<Child?>
- `updateChild(childId, familyId, displayName?, avatarEmoji?)` → Future<void>
- `updatePinHash(childId, familyId, newPinHash)` → Future<void>
- `updateSessionExpiry(childId, familyId, expiresAt)` → Future<void>

### BucketRepository
- `getBucketsStream(childId, familyId)` → Stream<List<Bucket>>
- `setMoneyBalance(childId, familyId, newBalance, performedByUid, note?)` → Future<void>
- `multiplyInvestment(childId, familyId, multiplier, performedByUid, note?)` → Future<void>
  - **Throws ArgumentError if multiplier ≤ 0**
- `donateCharity(childId, familyId, performedByUid, note?)` → Future<void>
- `addMoney(childId, familyId, amount, performedByUid, note?)` → Future<void>
- `removeMoney(childId, familyId, amount, performedByUid, note?)` → Future<void>

### TransactionRepository
- `getTransactionsStream(childId, familyId, limit?)` → Stream<List<Transaction>>
- `logTransaction(transaction)` → Future<void>
- `archiveOldTransactions(familyId, cutoffDate)` → Future<void>

## Riverpod Providers

### Family Providers (`lib/features/family/providers/`)
```dart
// Repository
@riverpod FamilyRepository familyRepository(...)

// Stream providers
@riverpod Stream<Family?> family(FamilyRef ref, String familyId)
@riverpod Stream<ParentUser?> currentUserProfile(CurrentUserProfileRef ref, String uid)
```

### Children Providers (`lib/features/children/providers/`)
```dart
// Repository
@riverpod ChildRepository childRepository(...)

// Stream providers
@riverpod Stream<List<Child>> children(ChildrenRef ref, String familyId)
@riverpod Stream<Child?> child(ChildRef ref, String childId, String familyId)

// State provider
@riverpod class SelectedChild extends _$SelectedChild {
  String? build() => null;
  void select(String? childId);
  void clear();
}
```

### Buckets Providers (`lib/features/buckets/providers/`)
```dart
// Repository
@riverpod BucketRepository bucketRepository(...)

// Stream providers
@riverpod Stream<List<Bucket>> childBuckets(
  ChildBucketsRef ref, {
  required String childId,
  required String familyId,
})

// Computed providers
@riverpod double totalWealth(TotalWealthRef ref, {
  required String childId,
  required String familyId,
})

@riverpod Bucket? bucketByType(BucketByTypeRef ref, {
  required String childId,
  required String familyId,
  required BucketType type,
})
```

### Transaction Providers (`lib/features/transactions/providers/`)
```dart
// Repository
@riverpod TransactionRepository transactionRepository(...)

// Stream providers
@riverpod Stream<List<Transaction>> transactionHistory(
  TransactionHistoryRef ref, {
  required String childId,
  required String familyId,
})

@riverpod Stream<List<Transaction>> recentTransactions(
  RecentTransactionsRef ref, {
  required String childId,
  required String familyId,
})

@riverpod Stream<List<Transaction>> transactionsByType(
  TransactionsByTypeRef ref, {
  required String childId,
  required String familyId,
  required TransactionType type,
})
```

## Usage Examples

### Create a Family
```dart
final repository = ref.read(familyRepositoryProvider);
final family = await repository.createFamily(
  name: 'Smith Family',
  parentUid: currentUser.uid,
  parentDisplayName: currentUser.displayName,
);
```

### Add a Child
```dart
final repository = ref.read(familyRepositoryProvider);
final child = await repository.addChild(
  familyId: familyId,
  displayName: 'Emma',
  avatarEmoji: '🌟',
  pinHash: hashedPin,
);
```

### Watch Child's Buckets
```dart
final bucketsAsync = ref.watch(childBucketsProvider(
  childId: childId,
  familyId: familyId,
));

bucketsAsync.when(
  data: (buckets) => ListView.builder(...),
  loading: () => CircularProgressIndicator(),
  error: (error, stack) => Text('Error: $error'),
);
```

### Multiply Investment
```dart
final repository = ref.read(bucketRepositoryProvider);
await repository.multiplyInvestment(
  childId: childId,
  familyId: familyId,
  multiplier: 2.0,  // Must be > 0
  performedByUid: currentUser.uid,
  note: 'Great job saving!',
);
```

### Donate Charity
```dart
final repository = ref.read(bucketRepositoryProvider);
await repository.donateCharity(
  childId: childId,
  familyId: familyId,
  performedByUid: currentUser.uid,
  note: 'Donated to local animal shelter',
);
```

## Key Implementation Details

### Atomic Transactions
All bucket mutations use Firestore transactions to ensure atomicity:
```dart
await _firestore.runTransaction((transaction) async {
  // 1. Read current balance
  // 2. Calculate new balance
  // 3. Update bucket
  // 4. Log transaction
});
```

### Validation
- Investment multiplier must be > 0 (throws `ArgumentError`)
- Money amounts must be non-negative
- Remove money checks for sufficient balance

### Transaction Logging
Every bucket mutation creates an immutable transaction log with:
- Previous and new balance
- Amount changed
- Who performed the action
- When it was performed
- Optional note

### Batch Writes
Multi-document creates use batches for atomicity:
```dart
final batch = _firestore.batch();
batch.set(familyRef, familyData);
batch.set(userProfileRef, parentData);
await batch.commit();
```

## Required Firestore Index

Create this composite index in Firebase Console:

```
Collection: families/{familyId}/transactions
Fields:
  - childId (Ascending)
  - performedAt (Descending)
```

## Code Generation

After creating or modifying models/providers, run:

```bash
dart run build_runner build --delete-conflicting-outputs
```

This generates:
- `*.freezed.dart` files for Freezed models
- `*.g.dart` files for JSON serialization
- `*_providers.g.dart` files for Riverpod providers

## Testing

All repositories and providers should be unit tested:

```dart
// Mock repository in tests
final container = ProviderContainer(
  overrides: [
    bucketRepositoryProvider.overrideWith(
      (ref) => MockBucketRepository(),
    ),
  ],
);
```

## Next Steps

1. Run code generation
2. Write unit tests for repositories
3. Implement Firestore security rules
4. Create UI screens that consume providers
5. Add error handling and retry logic
6. Implement offline conflict resolution
