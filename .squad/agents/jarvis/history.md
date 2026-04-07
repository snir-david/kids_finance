# JARVIS Backend Dev - Work History

## 2024-04-05: Removed Code Generation Dependencies

**Context:** Flutter 3.41.6 (Dart 3.11.4) has analyzer 7.6.0 incompatible with build_runner/freezed/riverpod_generator.

**Work Completed:**

### 1. Replaced All Freezed Models with Plain Dart + Equatable
Rewrote all domain models as plain immutable classes:
- `lib/features/family/domain/family.dart` - Family model
- `lib/features/family/domain/parent_user.dart` - ParentUser model
- `lib/features/children/domain/child.dart` - Child model
- `lib/features/buckets/domain/bucket.dart` - Bucket model with BucketType enum
- `lib/features/transactions/domain/transaction.dart` - Transaction model with TransactionType enum
- `lib/features/auth/domain/app_user.dart` - AppUser model with AppUserRole enum

Each model now includes:
- Manual `copyWith` methods
- `fromJson` and `toJson` for Firestore serialization
- Equatable for value equality
- Proper Timestamp handling for DateTime fields
- Custom enum serialization

### 2. Replaced All @riverpod Providers with Standard Riverpod API
Rewrote all provider files to use standard Riverpod 2.6.1:
- `lib/features/family/providers/family_providers.dart` - Provider, StreamProvider.family
- `lib/features/children/providers/children_providers.dart` - StreamProvider.family, StateProvider
- `lib/features/buckets/providers/buckets_providers.dart` - StreamProvider.family, Provider.family
- `lib/features/transactions/providers/transaction_providers.dart` - StreamProvider.family with aliased imports
- `lib/features/auth/providers/auth_providers.dart` - StreamProvider, Provider, StateProvider

Used named parameter records (e.g., `({String childId, String familyId})`) for multi-parameter family providers.

### 3. Fixed Import Conflicts
- Aliased `Transaction` import as `app_transaction` in:
  - `firebase_bucket_repository.dart`
  - `firebase_transaction_repository.dart`
  - `transaction_providers.dart`
- Aliased `Family` import as `domain` in `family_providers.dart`
- Removed unused imports from repository interfaces

### 4. Updated Routing
Rewrote `lib/routing/app_router.dart` to use standard Provider instead of @riverpod.

### 5. Cleanup
- Deleted `.dart_tool/build/` cache
- Confirmed no `.freezed.dart` or `.g.dart` files exist
- Ran `flutter analyze` - all codegen-related errors resolved

**Remaining Errors (unrelated to this task):**
- Missing packages: `google_sign_in`, `bcrypt` (not in pubspec.yaml)
- Theme API issues with CardTheme (pre-existing)

**Result:** The data layer is now fully compatible with Flutter 3.41.6 without any code generation dependencies.

## Learnings

### 2024-04-06: Firestore Timestamp Deserialization Bug (critical)

**Bug:** After adding a child, buckets failed to load with:
`type 'String' is not a subtype of type 'Timestamp' in type cast`

**Root cause — write side:** Three repository files wrote DateTime as ISO 8601 strings to Firestore instead of `Timestamp` objects:
- `firebase_family_repository.dart` — bucket init `lastUpdatedAt`
- `firebase_bucket_repository.dart` — `lastUpdatedAt` in all 5 balance operations
- `firebase_child_repository.dart` — `sessionExpiresAt` in `updateSessionExpiry`

**Root cause — read side:** `Bucket.fromJson` and `Child.fromJson` did an unsafe `as Timestamp` cast, crashing on any field stored as a String.

**Fix applied:**
1. All writes now use `Timestamp.fromDate(dateTime)` instead of `.toIso8601String()`
2. All `fromJson` methods now use a safe dual-type pattern:
   ```dart
   final raw = json['field'];
   final dt = raw is Timestamp ? raw.toDate() : DateTime.parse(raw as String);
   ```
   This ensures backward compatibility with any existing bad data already in Firestore.

**Files changed:** `firebase_family_repository.dart`, `firebase_bucket_repository.dart`, `firebase_child_repository.dart`, `bucket.dart`, `child.dart`

## 2026-04-07: Sprint 5A Backend — CRUD & Distribution

**Status:** ✅ COMPLETE

**Deliverables:**

### 1. distributeFunds — Allowance Split
Atomically distributes allowance across Money/Investment/Charity buckets in one Firestore transaction.
- **Files:** `transaction.dart` (added `distributed` to enum), `bucket_repository.dart`, `firebase_bucket_repository.dart`, `child_home_screen.dart`, `transaction_history_screen.dart`
- **Validation:** Each amount ≥ 0; total > 0 (all-zero throws ArgumentError)
- **Timestamp:** Uses `Timestamp.fromDate(DateTime.now())`
- **Atomic:** Single runTransaction ensures all-or-nothing

### 2. updateChild — Edit Child
Updates child name, avatar, and/or PIN with optional field handling.
- **Files:** `child_repository.dart`, `firebase_child_repository.dart`
- **Signature:** `updateChild(childId, {String? name, String? avatar, String? newPin})`
- **PIN Handling:** Hashed with BCrypt before write (not plaintext)
- **Mapping:** Domain `name` → Firestore `displayName`
- **Validation:** Only non-null fields written to Firestore

### 3. archiveChild — Soft Delete
Sets `archived: true` on Firestore child document. No data deleted.
- **Files:** `child.dart` (added `archived` field), `child_repository.dart`, `firebase_child_repository.dart`, `children_providers.dart`
- **Filtering:** `childrenProvider` now filters `.where((c) => !c.archived)`
- **Data Preservation:** All child data intact, just marked archived
- **Parent-Only:** Only parent accounts can call this method

**Code Quality:** flutter analyze = **0 errors** ✅

**Architecture Compliance:**
- ✅ Timestamp: `Timestamp.fromDate(DateTime.now())`
- ✅ Soft delete pattern enforced (no hard deletes)
- ✅ Parent-only operations
- ✅ Multiply-by-zero guard: distributeFunds requires total > 0
- ✅ BCrypt hashing for sensitive PIN data

**Rule:** Never use `.toIso8601String()` for Firestore timestamp fields. Always use `Timestamp.fromDate(dt)` or `FieldValue.serverTimestamp()`.

## Sprint 5B — 2026-04-07: Offline Sync Queue

**Status:** ✅ COMPLETE

### Decisions Locked
- Offline queue TTL: 24 hours (purge on next sync)
- Conflict resolution: USER PROMPT for bucket balance writes only
- Conflict scope: BUCKET BALANCES ONLY (`amount`/`balance` field on bucket docs)
- Operation types with conflict detection: setMoney, distribute, multiply, donate
- Operation types last-write-wins: addMoney, removeMoney, updateChild, archiveChild
- Child auth: PIN only
- Hive TypeAdapters written manually (no build_runner — incompatible with Flutter 3.41.6 + Riverpod 3)
- Riverpod 3.x: `Notifier` + `NotifierProvider` instead of `StateNotifier`/`StateProvider`
- `hive_generator` + `build_runner` removed from dev_dependencies (conflict with mockito + flutter_riverpod 3.x)

### Files Created
- `lib/core/offline/pending_operation.dart` — HiveObject + manual TypeAdapter (typeId: 0)
- `lib/core/offline/hive_setup.dart` — `initHive()` called in main()
- `lib/core/offline/offline_queue.dart` — enqueue/dequeue/purge with 24h TTL
- `lib/core/offline/connectivity_service.dart` — wraps connectivity_plus 6.x (List<ConnectivityResult>)
- `lib/core/offline/connectivity_provider.dart` — `connectivityServiceProvider`, `connectivityProvider`, `isOnlineProvider`
- `lib/core/offline/conflict.dart` — `BucketConflict`, `ConflictResolution` enum
- `lib/core/offline/sync_engine.dart` — processes queue, detects conflicts, resolves via repo calls
- `lib/core/offline/sync_providers.dart` — `offlineQueueProvider`, `syncEngineProvider`, `pendingOperationsProvider`, `pendingConflictsProvider`, `autoSyncProvider`

### Files Modified
- `pubspec.yaml` — added connectivity_plus ^6.0.0, hive ^2.2.3, hive_flutter ^1.1.0
- `lib/main.dart` — added `await initHive()` before `runApp`
- `lib/features/buckets/domain/bucket_repository.dart` — added optional `baseValue` params to all write methods; `distributeFunds` gets `baseValueMoney/Investment/Charity`
- `lib/features/buckets/data/firebase_bucket_repository.dart` — offline-aware: checks connectivity, enqueues ops when offline
- `lib/features/buckets/providers/buckets_providers.dart` — injects ConnectivityService + OfflineQueue
- `lib/features/children/data/firebase_child_repository.dart` — offline-aware: updateChild + archiveChild queue when offline; PIN hashed before storing in queue
- `lib/features/children/providers/children_providers.dart` — injects ConnectivityService + OfflineQueue

**Code Quality:** flutter analyze = **0 errors** ✅

## Sprint 5C — 2026-04-07: Security Hardening

**Status:** ✅ COMPLETE

### JARVIS — Cloud Functions Integration
**Note:** JARVIS did not work on this sprint (Cloud Functions authored by Fury).

**Cloud Functions Changes (by Fury, for JARVIS awareness):**
- `functions/src/index.ts` — All callable functions (`onMultiplyInvestment`, `onDonateCharity`, `onSetMoney`) now verify family membership via Firestore `families/{familyId}.parentIds` array instead of trusting JWT `familyId` claim
- `assertFamilyMembership(uid, familyId)` replaces JWT-based family check — throws `PERMISSION_DENIED` unless uid explicitly in parentIds array
- All numeric inputs validated: `typeof x !== 'number' || !isFinite(x)` check prevents Infinity/NaN/string attacks
- Role claim validation: `onSetCustomClaims` enforces allowlist (`validRoles = ['parent']`)
- Charity bucket precondition: only execute if `balance > 0`

**Firestore Rules Changes (by Fury, for JARVIS awareness):**
- Added `validBucketCreate()` and `validBucketUpdate()` rule helpers
- `validBucketCreate()` enforces: required fields (balance, childId, familyId, type, lastUpdatedAt), non-empty string IDs, `balance >= 0`
- `validBucketUpdate()` enforces: `balance >= 0` on every update
- Added explicit `allow delete: if false` on children and buckets (soft-delete only)
- Multiplier events: preserved existing `multiplier > 0` validation

**Impact on Data Layer:**
- No repository changes needed (Cloud Functions validate at write-time)
- `PinService._createSession()` now writes `sessionExpiresAt: Timestamp.fromDate(expiry)` to Firestore child document
- Session duration changed: 30 days → 24 hours

