# Data Layer Implementation Manifest

**Implemented by:** JARVIS (Backend Dev)
**Date:** 2026-04-08 (updated Sprints 5A-5D)
**Status:** Complete

---

## Files Created / Modified

### Domain Models (6 files)

```
lib/features/family/domain/
  family.dart              - Family entity (plain Dart + Equatable, no Freezed)
  parent_user.dart         - ParentUser entity

lib/features/children/domain/
  child.dart               - Child entity (includes archived, sessionExpiresAt)

lib/features/buckets/domain/
  bucket.dart              - Bucket entity + BucketType enum (money/investment/charity)

lib/features/transactions/domain/
  transaction.dart         - Transaction entity + TransactionType enum

lib/features/auth/domain/
  app_user.dart            - AppUser entity + AppUserRole enum
```

NOTE: No Freezed, no code generation. Flutter 3.41.6 + Dart 3.11.4 is incompatible with
build_runner/freezed/riverpod_generator. All models use plain immutable Dart classes with
manual copyWith, fromJson, and toJson.

### Repository Interfaces (4 files)

```
lib/features/family/domain/
  family_repository.dart       - Abstract FamilyRepository

lib/features/children/domain/
  child_repository.dart        - Abstract ChildRepository
                                 Methods: getChildStream, updateChild, updatePinHash,
                                          updateSessionExpiry, archiveChild

lib/features/buckets/domain/
  bucket_repository.dart       - Abstract BucketRepository
                                 Methods: getBucketsStream, setMoneyBalance, multiplyInvestment,
                                          donateCharity, addMoney, removeMoney, distributeFunds

lib/features/transactions/domain/
  transaction_repository.dart  - Abstract TransactionRepository
```

### Firebase Implementations (4 files)

```
lib/features/family/data/
  firebase_family_repository.dart      - Firestore implementation

lib/features/children/data/
  firebase_child_repository.dart       - Firestore implementation
                                         Offline-aware: updateChild + archiveChild queue when offline
                                         PIN hashed with BCrypt before storing in offline queue

lib/features/buckets/data/
  firebase_bucket_repository.dart      - Firestore implementation
                                         Offline-aware: checks connectivity, enqueues when offline
                                         distributeFunds uses single runTransaction (atomic)

lib/features/transactions/data/
  firebase_transaction_repository.dart - Firestore implementation
```

### Riverpod Providers (5 files)

```
lib/features/family/providers/
  family_providers.dart         - family, currentUserProfile providers

lib/features/children/providers/
  children_providers.dart       - children (filters archived), child, selectedChild providers

lib/features/buckets/providers/
  buckets_providers.dart        - childBuckets, totalWealth, bucketByType providers
                                  Injects ConnectivityService + OfflineQueue

lib/features/transactions/providers/
  transaction_providers.dart    - transactionHistory, recentTransactions providers

lib/features/auth/providers/
  auth_providers.dart           - authState, currentFamilyId, appUserRole, activeChild,
                                  isChildSessionValid providers
  session_provider.dart         - child session state
```

All providers use standard Riverpod 2.x API (Provider, StreamProvider, StreamProvider.family,
Notifier, NotifierProvider). No @riverpod codegen annotation.

### Offline Layer (8 files)

```
lib/core/offline/
  pending_operation.dart     - HiveObject + MANUAL TypeAdapter (typeId: 0)
                               DO NOT use hive_generator - incompatible with Flutter 3.41.6
  hive_setup.dart            - initHive() - called in main() before runApp
  offline_queue.dart         - enqueue / dequeue / purgeExpired (24h TTL, warn at 23h)
  connectivity_service.dart  - wraps connectivity_plus 6.x (List<ConnectivityResult>)
  connectivity_provider.dart - connectivityServiceProvider, isOnlineProvider
  conflict.dart              - BucketConflict model, ConflictResolution enum
  sync_engine.dart           - processes queue on reconnect, detects conflicts,
                               resolves via repository calls
  sync_providers.dart        - offlineQueueProvider, syncEngineProvider,
                               pendingOperationsProvider, pendingConflictsProvider,
                               autoSyncProvider
```

### Auth Services (3 files)

```
lib/features/auth/data/
  auth_service.dart          - Firebase Auth (email/password); createFamily
  pin_service.dart           - bcrypt PIN hash/verify; 24h sessions; lockout tracking
  pin_attempt_tracker.dart   - FlutterSecureStorage-backed lockout (5 failures -> 15min)
```

### Firebase / Emulator Config

```
firebase.json              - emulators: Firestore 8080, Auth 9099, Functions 5001, UI 4000
firestore.rules            - Production security rules
firestore.indexes.json     - Composite index: childId + performedAt

integration_test/test_helpers/
  firebase_test_setup.dart   - setupFirebaseEmulator() for integration tests
  test_data.dart             - createTestFamily, createTestChild, createTestBuckets, cleanupTestData

scripts/
  seed_emulator.ps1          - Windows: starts emulator, prints test credentials
  seed_emulator.sh           - Linux/macOS: same
```

---

## Key Implementation Decisions

1. No code generation - build_runner incompatible; all models and providers hand-written
2. Timestamps - always Timestamp.fromDate(dt), never .toIso8601String() (caused production crash)
3. Soft delete only - children use archived: true; buckets/transactions cannot be deleted
4. Offline queue TTL - 24h purge, 23h warning
5. Conflict scope - only bucket balance writes; child metadata ops are last-write-wins
6. Conflict resolution - USER PROMPT (useLocal / useServer); never silent overwrite
7. Investment multiplier - must be > 0 (throws ArgumentError at repo + Cloud Function)
8. Charity donation - always resets to exactly 0 (all-or-nothing)
9. distributeFunds - each amount >= 0, total > 0; atomic single runTransaction
10. Family membership - verified via Firestore parentIds array, NOT JWT claims (JWT spoofing fix)
11. PIN hashing - BCrypt in Dart; hash stored in Firestore, PIN never persisted
12. Session duration - 24h (not 30 days; shortened in Sprint 5C security hardening)
13. Hive TypeAdapter - hand-written PendingOperationAdapter (typeId: 0); DO NOT run hive_generator

---

## Firestore Collection Paths (actual, as implemented)

```
/families/{familyId}
  /children/{childId}
    /buckets/{bucketType}     <- money | investment | charity
  /transactions/{txnId}       <- family-level, filtered by childId field
```

NOTE: Transactions live at the FAMILY level, not under the child.
They are queried with .where('childId', isEqualTo: childId).

---

## Validation Checklist

- [x] Models compile without build_runner
- [x] flutter analyze = 0 errors
- [x] Timestamps use Timestamp.fromDate() everywhere
- [x] fromJson uses dual-type guard (Timestamp | String) for backward compat
- [x] childrenProvider filters .where((c) => !c.archived)
- [x] distributeFunds validates total > 0
- [x] multiplyInvestment rejects multiplier <= 0
- [x] Hive TypeAdapter is manual (no hive_generator in pubspec.yaml)
- [x] Offline queue integrated into bucket + child repositories
- [x] Firebase emulator config in firebase.json

---

See .squad/agents/jarvis/history.md for sprint-by-sprint decisions.
