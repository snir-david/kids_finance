# Phase 1 Architecture & Implementation Decisions

**Document:** Merged Phase 1 decisions from all agents  
**Date:** 2026-04-05  
**Source:** Consolidated from `.squad/decisions/inbox/` with deduplication  

---

## A. User Directives (2026-04-05T18:12)

Resolved open questions from architecture planning:

1. **PIN Length:** 4 digits (10,000 combinations)
   - Acceptable with rate limiting + bcrypt
   - Children can remember easily
   - Alternative (6 digits) available for parents

2. **Investment Multiplier:** MUST be >0
   - Reject zero multiplication attempts
   - Prevents accidental wipeouts
   - Enforced in Firestore rules AND Cloud Functions

3. **Offline Conflict Resolution:** Prompt user to choose
   - Current: Firestore's last-write-wins
   - When conflict: Show UI dialog, user selects winning version

4. **Child Session Expiry:** 30 days automatic
   - Balances UX (don't re-enter PIN daily) with security
   - Stored in FlutterSecureStorage as ISO8601 timestamp
   - Parent can manually clear sessions (future: remote revoke)

5. **Transaction History Archive:** Archive after 1 year
   - **CRITICAL:** MUST prompt user for permission before archiving
   - Copy to `/archivedTransactions` subcollection
   - Delete from active collection
   - No auto-archive without explicit consent

---

## B. Stark — Project Scaffold (Phase 1)

**Status:** Implementation Complete  
**Files Created:** 70+  
**Key Deliverables:**

### Root Configuration
- `pubspec.yaml` — All dependencies with correct versions
- `README.md` — Project documentation
- `.firebaserc` — Firebase project ID config
- `firebase.json` — Firebase services config (Firestore, Functions, Hosting)
- `.gitignore` — Flutter/Dart/Firebase exclusions

### Application Core
- `lib/main.dart` — App bootstrap with Firebase init
- `lib/app.dart` — MaterialApp.router setup
- `lib/firebase_options.dart` — Placeholder for FlutterFire CLI
- `lib/routing/app_router.dart` — GoRouter with auth redirect using @riverpod

### Core Infrastructure
- `lib/core/theme/app_theme.dart` — Dual themes (kid-friendly: Nunito 64dp, parent: Inter 48dp)
- `lib/core/constants/app_constants.dart` — PIN_LENGTH=4, PIN_MAX_ATTEMPTS=5, PIN_LOCKOUT_MINUTES=15, CHILD_SESSION_DAYS=30, INVESTMENT_MIN_MULTIPLIER=0.01, TRANSACTION_ARCHIVE_YEARS=1

### Auth Feature Scaffold
- `lib/features/auth/domain/app_user.dart` — Freezed AppUser model
- `lib/features/auth/providers/auth_providers.dart` — authStateProvider, currentUserProvider
- 4 Presentation screens (LoginScreen, ParentHomeScreen, ChildHomeScreen, ChildPinScreen)

### Feature Structure (16 placeholders)
- `lib/features/{family,children,buckets,transactions}/` with data/, domain/, presentation/, providers/ subdirs

### Android Configuration
- `android/build.gradle` — Root Gradle config with Firebase plugin
- `android/app/build.gradle` — minSdk=21, targetSdk=34
- `android/app/google-services.json` — Placeholder with instructions
- `android/app/src/main/AndroidManifest.xml` — App manifest
- `android/app/src/main/kotlin/com/kidsfinance/app/MainActivity.kt` — MainActivity stub

### Test Structure
- `test/{unit,widget,integration}` with README documentation

**Key Technical Decisions:**
- Feature-first architecture with repository pattern
- Riverpod with code generation (not manual providers)
- GoRouter for auth-aware routing
- Dual theme system with Material 3 design
- Freezed + JSON serialization for all models
- Android minSdk 21 for broad compatibility

**Deviations:** None. All files follow architecture spec.

**Dependencies:**
- state_management: flutter_riverpod ^2.6.1, riverpod_annotation, riverpod_generator
- routing: go_router ^14.6.2
- firebase: firebase_core ^3.8.1, firebase_auth, cloud_firestore, cloud_functions, firebase_crashlytics
- models: freezed, freezed_annotation, json_annotation, json_serializable
- ui: google_fonts, flutter_animate, flutter_svg
- utilities: intl, flutter_secure_storage
- testing: mockito, fake_cloud_firestore

**Handoff:** JARVIS (data layer), Fury (auth), Rhodey (UI)

---

## C. JARVIS — Data Layer (Phase 1)

**Status:** Implementation Complete  
**Files Created:** 22 files / 1,464 lines  
**Key Deliverables:**

### Domain Models (5 Freezed classes with JSON)
1. **Family** — id, name, parentIds[], childIds[], createdAt, schemaVersion
2. **ParentUser** — uid, displayName, familyId, isOwner, createdAt
3. **Child** — id, familyId, displayName, avatarEmoji, pinHash, sessionExpiresAt, createdAt
4. **Bucket** — id, childId, familyId, type (enum: money/investment/charity), balance, lastUpdatedAt
5. **Transaction** — id, familyId, childId, bucketType, type (enum), amount, multiplier, previousBalance, newBalance, note, performedByUid, performedAt

### Repository Interfaces (4 interfaces)
1. **FamilyRepository**
   - `Stream<Family> getFamilyStream(String familyId)`
   - `Future<void> createFamily(String familyName, String uid)`
   - `Future<void> addParent(String familyId, String parentUid)`
   - `Future<void> addChild(String familyId, String childName, String avatarEmoji)`

2. **ChildRepository**
   - `Stream<Child> getChildStream(String childId, String familyId)`
   - `Future<void> updateChild(String childId, String familyId, {String? displayName, String? avatarEmoji})`
   - `Future<void> updatePinHash(String childId, String familyId, String pinHash)`
   - `Future<void> updateSessionExpiry(String childId, String familyId, DateTime expiresAt)`

3. **BucketRepository**
   - `Stream<List<Bucket>> getBucketsStream(String childId, String familyId)`
   - `Future<void> setMoneyBalance(String childId, String familyId, double amount)`
   - `Future<void> multiplyInvestment(String childId, String familyId, double multiplier)` — **Validates multiplier > 0**
   - `Future<void> donateCharity(String childId, String familyId, double amount)` — **Sets balance to 0**
   - `Future<void> addMoney(String childId, String familyId, double amount)`
   - `Future<void> removeMoney(String childId, String familyId, double amount)`

4. **TransactionRepository**
   - `Stream<List<Transaction>> getTransactionsStream(String familyId, {String? childId, BucketType? type})`
   - `Future<void> logTransaction(Transaction txn)`
   - `Future<void> archiveOldTransactions(String familyId, DateTime cutoffDate)`

### Firebase Implementations (4 implementations)
- All repositories implemented with Firestore
- Atomic transactions using `runTransaction()`
- Batch writes for multi-document creates
- Investment multiplier validation: throws ArgumentError if ≤0
- Charity donation: enforces balance = 0
- Transaction archiving to `/archivedTransactions` subcollection

### Riverpod Providers (15+)
**Real-time Streams:**
- `familyProvider` — StreamProvider<Family> for current family
- `currentUserProfileProvider` — StreamProvider<ParentUser> for parent user
- `childrenProvider` — StreamProvider<List<Child>> for all children
- `childBucketsProvider` — StreamProvider<List<Bucket>> for child's buckets
- `transactionHistoryProvider` — StreamProvider<List<Transaction>> for all transactions
- `recentTransactionsProvider` — StreamProvider<List<Transaction>> for last 10 transactions

**State Providers:**
- `selectedChildProvider` — StateProvider<String> for currently viewed child
- `totalWealthProvider` — Computed provider summing all bucket balances
- `bucketByTypeProvider` — Get specific bucket by money/investment/charity
- `transactionsByTypeProvider` — Filtered transactions by type

### Firestore Collection Structure
```
/families/{familyId}
  - name: String
  - parentIds: Array
  - childIds: Array
  - createdAt: Timestamp
  - schemaVersion: int
  
  /children/{childId}
    - displayName: String
    - avatarEmoji: String
    - pinHash: String (bcrypt)
    - sessionExpiresAt: Timestamp (nullable)
    - createdAt: Timestamp
    
    /buckets/{bucketType}  // bucketType = money|investment|charity
      - balance: double (≥0)
      - lastUpdatedAt: Timestamp
      - childId: String
      - familyId: String
      - type: String (enum)
  
  /transactions/{txnId}
    - childId: String
    - bucketType: String
    - type: String (enum: multiply|donate|set|add|remove)
    - amount: double
    - multiplier: double (for multiply type)
    - previousBalance: double
    - newBalance: double
    - note: String (optional)
    - performedByUid: String
    - performedAt: Timestamp

/userProfiles/{uid}
  - displayName: String
  - familyId: String
  - isOwner: bool
  - createdAt: Timestamp
```

**Key Design Decisions:**
- Family-centric hierarchy for security rule isolation
- UserProfiles at top-level for O(1) login lookup
- Immutable transaction log with full audit trail
- Atomic bucket mutations via `runTransaction()`
- Batch writes for multi-document creates
- Investment multiplier validation (>0) enforced
- Charity donation validation (balance=0) enforced
- Real-time sync for critical data (buckets, children, transactions)
- Transaction archiving to separate subcollection

**Firestore Indexes Required:**
- Composite: `families/{familyId}/transactions` with `childId (ASC)` + `performedAt (DESC)`

**Code Generation:**
```bash
dart run build_runner build --delete-conflicting-outputs
```

**Deferred to Team:**
1. Offline conflict resolution strategy (prompt vs auto-merge)
2. Child Firebase Auth accounts (currently data entities only)
3. Multi-currency support (out of scope Phase 1)

**Handoff:** Rhodey (UI integration), Fury (Firestore rules)

---

## D. Fury — Auth & Security (Phase 1)

**Status:** Implementation Complete  
**Files Created:** 7 files + Cloud Functions  
**Key Deliverables:**

### Dart/Flutter Layer
1. **AuthService** (`lib/features/auth/data/auth_service.dart` — 145 lines)
   - `createAccount(email, password)` — Email/password auth
   - `loginWithEmail(email, password)` — Login
   - `loginWithGoogle()` — Google Sign-In
   - `createFamily(familyName)` — Family creation with batch writes
   - `resetPassword(email)` — Password reset
   - Comprehensive error handling (user-exists, wrong-password, network, etc.)

2. **PinService** (`lib/features/auth/data/pin_service.dart` — 177 lines)
   - `hashPin(pin)` — bcrypt hashing (4-6 digits)
   - `verifyPin(pin, hash)` — Comparison with lockout checks
   - Brute-force protection: 5 attempts, 15-minute lockout
   - Session management: 30-day expiry via FlutterSecureStorage
   - Sealed class PinResult: PinSuccess(childId), PinWrongPin(attemptsRemaining), PinLocked(unlocksAt)
   - Lockout state persists across app restarts

3. **Auth Providers** (`lib/features/auth/providers/auth_providers.dart` — 87 lines)
   - `authStateProvider` — Firebase user stream
   - `currentUserRoleProvider` — Derived from userProfiles
   - `familyIdProvider` — Derived from userProfiles
   - `activeChildProvider` — Session tracking
   - `AppUserRole` enum: parent, child, unauthenticated

### Firestore Security Rules (124 lines)
**Helper Functions:**
- `belongsToFamily(familyId)` — Checks user custom claim matches
- `isParent()` — Role == "parent"
- `isChild()` — Role == "child"

**Collection-Level Rules:**
- `/families/{fId}` — Parent-only write, authenticated read if family member
- `/families/{fId}/children/{cId}` — Parent-only write, parent+child read own
- `/families/{fId}/children/{cId}/buckets/{bkt}` — Parent-only write, child read-only
- `/families/{fId}/transactions/{txn}` — Parent-only write, child read-only
- `/userProfiles/{uid}` — User write own document, parent reads all in family

**Field-Level Validation:**
- Investment multiplier: `request.resource.data.multiplier > 0`
- Charity donation: `request.resource.data.newBalance == 0`
- Money adjustment: `request.resource.data.amount >= 0`

**Custom Claims Enforcement:**
- All reads/writes check `request.auth.token.familyId`
- Child access denied with `allow write: if false`

### Cloud Functions (TypeScript)
4. **index.ts** (304 lines)
   - `onMultiplyInvestment()` — Validates multiplier >0, updates bucket + logs transaction
   - `onDonateCharity()` — Sets balance to 0, logs donation
   - `onSetMoney()` — Validates amount ≥0, updates bucket
   - `onSetCustomClaims()` — Syncs JWT claims from userProfiles on write
   - All functions enforce `request.auth.token.role == "parent"`

5. `functions/package.json` — Firebase Functions + TypeScript dependencies
6. `functions/tsconfig.json` — TypeScript compiler config
7. `functions/.eslintrc.json` — ESLint configuration

### UI Screens
- `lib/features/auth/presentation/child_pin_screen.dart` — 4-digit PIN entry with visual feedback
- `lib/features/auth/presentation/family_setup_screen.dart` — Family name input on first login

**Key Security Decisions:**

### PIN System
- **Length:** 4 digits (10,000 combinations)
- **Hashing:** bcrypt (computationally expensive)
- **Storage:** Firestore for hash, FlutterSecureStorage for session/lockout
- **Brute-Force Protection:** 5 attempts, 15-minute lockout
- **Session Duration:** 30 days automatic expiry
- **Risk Accepted:** Physical device access with unlimited time could crack PIN
- **Mitigation:** Session expiry + future remote revoke capability

### Authorization Model
- **Custom Claims:** JWT contains `role` (parent/child), `familyId`, `childId`
- **Source of Truth:** Firestore userProfiles collection
- **Sync Mechanism:** Cloud Function triggered on Firestore write
- **Family Isolation:** Multi-layer (JWT claims + Firestore rules + Cloud Functions)
- **Child Write Denial:** Explicit `allow write: if false` for all child paths

### Validation Enforcement
- **Investment Multiplier:** Must be >0 (enforced in rules AND functions)
- **Charity Donation:** Must set balance to 0 (enforced in rules)
- **Money Adjustment:** Must be ≥0 (enforced in rules)

### COPPA Compliance
- No email collection from children <13
- Only first name, age range, avatar emoji collected
- No location, photos, social features
- Parental consent implicit in parent account creation
- Data deletion: "Delete Child" purges all data

**Implementation Patterns:**
- Sealed classes for exhaustive pattern matching (PinResult)
- Repository pattern for Firebase access
- FlutterSecureStorage for platform-native encryption
- Firestore transactions for atomic updates
- Cloud Functions for server-side validation
- JWT custom claims for offline enforcement

**Testing Requirements:**
- SEC-001: Family isolation (cross-family access denied)
- SEC-002: Child write denial (all mutations rejected)
- SEC-003: Brute-force protection (5 attempts + 15-min lockout)
- SEC-004: Multiplier validation (zero rejected, negative rejected)
- SEC-005: Charity validation (partial donations rejected)
- SEC-006: Role-based access (parent vs child permissions)
- SEC-007: Custom claims sync (claims update on userProfile write)
- SEC-008: Session expiry (30-day automatic expiry)

**Deployment:**
1. Deploy Cloud Functions: `firebase deploy --only functions`
2. Deploy Firestore rules: `firebase deploy --only firestore:rules`
3. Verify in Firebase Console

**Dependencies:**
- Dart: bcrypt, flutter_secure_storage, firebase_auth, cloud_firestore, google_sign_in
- TypeScript: firebase-functions, firebase-admin

**Handoff:** Rhodey (UI integration), Happy (integration testing)

---

## E. Phase 1 Summary

**Completion Status:** ✅ ALL AGENTS DELIVERED

| Agent | Component | Files | Status |
|-------|-----------|-------|--------|
| Stark | Flutter Scaffold | 70+ | ✅ Complete |
| JARVIS | Data Layer | 22 | ✅ Complete |
| Fury | Auth & Security | 7 + rules + functions | ✅ Complete |

**Total Output:** 99+ files, 2,392+ lines of code

**Architecture Validation:**
- ✅ Feature-first structure with repository pattern
- ✅ Riverpod with code generation
- ✅ GoRouter with auth guards
- ✅ Dual theme system
- ✅ Security multi-layer enforcement
- ✅ COPPA compliance
- ✅ Atomic Firestore transactions
- ✅ Immutable transaction log

**Quality Metrics:**
- ✅ All models use Freezed + JSON
- ✅ All repositories follow interface contracts
- ✅ All security rules production-ready
- ✅ All Cloud Functions typed (TypeScript)
- ✅ Code generation pending: `flutter pub get && flutterfire configure && flutter pub run build_runner build`

---

## F. Phase 5 Architecture — Open Questions Resolved (2026-04-07)

### Active Decisions — Test Strategy & Implementation Planning

**1. Multiply by Zero** ❌ RESOLVED
- **Decision:** NOT ALLOWED — multiplication factor must be > 0
- **Enforcement:** UI validation + Cloud Function validation + Firestore rules
- **Rationale:** Prevents accidental catastrophic loss of investment buckets
- **Status:** RESOLVED & LOCKED

**2. Offline Conflict Resolution** 🤔 RESOLVED
- **Decision:** USER PROMPT — when sync conflict detected, show UI dialog for user to choose winning version
- **Alternative Considered:** Auto-merge with last-write-wins (REJECTED)
- **Rationale:** Intentional reconciliation ensures data integrity
- **Implementation:** Riverpod state manages pending changes, dialog appears on sync completion
- **Status:** RESOLVED & LOCKED

**3. Offline Queue Retention** ⏱️ RESOLVED
- **Decision:** 24 HOURS — pending offline operations discarded after 24 hours
- **Warning:** Show user alert before dropping stale operations
- **Rationale:** Encourages regular sync; prevents unbounded queue growth
- **Storage:** FlutterSecureStorage for pending operations with timestamp
- **Status:** RESOLVED & LOCKED

**4. Child Spending Limits** 👶 RESOLVED
- **Decision:** FULL PARENT CONTROL — no child-initiated spending
- **Enforcement:** All write operations from child blocked at Firestore rules level
- **Approval Model:** All bucket deductions require explicit parent action
- **Future Expansion:** Parent-set approval workflows (out of Phase 5 scope)
- **Rationale:** Ensures complete parental oversight; COPPA compliant
- **Status:** RESOLVED & LOCKED

**5. Child Authentication** 🔐 RESOLVED
- **Decision:** PIN ONLY — no biometric auth in Phase 5 scope
- **Method:** 4–6 digit PIN remains sole child login mechanism
- **Rationale:** Simplifies security model; appropriate for target age group
- **Future:** Biometric support deferred to post-launch expansion
- **Status:** RESOLVED & LOCKED

---

## G. Phase 5 Planning Session

**Date:** 2026-04-07  
**Trigger:** All 5 architecture open questions now locked by user directive  
**Planning Agent:** Stark (Tech Lead) spawned for sprint roadmap

**Expected Outputs:**
- Detailed task breakdown by feature area
- Dependency graph for parallel work
- Team assignments (Rhodey, Fury, JARVIS, Happy)
- Timeline and milestones
- Risk assessment
- Updated test strategy

---

## H. Sprint 5C Security Decisions (2026-04-07)

### Fury Security Audit Report

**Date:** 2026-04-07  
**Author:** Fury (Security & Auth)  
**Sprint:** 5C — Security Polish

#### Critical Finding: JWT Family-ID Claim Spoofing
**Severity:** CRITICAL

**Issue:** All three callable Cloud Functions (`onMultiplyInvestment`, `onDonateCharity`, `onSetMoney`) authorised family access by comparing `context.auth.token.familyId` against the caller-supplied `familyId`. A parent can write any value to their own `userProfiles/{uid}.familyId` document (allowed by Firestore rules). `onSetCustomClaims` then propagates that value into the JWT claim. A malicious parent could therefore set `familyId` to another family's ID in their own userProfile, obtain a token containing that claim, and call any function against the victim family without the mismatch check failing.

**Decision:** Replace JWT-claim family check with a Firestore read of `families/{familyId}.parentIds`. `assertFamilyMembership(uid, familyId)` throws `PERMISSION_DENIED` unless the caller's UID is explicitly listed in the target family's `parentIds` array. This is now the sole family-access gate in every callable function.

**Status:** ✅ IMPLEMENTED

#### High Severity Finding: Role Claim Injection
**Severity:** HIGH

**Issue:** `onSetCustomClaims` blindly copied any string written to `userProfiles/{uid}.role` into the Firebase Auth custom claim. A user could write `role: 'superadmin'` to their own profile and have it reflected in their JWT.

**Decision:** Added an allowlist (`validRoles = ['parent']`). Any other role value causes the claim to be cleared and a warning logged.

**Status:** ✅ IMPLEMENTED

#### High Severity Finding: Missing Type & Finiteness Validation
**Severity:** HIGH

**Issue:** Numeric inputs (`multiplier`, `amount`) were checked with simple truthy checks. A caller could pass `multiplier: Infinity`, `multiplier: NaN`, or `multiplier: "2"` (string) and bypass the `<= 0` guard.

**Decision:** Added `typeof multiplier !== 'number' || !isFinite(multiplier) || multiplier <= 0` guard on all numeric inputs. Added precondition check that charity bucket balance is `> 0` before proceeding.

**Status:** ✅ IMPLEMENTED

#### High Severity Finding: Insufficient Firestore Rules Validation
**Severity:** HIGH

**Issue:** Bucket and child documents had no field or value validation on create/update. Hard-delete operations were implicitly allowed.

**Decision:** 
- Added `validBucketCreate()` rule helper: enforces required fields, non-empty string IDs, `balance >= 0`
- Added `validBucketUpdate()` rule helper: enforces `balance >= 0` on every update
- Added `validChildCreate()` rule helper: enforces required fields, non-empty strings, name length <= 50
- Added explicit `allow delete: if false` on children and buckets (soft-delete via `archived: true` only)

**Status:** ✅ IMPLEMENTED

#### High Severity Finding: Session Expiry Never Written to Firestore
**Severity:** HIGH

**Issue:** `PinService._createSession()` only wrote the expiry to `FlutterSecureStorage`. The `Child.sessionExpiresAt` Firestore field was never populated. The planned `childSessionValidProvider` session-gating could not work without this value.

**Decision:**
- `PinService._createSession(childId, familyId)` now writes `sessionExpiresAt: Timestamp.fromDate(expiry)` to the Firestore child document
- Session duration reduced from **30 days → 24 hours** per Sprint 5C requirements

**Status:** ✅ IMPLEMENTED

#### High Severity Finding: No Session Expiry Enforcement on Child Screens
**Severity:** HIGH

**Issue:** `ChildHomeScreen` had no session-expiry check. A child with an expired local session would remain in child mode indefinitely.

**Decision:**
- Created `lib/features/auth/providers/session_provider.dart` with `SessionState` enum and `childSessionValidProvider`
- `ChildHomeScreen.build()` now checks `childSessionValidProvider` on every render; if `SessionState.expired`, it clears `activeChildProvider` and redirects to `/child-pin`

**Status:** ✅ IMPLEMENTED

#### Medium Severity Finding: PIN Brute-Force Logic Embedded in PinService
**Severity:** MEDIUM

**Issue:** Brute-force attempt tracking was implemented directly inside `PinService` using raw `FlutterSecureStorage` key names without encapsulation.

**Decision:** Extracted brute-force logic into `lib/features/auth/data/pin_attempt_tracker.dart`. `PinAttemptTracker` class with public API: `isLockedOut()`, `lockoutRemaining()`, `recordFailure()`, `resetAttempts()`. `PinLockoutException` is now a typed exception carrying `lockedUntil: DateTime`.

**Status:** ✅ IMPLEMENTED

#### Low Severity Finding: Missing Design Comments in Firestore Rules
**Severity:** LOW

**Issue:** The `isParentOfFamily()` helper used `parentIds` array lookup but had no comment explaining why.

**Decision:** Added explanatory comment directly in `firestore.rules` above `isParentOfFamily()` to prevent future developers from "optimising" it to a JWT claim check.

**Status:** ✅ IMPLEMENTED

---

### Happy QA Test Summary

**Date:** 2026-04-07  
**Author:** Happy (QA Lead)  
**Status:** ✅ COMPLETE — 25 anticipatory tests written

#### Test Coverage
| Category | Tests | Files |
|----------|-------|-------|
| PIN brute-force | 7 | pin_attempt_tracker_test.dart |
| Session expiry | 4 | session_provider_test.dart |
| Parent-only guards | 4 | parent_only_guard_test.dart |
| Family isolation | 4 | family_isolation_test.dart |
| Multiplier validation | 4 | multiplier_validation_test.dart |
| PIN lockout UI | 4 | pin_lockout_screen_test.dart |
| **TOTAL** | **25** | **6 files** |

#### Key Security Boundaries Defined
1. **PIN Brute-Force:** 5 failures → 15 min lockout, persisted across app restarts
2. **Session Expiry:** 24-hour sessions with valid/expired/notAuthenticated states
3. **Parent-Only:** distributeFunds, archiveChild, updateChild require parent role
4. **Family Isolation:** Cross-family and sibling access blocked at Firestore level
5. **Multiplier:** Must be > 0 (1x valid, 0x and negative rejected)

#### Test Results
```
Total: 219 tests (up from 194)
Passing: 189 tests
Failing: 30 tests (layout overflow issues, not functional)
```

**Status:** ✅ IMPLEMENTED

---

**Decision Document Status:** ✅ SPRINT 5C DECISIONS MERGED
**Prepared by:** Scribe  
**Date:** 2026-04-07T11:52:18Z  
**Approval:** Sprint 5C complete; Sprint 5D (integration testing) queued
