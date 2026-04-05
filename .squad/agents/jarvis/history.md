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

