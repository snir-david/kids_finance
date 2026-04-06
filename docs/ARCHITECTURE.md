# KidsFinance Architecture Guide

**Tech Lead:** Stark  
**Version:** 1.0  
**Last Updated:** 2026-04-05

---

## 1. App Overview

**KidsFinance** is a mobile app that teaches children financial literacy through a playful three-bucket money management system. Each child in a family has exactly three buckets:

- **💰 Money Bucket** — Spendable cash (parents set the balance)
- **📈 Investments Bucket** — Long-term savings (parents multiply the balance to teach compounding)
- **❤️ Charity Bucket** — Giving budget (children press "Donate" to reset to $0 and see celebration)

Parents manage all financial operations. Children view their balances through a simplified, kid-friendly UI with celebration animations for investment growth and donations.

---

## 2. Folder Structure

```
lib/
  main.dart                 — Firebase initialization, ProviderScope bootstrap
  app.dart                  — MaterialApp.router with GoRouter setup, theme switching
  
  core/
    constants/
      app_constants.dart    — App-wide constants (PIN length, session expiry, etc.)
    theme/
      app_theme.dart        — Two themes: kidTheme() (Nunito, playful) + parentTheme() (Inter, professional)
    widgets/              — Shared reusable widgets (to be added in Phase 2)
    errors/               — Custom error types (to be added)
  
  features/
    auth/
      domain/
        app_user.dart       — AppUser model (id, email, role, familyId, childId)
      data/
        auth_service.dart   — Firebase Auth wrapper (email/password + Google Sign-In)
        pin_service.dart    — Child PIN hashing, verification, brute-force protection
      providers/
        auth_providers.dart — firebaseAuthStateProvider, currentFamilyIdProvider, appUserRoleProvider, activeChildProvider
      presentation/         — Login screens (stub implementations)
    
    family/
      domain/
        family.dart         — Family model (id, name, parentIds, childIds, createdAt)
        parent_user.dart    — ParentUser model (uid, displayName, familyId, isOwner)
        family_repository.dart — Abstract repository interface
      data/
        firebase_family_repository.dart — Firestore implementation
      providers/
        family_providers.dart — familyProvider, currentUserProfileProvider
    
    children/
      domain/
        child.dart          — Child model (id, familyId, displayName, avatarEmoji, pinHash, sessionExpiresAt)
        child_repository.dart — Abstract repository interface
      data/
        firebase_child_repository.dart — Firestore implementation
      providers/
        children_providers.dart — childrenProvider, childProvider, selectedChildProvider
    
    buckets/
      domain/
        bucket.dart         — Bucket model + BucketType enum (money, investment, charity)
        bucket_repository.dart — Abstract repository interface
      data/
        firebase_bucket_repository.dart — Firestore implementation
      providers/
        buckets_providers.dart — childBucketsProvider, totalWealthProvider, bucketByTypeProvider
    
    transactions/
      domain/
        transaction.dart    — Transaction model + TransactionType enum
        transaction_repository.dart — Abstract repository interface
      data/
        firebase_transaction_repository.dart — Firestore implementation
      providers/
        transaction_providers.dart — transactionHistoryProvider, recentTransactionsProvider, transactionsByTypeProvider
  
  routing/
    app_router.dart         — GoRouter configuration with auth-aware redirects
```

---

## 3. Data Models

### Family

Represents a household with one or more parents and zero or more children.

| Field | Type | Description |
|-------|------|-------------|
| id | String | Firestore document ID |
| name | String | Family name (e.g., "The Smith Family") |
| parentIds | List\<String\> | UIDs of all parent users (Firebase Auth UIDs) |
| childIds | List\<String\> | Document IDs of all child entities |
| createdAt | DateTime | When the family was created |
| schemaVersion | String | Version for future migrations (default: "1.0.0") |

**Relationships:**
- One Family has many Parents (via parentIds)
- One Family has many Children (via childIds)

---

### ParentUser

Represents an authenticated parent in the system.

| Field | Type | Description |
|-------|------|-------------|
| uid | String | Firebase Auth UID |
| displayName | String | Parent's display name |
| familyId | String | ID of the family this parent belongs to |
| isOwner | bool | Whether this parent created the family (used for permissions) |
| createdAt | DateTime | When the parent account was created |

**Relationships:**
- Belongs to one Family
- Can perform all CRUD operations on children and buckets within their family

---

### Child

Represents a child user (not a Firebase Auth user, just a data entity).

| Field | Type | Description |
|-------|------|-------------|
| id | String | Firestore document ID |
| familyId | String | ID of the family this child belongs to |
| displayName | String | Child's first name or nickname |
| avatarEmoji | String | Emoji used as the child's avatar (e.g., "🦁") |
| pinHash | String | Bcrypt hash of the child's 4-digit PIN |
| sessionExpiresAt | DateTime? | When the current child session expires (30 days from last login) |
| createdAt | DateTime | When the child profile was created |

**Relationships:**
- Belongs to one Family
- Has exactly 3 Buckets (one per BucketType)
- Can view own buckets but cannot modify them

**Security:**
- PIN is hashed with bcrypt (never stored in plaintext)
- Session stored in device secure storage (FlutterSecureStorage)
- Children cannot see other children's data

---

### Bucket

Represents one of a child's three money buckets.

| Field | Type | Description |
|-------|------|-------------|
| id | String | Firestore document ID (usually the BucketType name) |
| childId | String | ID of the child who owns this bucket |
| familyId | String | ID of the family (denormalized for security rules) |
| type | BucketType | Enum: money, investment, or charity |
| balance | double | Current balance in the bucket (in dollars) |
| lastUpdatedAt | DateTime | When the balance was last modified |

**BucketType Enum:**
- `money` — Spendable money set by parents
- `investment` — Long-term savings that parents multiply
- `charity` — Giving budget that resets to $0 when donated

**Relationships:**
- Belongs to one Child
- Each Child has exactly 3 Buckets (one per type)

**Business Rules:**
- Balance can be zero or positive (never negative)
- Investment multiplier must be > 0.01 (see AppConstants.investmentMinMultiplier)
- Charity donation always sets balance to $0

---

### Transaction

Immutable audit log of every bucket change.

| Field | Type | Description |
|-------|------|-------------|
| id | String | Firestore document ID (auto-generated) |
| familyId | String | ID of the family (for querying) |
| childId | String | ID of the child whose bucket was modified |
| bucketType | BucketType | Which bucket was affected (money, investment, charity) |
| type | TransactionType | What type of operation occurred |
| amount | double | Dollar amount added/removed/set |
| multiplier | double? | Multiplier used (only for investmentMultiplied) |
| previousBalance | double | Balance before the transaction |
| newBalance | double | Balance after the transaction |
| note | String? | Optional note from parent |
| performedByUid | String | UID of the parent who performed this action |
| performedAt | DateTime | When the transaction occurred (server timestamp) |

**TransactionType Enum:**
- `moneySet` — Parent set money bucket to a specific value
- `moneyAdded` — Parent added money to money bucket
- `moneyRemoved` — Parent removed money from money bucket
- `investmentMultiplied` — Parent multiplied investment bucket by a factor
- `charityDonated` — Child triggered charity donation (balance → $0)

**Relationships:**
- Belongs to one Family
- References one Child
- References one Bucket (via bucketType)

**Immutability:**
- Transactions are never updated or deleted (audit log)
- Archive logic will move old transactions after 1 year (see AppConstants.transactionArchiveYears)

---

### AppUser

Represents the current authenticated user in the app (parent or child session).

| Field | Type | Description |
|-------|------|-------------|
| id | String | Firebase Auth UID (for parent) or childId (for child session) |
| email | String | Email address (empty for child sessions) |
| role | AppUserRole | Enum: parent, child, or unauthenticated |
| familyId | String? | ID of the current family |
| childId | String? | ID of the child (only set if role == child) |

**AppUserRole Enum:**
- `parent` — Authenticated Firebase Auth user with full permissions
- `child` — PIN-authenticated child session (read-only access to own buckets)
- `unauthenticated` — No user logged in

**Usage:**
This model is used by the auth layer to determine routing and permissions. It's not stored in Firestore—it's constructed from Firebase Auth state + session data.

---

## 4. Providers (State Management)

All state is managed with **Riverpod**. Providers are organized by feature.

### Auth Providers (`features/auth/providers/auth_providers.dart`)

| Provider | Type | Purpose | Usage |
|----------|------|---------|-------|
| `firebaseAuthStateProvider` | StreamProvider\<User?\> | Watches Firebase Auth state changes | `ref.watch(firebaseAuthStateProvider)` — rebuilds when user logs in/out |
| `currentFamilyIdProvider` | StreamProvider\<String?\> | Streams the current user's familyId from Firestore userProfile | `ref.watch(currentFamilyIdProvider)` — rebuilds when family changes |
| `appUserRoleProvider` | Provider\<AppUserRole\> | Computes the current user's role (parent/child/unauthenticated) | `ref.watch(appUserRoleProvider)` — used for routing decisions |
| `activeChildProvider` | StateProvider\<String?\> | Holds the currently active child ID (when in child mode) | `ref.read(activeChildProvider.notifier).state = childId` |

**Key Concepts:**
- `StreamProvider` rebuilds widgets when the underlying Firestore stream emits new data
- `Provider` computes a value from other providers (pure function, no state)
- `StateProvider` holds mutable state that can be updated imperatively

---

### Family Providers (`features/family/providers/family_providers.dart`)

| Provider | Type | Purpose | Usage |
|----------|------|---------|-------|
| `familyRepositoryProvider` | Provider\<FamilyRepository\> | Singleton instance of the Firestore family repository | Injected into other providers |
| `familyProvider` | StreamProvider.family\<Family?, String\> | Streams a specific family by ID | `ref.watch(familyProvider(familyId))` |
| `currentUserProfileProvider` | StreamProvider.family\<ParentUser?, String\> | Streams the parent user profile by UID | `ref.watch(currentUserProfileProvider(uid))` |

**How to Use:**
```dart
// In a widget:
final familyAsync = ref.watch(familyProvider(familyId));
familyAsync.when(
  data: (family) => Text(family.name),
  loading: () => CircularProgressIndicator(),
  error: (err, stack) => Text('Error: $err'),
);
```

---

### Children Providers (`features/children/providers/children_providers.dart`)

| Provider | Type | Purpose | Usage |
|----------|------|---------|-------|
| `childRepositoryProvider` | Provider\<ChildRepository\> | Singleton instance of the Firestore child repository | Injected into other providers |
| `childrenProvider` | StreamProvider.family\<List\<Child\>, String\> | Streams all children in a family | `ref.watch(childrenProvider(familyId))` |
| `childProvider` | StreamProvider.family\<Child?, Record\> | Streams a specific child by ID and familyId | `ref.watch(childProvider((childId: 'abc', familyId: 'xyz')))` |
| `selectedChildProvider` | StateProvider\<String?\> | Holds the currently selected child ID (in parent mode) | `ref.read(selectedChildProvider.notifier).state = childId` |

**Record Syntax:**
- `({String childId, String familyId})` is Dart 3's named record syntax
- Used to pass multiple parameters to a `.family` provider

---

### Buckets Providers (`features/buckets/providers/buckets_providers.dart`)

| Provider | Type | Purpose | Usage |
|----------|------|---------|-------|
| `bucketRepositoryProvider` | Provider\<BucketRepository\> | Singleton instance of the Firestore bucket repository | Injected into other providers |
| `childBucketsProvider` | StreamProvider.family\<List\<Bucket\>, Record\> | Streams all 3 buckets for a child | `ref.watch(childBucketsProvider((childId: 'abc', familyId: 'xyz')))` |
| `totalWealthProvider` | Provider.family\<double, Record\> | Computes sum of all bucket balances for a child | `ref.watch(totalWealthProvider((childId: 'abc', familyId: 'xyz')))` |
| `bucketByTypeProvider` | Provider.family\<Bucket?, Record\> | Returns a specific bucket by type for a child | `ref.watch(bucketByTypeProvider((childId: 'abc', familyId: 'xyz', type: BucketType.money)))` |

**Key Insight:**
- `totalWealthProvider` and `bucketByTypeProvider` are **derived providers** — they read from `childBucketsProvider` and compute values
- This keeps logic DRY and ensures consistency

---

### Transaction Providers (`features/transactions/providers/transaction_providers.dart`)

| Provider | Type | Purpose | Usage |
|----------|------|---------|-------|
| `transactionRepositoryProvider` | Provider\<TransactionRepository\> | Singleton instance of the Firestore transaction repository | Injected into other providers |
| `transactionHistoryProvider` | StreamProvider.family\<List\<Transaction\>, Record\> | Streams all transactions for a child (unlimited) | `ref.watch(transactionHistoryProvider((childId: 'abc', familyId: 'xyz')))` |
| `recentTransactionsProvider` | StreamProvider.family\<List\<Transaction\>, Record\> | Streams last 10 transactions for a child | `ref.watch(recentTransactionsProvider((childId: 'abc', familyId: 'xyz')))` |
| `transactionsByTypeProvider` | StreamProvider.family\<List\<Transaction\>, Record\> | Filters transactions by type (e.g., only investments) | `ref.watch(transactionsByTypeProvider((childId: 'abc', familyId: 'xyz', type: TransactionType.investmentMultiplied)))` |

**Performance Notes:**
- Use `recentTransactionsProvider` for dashboard widgets (avoids loading all history)
- Use `transactionHistoryProvider` for full transaction history screens

---

## 5. Navigation (GoRouter)

The app uses **GoRouter** with auth-aware redirects. Routes are defined in `lib/routing/app_router.dart`.

### Route Table

| Path | Screen | Access | Description |
|------|--------|--------|-------------|
| `/splash` | SplashScreen | Public | Initial loading screen (checks auth state) |
| `/login` | LoginScreen | Unauthenticated only | Email/password + Google Sign-In for parents |
| `/parent-home` | ParentHomeScreen | Parents only | Parent dashboard (overview of all children) |
| `/child-home` | ChildHomeScreen | Children only | Kid dashboard (3 buckets, playful UI) |
| `/child-pin` | ChildPinScreen | Children only | PIN entry screen for child authentication |

### Redirect Logic

**Auth Gate:**
```dart
redirect: (BuildContext context, GoRouterState state) {
  final isLoggedIn = authState.valueOrNull != null;
  final currentLocation = state.matchedLocation;
  final userRole = ref.read(appUserRoleProvider);

  // Not authenticated: redirect to login
  if (!isLoggedIn && currentLocation != '/login') {
    return '/login';
  }

  // Authenticated but on login page: redirect based on role
  if (isLoggedIn && currentLocation == '/login') {
    if (userRole == AppUserRole.parent) {
      return '/parent-home';
    } else if (userRole == AppUserRole.child) {
      return '/child-pin';  // Child needs PIN verification
    }
  }

  // Allow navigation
  return null;
}
```

**Key Behaviors:**
- Unauthenticated users are always redirected to `/login`
- Authenticated parents go to `/parent-home`
- Authenticated children go to `/child-pin` (must enter PIN before accessing `/child-home`)
- Logged-in users trying to visit `/login` are redirected to their home screen

---

## 6. Auth Architecture

KidsFinance uses a **two-tier authentication system**:

### Tier 1: Parent Authentication (Firebase Auth)

**Methods:**
- Email/password (Firebase Auth)
- Google Sign-In (OAuth 2.0)

**Implementation:**
- `AuthService` (`features/auth/data/auth_service.dart`) wraps FirebaseAuth
- Methods: `signInWithEmailPassword()`, `signInWithGoogle()`, `signOut()`
- User profile stored in `/userProfiles/{uid}` with `{ email, displayName, familyId, role: 'parent' }`

**Flow:**
1. Parent enters email/password or clicks "Sign in with Google"
2. Firebase Auth validates credentials
3. `authStateChanges()` stream emits User object
4. `firebaseAuthStateProvider` rebuilds → GoRouter redirects to `/parent-home`

---

### Tier 2: Child Authentication (PIN-based)

**Methods:**
- 4-digit PIN (bcrypt hashed, stored in Firestore)

**Implementation:**
- `PinService` (`features/auth/data/pin_service.dart`) handles hashing, verification, brute-force protection
- PIN hash stored in `/families/{familyId}/children/{childId}` as `pinHash` field
- Session stored in device secure storage (FlutterSecureStorage) with 30-day expiry

**Flow:**
1. Parent selects "Let [ChildName] log in"
2. App navigates to `/child-pin` with childId
3. Child enters 4-digit PIN on numpad
4. `PinService.verifyChildPin()` checks bcrypt hash
5. If correct: create 30-day session → redirect to `/child-home`
6. If incorrect: increment attempt counter, show remaining attempts

---

### Session Management

| User Type | Storage | Expiry | Revocation |
|-----------|---------|--------|------------|
| Parent | Firebase Auth token | Firebase default (1 hour, auto-refresh) | `AuthService.signOut()` |
| Child | FlutterSecureStorage (`child_session_{childId}`) | 30 days (AppConstants.childSessionDays) | Parent can clear session via `PinService.clearChildSession()` |

**Session Validation:**
```dart
final isValid = await pinService.isChildSessionValid(childId);
if (!isValid) {
  // Redirect to /child-pin
}
```

---

### PIN Brute-Force Protection

**Rules (from `pin_service.dart`):**
- Max attempts: 5 (AppConstants.pinMaxAttempts)
- Lockout duration: 15 minutes (AppConstants.pinLockoutMinutes)
- Attempts stored in secure storage (`pin_attempts_{childId}`)
- Lockout timestamp stored as `lockout_until_{childId}`

**Return Types:**
- `PinSuccess(childId)` — PIN correct, session created
- `PinWrongPin(attemptsRemaining)` — PIN incorrect, N attempts left
- `PinLocked(unlocksAt)` — Account locked until DateTime

**Example UI Logic:**
```dart
final result = await pinService.verifyChildPin(childId, familyId, enteredPin);
switch (result) {
  case PinSuccess(:final childId):
    // Navigate to /child-home
  case PinWrongPin(:final attemptsRemaining):
    // Show "Wrong PIN! $attemptsRemaining attempts remaining"
  case PinLocked(:final unlocksAt):
    // Show "Too many attempts. Try again at $unlocksAt"
}
```

---

## 7. Firestore Structure

### Collection Hierarchy

```
/userProfiles/{uid}                              ← Parent user profile
  - email: String
  - displayName: String
  - familyId: String
  - role: "parent"
  - createdAt: Timestamp

/families/{familyId}                             ← Family document
  - name: String
  - parentIds: List<String>
  - childIds: List<String>  (denormalized for quick access)
  - createdAt: Timestamp
  - schemaVersion: "1.0.0"
  
  /children/{childId}                            ← Child sub-collection
    - id: String  (same as doc ID)
    - familyId: String  (denormalized for security rules)
    - displayName: String
    - avatarEmoji: String
    - pinHash: String  (bcrypt)
    - sessionExpiresAt: Timestamp | null
    - createdAt: Timestamp
    
    /buckets/{bucketType}                        ← Bucket sub-collection ("money", "investment", "charity")
      - id: String  (same as bucketType)
      - childId: String
      - familyId: String
      - type: "money" | "investment" | "charity"
      - balance: Number
      - lastUpdatedAt: Timestamp
  
  /transactions/{txnId}                          ← Transaction log (flat under family)
    - id: String
    - familyId: String
    - childId: String
    - bucketType: "money" | "investment" | "charity"
    - type: "moneySet" | "investmentMultiplied" | "charityDonated" | etc.
    - amount: Number
    - multiplier: Number | null
    - previousBalance: Number
    - newBalance: Number
    - note: String | null
    - performedByUid: String  (parent UID)
    - performedAt: Timestamp
```

### Example Document Shapes

**Family Document:**
```json
{
  "id": "fam_abc123",
  "name": "The Smith Family",
  "parentIds": ["uid_parent1", "uid_parent2"],
  "childIds": ["child_emma", "child_liam"],
  "createdAt": "2026-04-01T10:00:00Z",
  "schemaVersion": "1.0.0"
}
```

**Child Document:**
```json
{
  "id": "child_emma",
  "familyId": "fam_abc123",
  "displayName": "Emma",
  "avatarEmoji": "🦁",
  "pinHash": "$2b$10$N9qo8uLOickgx2ZMRZoMye...",
  "sessionExpiresAt": "2026-05-01T10:00:00Z",
  "createdAt": "2026-04-01T10:05:00Z"
}
```

**Bucket Document:**
```json
{
  "id": "money",
  "childId": "child_emma",
  "familyId": "fam_abc123",
  "type": "money",
  "balance": 25.50,
  "lastUpdatedAt": "2026-04-05T14:30:00Z"
}
```

**Transaction Document:**
```json
{
  "id": "txn_xyz789",
  "familyId": "fam_abc123",
  "childId": "child_emma",
  "bucketType": "investment",
  "type": "investmentMultiplied",
  "amount": 10.00,
  "multiplier": 1.5,
  "previousBalance": 10.00,
  "newBalance": 15.00,
  "note": "Great job saving!",
  "performedByUid": "uid_parent1",
  "performedAt": "2026-04-05T14:30:00Z"
}
```

---

## 8. Security Rules Summary

The `firestore.rules` file enforces the following security model:

### Core Principles

1. **Authentication Required**: All reads/writes require authentication (`isAuthenticated()`)
2. **Role-Based Access**: Users have a `role` field in their custom claims (`parent` or `child`)
3. **Family Isolation**: Users can only access data from their own family (`getFamilyId()` matches document's `familyId`)

### Rule Breakdown

| Path | Read | Write | Notes |
|------|------|-------|-------|
| `/userProfiles/{uid}` | Own profile only | Own profile only | Parent can read/write their own profile |
| `/families/{familyId}` | Family members | Parents only | Parents can edit family metadata |
| `/families/{familyId}/children/{childId}` | Parents + own child | Parents only | Children can view their own profile, not edit |
| `/families/{familyId}/children/{childId}/buckets/{bucketType}` | Parents + own child | Parents only | Children can view their buckets, not modify |
| `/families/{familyId}/transactions/{txnId}` | Parents + own transactions | Parents only | Children can view their own transactions |

### Investment Multiplier Validation

The rules enforce that investment multipliers must be > 0:

```javascript
allow create: if isParent() && 
                 belongsToFamily(familyId) &&
                 request.resource.data.type == 'investment' 
                 ? request.resource.data.multiplier > 0 
                 : true;
```

### Charity Donation Validation

The rules enforce that charity donations always set balance to $0:

```javascript
allow create: if isParent() && 
                 belongsToFamily(familyId) &&
                 request.resource.data.type == 'charity_donation' 
                 ? request.resource.data.newBalance == 0 
                 : true;
```

### Child Isolation

Children can **only** see their own data:
- `isChildOwner(childId)` checks that `getChildId() == childId`
- Children cannot query other children's buckets or transactions
- This prevents siblings from viewing each other's balances

---

## 9. Key Constants

All app-wide constants are defined in `lib/core/constants/app_constants.dart`.

| Constant | Value | Description |
|----------|-------|-------------|
| `pinLength` | 4 | Number of digits in a child's PIN |
| `pinMaxAttempts` | 5 | Max failed PIN attempts before lockout |
| `pinLockoutMinutes` | 15 | Duration of lockout after max attempts |
| `childSessionDays` | 30 | How long a child session lasts before re-authentication |
| `investmentMinMultiplier` | 0.01 | Minimum multiplier for investment bucket (must be > 0) |
| `transactionArchiveYears` | 1 | How old transactions must be before archiving |
| `bucketMoney` | "money" | String constant for money bucket type |
| `bucketInvestments` | "investments" | String constant for investments bucket type |
| `bucketCharity` | "charity" | String constant for charity bucket type |
| `roleParent` | "parent" | String constant for parent role |
| `roleChild` | "child" | String constant for child role |

**Usage:**
```dart
import 'package:kids_finance/core/constants/app_constants.dart';

if (pin.length != AppConstants.pinLength) {
  throw Exception('PIN must be ${AppConstants.pinLength} digits');
}
```

---

## 10. Design Patterns & Conventions

### Repository Pattern

**All Firestore access goes through repositories.** Features never import `cloud_firestore` directly—they depend on abstract repository interfaces.

**Example:**
```dart
// ❌ BAD: Direct Firestore access in a widget
final snapshot = await FirebaseFirestore.instance
    .collection('families')
    .doc(familyId)
    .collection('children')
    .get();

// ✅ GOOD: Use repository injected via provider
final repository = ref.read(childRepositoryProvider);
final children = await repository.getChildren(familyId);
```

**Benefits:**
- Testable (mock repositories in tests)
- Swappable (could switch to REST API or local DB)
- Single source of truth for queries

---

### Feature-First Folder Structure

Each feature is self-contained:
```
features/{feature_name}/
  domain/          ← Models, repository interfaces
  data/            ← Firestore/API implementations
  providers/       ← Riverpod providers
  presentation/    ← Screens and widgets (Phase 2)
```

**Rules:**
- Features can depend on `core/`
- Features **cannot** depend on other features (use core for shared code)
- Domain layer has no Flutter/Firebase imports (pure Dart)

---

### Freezed for Data Classes

**Not Yet Implemented** (Phase 1 used manual `copyWith` and `==`).

Phase 2 will migrate all domain models to Freezed:
```dart
@freezed
class Child with _$Child {
  const factory Child({
    required String id,
    required String familyId,
    required String displayName,
    // ...
  }) = _Child;
  
  factory Child.fromJson(Map<String, dynamic> json) => _$ChildFromJson(json);
}
```

---

### Error Handling

**Current State:**
- Auth errors are handled in `AuthService._handleAuthException()`
- Other errors are thrown as generic `Exception`

**Phase 2 TODO:**
- Define custom error types in `core/errors/`
- Use `sealed class` for exhaustive error handling:
  ```dart
  sealed class AppError {}
  class NetworkError extends AppError {}
  class AuthError extends AppError {}
  class ValidationError extends AppError { final String message; }
  ```

---

## 11. Testing Strategy

**Phase 1 Status:**
- No tests yet (focused on architecture setup)

**Phase 2 Plan:**
- Widget tests for all screens
- Unit tests for PinService (brute-force logic)
- Integration tests with Firebase Emulator (see Happy's test plan in `.squad/decisions.md`)

**P0 Tests (Release Blockers):**
- Auth flow (parent login → dashboard)
- Child PIN verification + brute-force lockout
- Bucket CRUD operations
- Security rules enforcement (child cannot write buckets)

---

## 12. Performance Considerations

### StreamProviders vs FutureProviders

**StreamProvider** is used for real-time data (buckets, children):
- Auto-updates widgets when Firestore data changes
- Best for dashboard screens

**FutureProvider** should be used for one-time fetches (transaction history pagination):
- Doesn't keep a persistent listener
- Better for large datasets

### Query Limits

- `recentTransactionsProvider` limits to 10 transactions (for dashboard performance)
- Full `transactionHistoryProvider` has no limit (use pagination in Phase 2)

### Firestore Indexes

**Required Composite Index:**
```
Collection: families/{familyId}/transactions
Fields: childId (ASC) + performedAt (DESC)
```

This allows efficient queries for "last 10 transactions for child X".

---

## 13. Next Steps (Phase 2)

Phase 1 (Architecture) is **complete**. See `docs/PHASE2_PLAN.md` for the detailed implementation roadmap.

**High-Level Goals:**
1. Build all screens (Login, Dashboards, PIN entry, Family Setup)
2. Wire GoRouter to real screens (replace stub screens)
3. Implement bucket actions (Set Money, Multiply Investment, Donate Charity)
4. Add celebration animations (investment multiply, charity donation)
5. End-to-end Firebase integration testing

**Key Decision Points for Phase 2:**
- Theme switching: how to toggle between kid/parent theme mid-session?
- Unseen celebration tracking: device-local flag or Firestore field?
- Navigation: bottom nav bar or drawer for parent dashboard?

---

## Appendix: Key Files Reference

| File | Purpose |
|------|---------|
| `lib/main.dart` | App entry point, Firebase init, ProviderScope setup |
| `lib/app.dart` | Root widget, GoRouter config, theme provider |
| `lib/routing/app_router.dart` | Route definitions, auth redirect logic |
| `lib/core/constants/app_constants.dart` | All app-wide constants |
| `lib/core/theme/app_theme.dart` | Kid theme + Parent theme definitions |
| `lib/features/auth/data/auth_service.dart` | Firebase Auth wrapper |
| `lib/features/auth/data/pin_service.dart` | PIN hashing, verification, brute-force protection |
| `lib/features/auth/providers/auth_providers.dart` | Auth state providers |
| `lib/features/buckets/providers/buckets_providers.dart` | Bucket state providers |
| `firestore.rules` | Firestore security rules |
| `.squad/decisions.md` | Team architectural decisions log |
| `docs/design/DESIGN_SYSTEM.md` | UI/UX specifications (screens, flows, animations) |

---

**Document Maintained by:** Stark (Tech Lead)  
**Last Review:** 2026-04-05  
**Next Review:** After Phase 2 completion
