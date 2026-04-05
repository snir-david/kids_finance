## Core Context

## Project Seed

**Project:** KidsFinance
**Description:** Android app (Flutter + Firebase) for kids' financial literacy.
- Three buckets per child: Money 💰, Investments 📈, Charity ❤️
- Parents can multiply investments at will (stored as a transaction event)
- Charity bucket resets to zero when child donates
- Multi-child: each family has 1–N children
- Multi-parent: 2+ parents can manage the same family
- Money can be set freely by parents (any positive amount)
- UI must be simple enough for kids to understand
**Stack:** Flutter (Dart) + Firebase (Firestore, Auth, Cloud Functions)
**Target:** Android (primary); Flutter enables future iOS expansion
**Universe:** Iron Man (Marvel)

## Team
- Stark: Tech Lead
- Rhodey: Mobile Dev
- JARVIS: Backend Dev
- Pepper: UI/UX Designer
- Fury: Security & Auth
- Happy: QA/Tester
- Scribe: Session Logger
- Ralph: Work Monitor

## Learnings

### 2026-04-05: Firestore Data Model Design

**Key Decisions:**
1. **Family-centric hierarchy:** All data lives under `/families/{familyId}` with parents, children, and transactions as subcollections. This simplifies security rules and ensures data locality.

2. **UserProfiles as top-level collection:** Fast O(1) lookup to find which family a user belongs to on login, avoiding costly subcollection queries.

3. **Immutable transaction log:** All state changes (investment multiplications, charity donations, money adjustments, bucket transfers) are recorded as immutable transaction documents. Provides complete audit trail and enables future undo/analytics features.

4. **Real-time sync strategy:**
   - Children buckets: Real-time (critical for parent/child sync)
   - Recent transactions (last 50): Real-time
   - Full transaction history: Paginated one-time fetch
   - Family settings: Real-time
   - Parents list: One-time fetch (rarely changes)

5. **Cloud Functions for mutations:** All bucket modifications go through Cloud Functions, not direct Firestore writes. Ensures atomicity, validation, and security. Functions: `multiplyInvestment`, `donateCharity`, `adjustMoney`, `transferBetweenBuckets`, `createFamily`, `addChild`.

6. **Three bucket design per child:**
   - Money bucket: Freely adjustable by parents (any positive amount)
   - Investment bucket: Tracks total earnings, multiplication events
   - Charity bucket: Resets to 0 on donation, tracks total donated

7. **Multi-parent support:** Multiple parents can be members of a family with granular permissions. `isOwner` flag for family creator.

8. **Stats tracking:** Each child document maintains aggregate stats (total multiplications, donations, money received) for quick UI display without querying transactions.

9. **Composite indexes needed:** 
   - Transactions: `childId (ASC) + timestamp (DESC)` for filtered transaction history

10. **Schema versioning:** Family document includes `schemaVersion` field for future migrations.

**Output:** Created `FIRESTORE_DATA_MODEL.md` with complete collection structure, document schemas, transaction types, Riverpod provider sketch, and Cloud Function specifications.

### 2026-04-05: Phase 1 Data Layer Implementation

**Implementation Completed:**
1. **Domain Models (Freezed + JSON):**
   - `Family` — id, name, parentIds, childIds, createdAt, schemaVersion
   - `ParentUser` — uid, displayName, familyId, isOwner, createdAt
   - `Child` — id, familyId, displayName, avatarEmoji, pinHash, sessionExpiresAt, createdAt
   - `Bucket` — id, childId, familyId, type (enum), balance, lastUpdatedAt
   - `Transaction` — id, familyId, childId, bucketType, type (enum), amount, multiplier, previousBalance, newBalance, note, performedByUid, performedAt

2. **Repository Interfaces:**
   - `FamilyRepository` — getFamilyStream, createFamily, addParent, addChild
   - `ChildRepository` — getChildStream, updateChild, updatePinHash, updateSessionExpiry
   - `BucketRepository` — getBucketsStream, setMoneyBalance, multiplyInvestment (validates >0), donateCharity, addMoney, removeMoney
   - `TransactionRepository` — getTransactionsStream, logTransaction, archiveOldTransactions

3. **Firebase Implementations:**
   - All repositories implemented with Firestore
   - Atomic transactions using `runTransaction()` for bucket mutations
   - Batch writes for multi-document creates (family + user profile, child + buckets)
   - Investment multiplier validation: throws ArgumentError if ≤ 0
   - Transaction archiving to `/archivedTransactions` subcollection

4. **Riverpod Providers:**
   - `familyProvider` — StreamProvider for current family
   - `currentUserProfileProvider` — StreamProvider for parent user
   - `childrenProvider` — StreamProvider for all children in family
   - `selectedChildProvider` — StateProvider for currently viewed child
   - `childBucketsProvider` — StreamProvider for child's buckets
   - `totalWealthProvider` — Computed provider summing all bucket balances
   - `bucketByTypeProvider` — Get specific bucket by type
   - `transactionHistoryProvider` — StreamProvider for all transactions
   - `recentTransactionsProvider` — StreamProvider for last 10 transactions
   - `transactionsByTypeProvider` — Filtered transactions by type

**Firestore Paths Used:**
- `/families/{familyId}` — Family documents
- `/families/{familyId}/children/{childId}` — Child documents
- `/families/{familyId}/children/{childId}/buckets/{bucketType}` — Bucket documents
- `/families/{familyId}/transactions/{txnId}` — Transaction log (all children)
- `/families/{familyId}/archivedTransactions/{txnId}` — Archived transactions
- `/userProfiles/{uid}` — Parent user profiles (top-level for fast lookup)

**Key Implementation Details:**
- Freezed models with `@freezed` annotation and JSON serialization
- All bucket mutations create immutable transaction logs
- Firestore transactions ensure atomic updates (bucket + log)
- Investment multiplier must be > 0 (ArgumentError thrown)
- Charity donation sets balance to 0 and logs amount donated
- Repository pattern enforced: no direct Firestore access from UI
- Riverpod code generation with `@riverpod` annotation
- Real-time streams for buckets, children, and transactions

**Index Requirements:**
- Composite index: `childId (ASC) + performedAt (DESC)` on transactions collection

**Next Steps:**
- Run code generation: `dart run build_runner build --delete-conflicting-outputs`
- Unit tests for repositories and providers
- Firestore security rules
- UI integration with providers

### 2026-04-05: Phase 1 Complete — Data Layer Finalized
- **Status:** ✅ PHASE 1 DATA LAYER FINALIZED
- 22 files / 1,464 lines created: 5 Freezed models, 4 repository interfaces, 4 Firebase implementations, 15+ providers
- Domain models: Family, ParentUser, Child, Bucket, Transaction (all with JSON serialization)
- Repository pattern strictly enforced: FamilyRepository, ChildRepository, BucketRepository, TransactionRepository
- Firestore collection structure finalized with family-centric hierarchy
- Atomic transactions using `runTransaction()` for bucket mutations
- Investment multiplier validation: throws ArgumentError if ≤0
- Immutable transaction log with full audit trail for all mutations
- Real-time streams for buckets, children, transactions
- Code generation ready with @riverpod annotation
- **Orchestration Log:** `.squad/orchestration-log/2026-04-05T18-30-00Z-jarvis-models.md`
- **Next:** Rhodey for UI integration, Fury for security rules, Happy for testing

