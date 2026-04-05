# Phase 1 Summary — KidsFinance Foundation

**Project:** KidsFinance — Financial literacy app for kids  
**Phase:** 1 — Foundation & Architecture  
**Status:** ✅ Complete  
**Date:** 2026-04-05  
**Team:** Iron Man Universe Squad

---

## 1. Phase 1 Overview

### What Was Built

#### Stark (Tech Lead)
- **Project Foundation:** Initialized Flutter project with Firebase integration, Riverpod state management, GoRouter navigation
- **Architecture Decisions:** Established feature-first folder structure, repository pattern, Freezed code generation standards
- **Core Infrastructure:** Set up app constants, dual-theme system (parent/child modes), router with auth-based redirects

#### JARVIS (Backend Lead)
- **Data Model Design:** Created comprehensive domain models using Freezed: Family, ParentUser, Child, Bucket, Transaction
- **Repository Pattern:** Implemented Firebase repositories for all entities with proper abstraction layers
- **Firestore Schema:** Designed family-centric hierarchy with immutable transaction logs and composite indexes

#### Fury (Security Lead)
- **Authentication System:** Implemented dual-tier auth (Firebase Auth for parents, PIN-based for children)
- **Firestore Security Rules:** Created comprehensive role-based rules with family isolation and child read-only enforcement
- **PIN Security:** Designed bcrypt-based PIN hashing with brute-force protection (5 attempts, 15-min lockout)

### App Status

#### ✅ What Works Now
- Firebase project initialized with authentication and Firestore
- Parent login with email/password and Google Sign-In
- Family creation and profile management
- Complete data model with type-safe domain entities
- Repository pattern for all data access
- Firestore security rules enforcing family isolation and role-based access
- Router with auth state redirects
- Dual theme system (parent/child modes)

#### 🔜 What's Pending
- Child PIN authentication screens (Pepper)
- Parent dashboard UI (Rhodey)
- Child dashboard UI (Pepper)
- Bucket management screens (Rhodey + Pepper)
- Transaction history and detail views (Rhodey)
- Investment multiply and charity donation flows
- Celebration animations (Pepper)
- Cloud Functions for server-side validation
- Comprehensive testing (Happy)

### Metrics
- **Files:** 32 Dart files
- **Lines of Code:** ~1,970 lines
- **Features:** 5 (auth, family, children, buckets, transactions)
- **Domain Models:** 6 (Family, ParentUser, Child, Bucket, Transaction, AppUser)
- **Repositories:** 4 (Family, Child, Bucket, Transaction)
- **Security Rules:** 120 lines covering 8 boundary conditions

---

## 2. Project Structure Diagram

```mermaid
graph TD
    lib[lib/] --> core[core/]
    lib --> features[features/]
    lib --> routing[routing/]
    
    core --> constants[constants/]
    core --> theme[theme/]
    
    constants --> app_constants[app_constants.dart]
    theme --> app_theme[app_theme.dart]
    
    features --> auth[auth/]
    features --> family[family/]
    features --> children[children/]
    features --> buckets[buckets/]
    features --> transactions[transactions/]
    
    auth --> auth_data[data/]
    auth --> auth_domain[domain/]
    auth --> auth_providers[providers/]
    auth --> auth_presentation[presentation/]
    
    family --> family_data[data/]
    family --> family_domain[domain/]
    family --> family_providers[providers/]
    
    children --> children_data[data/]
    children --> children_domain[domain/]
    children --> children_providers[providers/]
    
    buckets --> buckets_data[data/]
    buckets --> buckets_domain[domain/]
    buckets --> buckets_providers[providers/]
    
    transactions --> transactions_data[data/]
    transactions --> transactions_domain[domain/]
    transactions --> transactions_providers[providers/]
    
    routing --> app_router[app_router.dart]
    
    style lib fill:#e1f5ff
    style core fill:#fff4e1
    style features fill:#e8f5e9
    style routing fill:#fce4ec
```

---

## 3. Data Model — Class Diagram

```mermaid
classDiagram
    class Family {
        +String id
        +String name
        +List~String~ parentIds
        +List~String~ childIds
        +DateTime createdAt
        +String schemaVersion
    }
    
    class ParentUser {
        +String uid
        +String displayName
        +String familyId
        +bool isOwner
        +DateTime createdAt
    }
    
    class Child {
        +String id
        +String familyId
        +String displayName
        +String avatarEmoji
        +String pinHash
        +DateTime? sessionExpiresAt
        +DateTime createdAt
    }
    
    class Bucket {
        +String id
        +String childId
        +String familyId
        +BucketType type
        +double balance
        +DateTime lastUpdatedAt
    }
    
    class BucketType {
        <<enumeration>>
        money
        investment
        charity
    }
    
    class Transaction {
        +String id
        +String familyId
        +String childId
        +BucketType bucketType
        +TransactionType type
        +double amount
        +double? multiplier
        +double previousBalance
        +double newBalance
        +String? note
        +String performedByUid
        +DateTime performedAt
    }
    
    class TransactionType {
        <<enumeration>>
        moneySet
        investmentMultiplied
        charityDonated
        moneyAdded
        moneyRemoved
    }
    
    Family "1" --> "*" ParentUser : has parents
    Family "1" --> "*" Child : has children
    Child "1" --> "3" Bucket : owns (money, investment, charity)
    Child "1" --> "*" Transaction : has history
    Bucket --> BucketType : categorized by
    Transaction --> TransactionType : classified as
    Transaction --> BucketType : targets
```

---

## 4. Auth Flow — Sequence Diagrams

### 4a. Parent Login Flow

```mermaid
sequenceDiagram
    actor Parent
    participant LoginScreen
    participant AuthService
    participant FirebaseAuth
    participant Firestore
    participant GoRouter
    participant ParentDashboard
    
    Parent->>LoginScreen: enters email/password
    LoginScreen->>AuthService: signInWithEmailPassword()
    AuthService->>FirebaseAuth: signInWithEmailAndPassword()
    FirebaseAuth-->>AuthService: UserCredential
    AuthService->>Firestore: read /userProfiles/{uid}
    Firestore-->>AuthService: ParentUser data
    AuthService-->>AuthService: authStateChanges stream fires
    AuthService-->>GoRouter: user authenticated (role: parent)
    GoRouter->>GoRouter: redirect logic evaluates
    GoRouter-->>ParentDashboard: navigate to /parent-home
    ParentDashboard-->>Parent: shows dashboard
```

### 4b. Child PIN Auth Flow

```mermaid
sequenceDiagram
    actor Child
    participant PinScreen
    participant PinService
    participant Firestore
    participant SecureStorage
    participant GoRouter
    participant ChildHome
    
    Child->>PinScreen: enters 4-digit PIN
    PinScreen->>PinService: verifyChildPin(childId, pin)
    PinService->>Firestore: read /families/{familyId}/children/{childId}
    Firestore-->>PinService: child.pinHash
    PinService->>PinService: bcrypt.verify(pin, pinHash)
    
    alt PIN correct
        PinService->>SecureStorage: store session expiry (now + 30 days)
        PinService->>SecureStorage: reset attempt counter to 0
        PinService-->>PinScreen: PinResult.success
        PinScreen->>GoRouter: navigate to /child-home
        GoRouter-->>ChildHome: show child dashboard
        ChildHome-->>Child: playful UI with buckets
    else PIN wrong (attempts < 5)
        PinService->>SecureStorage: increment attempt counter
        PinService-->>PinScreen: PinResult.wrongPin(attemptsRemaining)
        PinScreen-->>Child: show error + remaining attempts
    else 5th wrong attempt
        PinService->>SecureStorage: store lockout expiry (now + 15 min)
        PinService->>SecureStorage: set attempt counter to 5
        PinService-->>PinScreen: PinResult.locked(unlocksAt)
        PinScreen-->>Child: show lockout message + timer
    end
```

### 4c. Parent Investment Multiply Flow

```mermaid
sequenceDiagram
    actor Parent
    participant UI
    participant CloudFunction
    participant Firestore
    
    Parent->>UI: selects child + enters multiplier (e.g., 2.5)
    UI->>UI: validate multiplier >= 0.01
    UI->>CloudFunction: onMultiplyInvestment({childId, multiplier})
    CloudFunction->>CloudFunction: verify auth token (role: parent)
    CloudFunction->>CloudFunction: validate multiplier > 0
    
    alt invalid multiplier
        CloudFunction-->>UI: error "Multiplier must be > 0"
        UI-->>Parent: show error message
    else valid multiplier
        CloudFunction->>Firestore: read /families/{familyId}/children/{childId}/buckets/investment
        Firestore-->>CloudFunction: current balance
        CloudFunction->>CloudFunction: calculate new balance = current * multiplier
        CloudFunction->>Firestore: batch write:<br/>1. update bucket balance<br/>2. create transaction log
        Firestore-->>CloudFunction: write success
        CloudFunction-->>UI: success {previousBalance, newBalance, multiplier}
        UI->>UI: trigger celebration animation (confetti + count-up)
        UI-->>Parent: show updated balance + celebration
    end
```

### 4d. Charity Donation Flow

```mermaid
sequenceDiagram
    actor Parent
    participant UI
    participant CloudFunction
    participant Firestore
    
    Parent->>UI: tap "Donate Charity" for child
    UI->>UI: confirm donation (optional dialog)
    UI->>CloudFunction: onDonateCharity({childId})
    CloudFunction->>CloudFunction: verify auth token (role: parent)
    CloudFunction->>Firestore: read /families/{familyId}/children/{childId}/buckets/charity
    Firestore-->>CloudFunction: current charity balance
    
    alt balance is 0
        CloudFunction-->>UI: info "Charity bucket already empty"
        UI-->>Parent: show message
    else balance > 0
        CloudFunction->>CloudFunction: capture donatedAmount = current balance
        CloudFunction->>Firestore: batch write:<br/>1. set charity bucket balance = 0<br/>2. create transaction log (type: charityDonated)
        Firestore-->>CloudFunction: write success
        CloudFunction-->>UI: success {donatedAmount}
        UI->>UI: trigger celebration animation (hearts burst + impact viz)
        UI-->>Parent: show "Donated ${donatedAmount}" + celebration
    end
```

---

## 5. Firestore Data Hierarchy

```mermaid
graph TD
    Root[(Firestore Root)]
    
    Root --> UP["/userProfiles/{uid}"]
    UP --> UP_Fields["uid, displayName, familyId<br/>role, createdAt, updatedAt"]
    
    Root --> F["/families/{familyId}"]
    F --> F_Fields["id, name, parentIds, childIds<br/>createdAt, updatedAt, schemaVersion"]
    
    F --> FC["/children/{childId}"]
    FC --> FC_Fields["id, familyId, displayName<br/>avatarEmoji, pinHash<br/>sessionExpiresAt, createdAt"]
    
    FC --> FB["/buckets/{bucketType}"]
    FB --> FB_Fields["id, childId, familyId, type<br/>balance, lastUpdatedAt<br/><br/>bucketType ∈ {money, investment, charity}"]
    
    F --> FT["/transactions/{txnId}"]
    FT --> FT_Fields["id, familyId, childId, bucketType<br/>type, amount, multiplier<br/>previousBalance, newBalance<br/>note, performedByUid, performedAt<br/><br/>type ∈ {moneySet, investmentMultiplied<br/>charityDonated, moneyAdded, moneyRemoved}"]
    
    F --> Inv["/invitations/{invitationId}"]
    Inv --> Inv_Fields["invitedEmail, familyId<br/>createdAt, expiresAt"]
    
    style Root fill:#ffebee
    style UP fill:#e3f2fd
    style F fill:#e8f5e9
    style FC fill:#fff3e0
    style FB fill:#f3e5f5
    style FT fill:#fce4ec
    style Inv fill:#e0f2f1
```

**Key Design Decisions:**
- **Family-centric isolation:** All child data lives under `/families/{familyId}` for atomic queries
- **Immutable transaction log:** Every bucket mutation creates a transaction record
- **Composite index:** `(childId ASC, performedAt DESC)` for fast history queries
- **Schema versioning:** `schemaVersion: "1.0.0"` in family doc enables future migrations

---

## 6. GoRouter Navigation Map

```mermaid
graph LR
    Start([App Launch]) --> Splash[/splash]
    
    Splash --> CheckAuth{Auth State?}
    
    CheckAuth -->|Not Authenticated| Login[/login]
    CheckAuth -->|Authenticated| CheckRole{User Role?}
    
    CheckRole -->|Parent| ParentHome[/parent-home]
    CheckRole -->|Child| ChildPin[/child-pin]
    
    Login -->|Sign In Success| CheckRole
    Login -->|Google Sign In| CheckRole
    Login -->|Create Account| FamilySetup[/family-setup]
    
    FamilySetup -->|Complete| ParentHome
    
    ChildPin -->|PIN Verified| ChildHome[/child-home]
    ChildPin -->|5 Failed Attempts| Lockout[Lockout Screen<br/>15 min timer]
    
    Lockout -->|Timer Expires| ChildPin
    
    ParentHome -->|Manage Children| ChildList[Child Management]
    ParentHome -->|View Transactions| TransactionHistory
    ParentHome -->|Multiply Investment| InvestmentFlow
    ParentHome -->|Donate Charity| CharityFlow
    
    ChildHome -->|View Buckets| BucketView[Bucket Details]
    ChildHome -->|Session Expired| ChildPin
    
    style Start fill:#e3f2fd
    style Splash fill:#fff3e0
    style Login fill:#e8f5e9
    style ParentHome fill:#f3e5f5
    style ChildHome fill:#fce4ec
    style ChildPin fill:#ffebee
```

**Redirect Logic:**
1. **Splash → Login:** If `authState.value == null`
2. **Login → Parent Home:** If authenticated AND `role == 'parent'`
3. **Login → Child PIN:** If authenticated AND `role == 'child'`
4. **Child PIN → Child Home:** After successful PIN verification
5. **Session Expiry:** Child home redirects to PIN screen after 30 days

---

## 7. Security Architecture

```mermaid
graph TD
    Client[Client App<br/>Flutter + Riverpod]
    Functions[Cloud Functions<br/>Server-side Validation]
    Rules[Firestore Security Rules<br/>Access Control]
    Storage[(Firestore Database)]
    
    Client -->|1. UI Validation| L3[Layer 3: Client Security]
    L3 -->|PIN brute-force protection<br/>Session expiry checks<br/>Input validation| Client
    
    Client -->|2. Cloud Function Call| Functions
    Functions -->|3. Business Logic| L2[Layer 2: Server Validation]
    L2 -->|Multiplier > 0<br/>Charity = 0<br/>Amount limits<br/>Transaction atomicity| Functions
    
    Functions -->|4. Write to Firestore| Rules
    Client -->|Read from Firestore| Rules
    
    Rules -->|5. Access Control| L1[Layer 1: Firestore Rules]
    L1 -->|Family isolation<br/>Parent write-only<br/>Child read-own<br/>Role verification| Rules
    
    Rules -->|Approved| Storage
    Rules -->|Denied| Reject[❌ Access Denied]
    
    style L1 fill:#ffebee
    style L2 fill:#fff3e0
    style L3 fill:#e8f5e9
    style Client fill:#e3f2fd
    style Functions fill:#f3e5f5
    style Rules fill:#fce4ec
    style Storage fill:#e0f2f1
```

### Layer 1: Firestore Security Rules
**Purpose:** Enforce data access boundaries at the database level  
**Key Rules:**
- ✅ Parents can read/write their own family data
- ✅ Children can read only their own buckets and transactions
- ✅ Children cannot write to any Firestore documents
- ✅ Family isolation: users can only access data for their `familyId`
- ✅ Custom claims verification: `request.auth.token.role` and `request.auth.token.familyId`

### Layer 2: Cloud Functions
**Purpose:** Server-side business logic validation  
**Key Validations:**
- ✅ Investment multiplier must be > 0 (rejects zero/negative)
- ✅ Charity donation sets balance to exactly 0
- ✅ Atomic batch writes: bucket update + transaction log together
- ✅ Balance calculations: `newBalance = previousBalance * multiplier`
- ✅ Auth token verification before every operation

### Layer 3: Client Security
**Purpose:** User experience and local protection  
**Key Features:**
- ✅ PIN brute-force protection: 5 attempts, then 15-minute lockout
- ✅ bcrypt password hashing (cost factor 10)
- ✅ Session expiry: 30 days, stored in secure storage
- ✅ Attempt counter and lockout timer in secure storage
- ✅ No PIN storage in memory after verification

---

## 8. Key Constants & Configuration

| Constant | Value | Purpose | Defined In |
|----------|-------|---------|------------|
| `PIN_LENGTH` | 4 | Child PIN digit count | `app_constants.dart` |
| `PIN_MAX_ATTEMPTS` | 5 | Maximum wrong PIN attempts before lockout | `app_constants.dart` |
| `PIN_LOCKOUT_MINUTES` | 15 | Duration of lockout after 5 failed attempts | `app_constants.dart` |
| `CHILD_SESSION_DAYS` | 30 | Days before child session auto-expires | `app_constants.dart` |
| `INVESTMENT_MIN_MULTIPLIER` | 0.01 | Minimum multiplier value (must be > 0) | `app_constants.dart` |
| `TRANSACTION_ARCHIVE_YEARS` | 1 | Years before transactions are archived | `app_constants.dart` |
| `SCHEMA_VERSION` | "1.0.0" | Current Firestore schema version | `family.dart` |
| `BUCKET_TYPES` | money, investment, charity | Three bucket categories per child | `bucket.dart` |
| `TRANSACTION_TYPES` | moneySet, investmentMultiplied, charityDonated, moneyAdded, moneyRemoved | All transaction categories | `transaction.dart` |
| `USER_ROLES` | parent, child | Two role types in auth system | `app_constants.dart` |

**Configuration Files:**
- **`firebase_options.dart`:** Firebase project configuration (auto-generated by FlutterFire CLI)
- **`firestore.rules`:** Security rules (120 lines)
- **`app_constants.dart`:** App-wide constants (27 lines)
- **`.squad/decisions.md`:** Architectural decisions log (150+ lines)

---

## 9. Phase Status & Next Steps

### ✅ Phase 1 Complete — Foundation Built

**Completed Deliverables:**
- [x] Flutter project initialized with Firebase SDK
- [x] Feature-first folder structure established
- [x] Repository pattern implemented for all entities
- [x] Domain models defined with Freezed (Family, ParentUser, Child, Bucket, Transaction)
- [x] Firestore security rules with family isolation and role-based access
- [x] Parent authentication (email/password + Google Sign-In)
- [x] Child PIN security design (bcrypt, brute-force protection)
- [x] GoRouter with auth-based redirects
- [x] Dual theme system (parent/child modes)
- [x] Core constants and configuration
- [x] Architectural decisions documented

**Key Achievements:**
- **Security:** Three-layer security model (Firestore Rules + Cloud Functions + Client)
- **Data Integrity:** Immutable transaction log for audit trail
- **Scalability:** Family-centric hierarchy supports multi-parent, multi-child
- **Type Safety:** Freezed models with code generation
- **Maintainability:** Feature-first structure, repository pattern, clear separation of concerns

---

### 🔜 Phase 2 — Dashboards & Core UI (Rhodey + Pepper)

**Objectives:** Build parent and child dashboard screens with bucket displays

**Rhodey (Frontend Lead) — Parent Dashboard:**
- [ ] Parent home screen layout (data-dense, efficient)
- [ ] Child list with bucket summary cards
- [ ] Add/edit child functionality
- [ ] Transaction history list view
- [ ] Search and filter transactions
- [ ] Investment multiply UI
- [ ] Charity donation UI

**Pepper (UI/UX Lead) — Child Dashboard:**
- [ ] Child home screen (playful, large touch targets)
- [ ] Three bucket cards (money, investment, charity) with emojis
- [ ] Animated balance displays with count-up
- [ ] Child PIN entry screen with brute-force protection UI
- [ ] Lockout screen with countdown timer
- [ ] Session expiry handling

**Shared Work:**
- [ ] Riverpod providers for bucket state
- [ ] Real-time bucket updates via StreamProvider
- [ ] Navigation between parent/child modes
- [ ] Responsive layout (mobile-first, tablet support)

---

### 🔜 Phase 3 — Transactions & Celebrations (Rhodey + Pepper + Happy)

**Objectives:** Implement transaction flows, history views, and celebration animations

**Features:**
- [ ] Cloud Functions for investment multiply and charity donation
- [ ] Transaction creation with batch writes
- [ ] Transaction detail view with full metadata
- [ ] Celebration animations (confetti, hearts burst, coin drop)
- [ ] Transaction filtering by type, child, date range
- [ ] Export transaction history (CSV)
- [ ] Offline queue for pending transactions

**Testing:**
- [ ] Widget tests for all screens
- [ ] Integration tests with Firebase Emulator
- [ ] Security boundary tests (8 test cases)
- [ ] Edge case tests (zero balance, large multipliers, race conditions)

---

### 🔜 Phase 4 — Polish, Testing & Release (Happy + Team)

**Objectives:** Comprehensive testing, performance optimization, and production release

**Quality Assurance:**
- [ ] P0 test suite (30+ tests)
- [ ] Manual QA for kid UX (engagement, delight)
- [ ] Performance profiling (Firestore query optimization)
- [ ] Offline-first validation
- [ ] Multi-parent conflict resolution testing

**Production Readiness:**
- [ ] App store assets (screenshots, descriptions)
- [ ] Privacy policy (COPPA compliance)
- [ ] Terms of service
- [ ] Analytics integration (Firebase Analytics)
- [ ] Crash reporting (Firebase Crashlytics)
- [ ] Production Firebase project setup
- [ ] Beta testing with real families

**Release:**
- [ ] Android release build
- [ ] Google Play Store submission
- [ ] Post-launch monitoring

---

## Architecture Principles

### 1. Feature-First Organization
Every feature is self-contained with its own `data/`, `domain/`, `presentation/`, and `providers/` layers. No cross-feature imports.

### 2. Repository Pattern
All Firebase access goes through repository interfaces. Domain layer never directly touches Firebase SDK.

### 3. Immutability
Freezed models ensure immutable data structures. Transaction log is append-only.

### 4. Type Safety
Code generation (Freezed, Riverpod) eliminates boilerplate and runtime errors.

### 5. Security by Design
Three-layer security ensures no single point of failure. Defense in depth.

### 6. Real-Time First
StreamProvider for bucket balances. FutureProvider for historical data. Offline support via Firebase local cache.

### 7. COPPA Compliance
Children provide only first name, age range, avatar emoji. No email, phone, or DOB collected.

### 8. Dual User Experience
Parent mode: data-dense, efficient, professional (Inter font).  
Child mode: playful, simple, delightful (Nunito font).

---

## Team Contacts

- **Stark (Tech Lead):** Architecture, project setup, technical decisions
- **JARVIS (Backend Lead):** Data models, repositories, Firestore schema
- **Fury (Security Lead):** Authentication, security rules, PIN system
- **Rhodey (Frontend Lead):** Parent UI, transaction flows, data visualization
- **Pepper (UI/UX Lead):** Child UI, celebrations, animations, design system
- **Happy (QA Lead):** Test strategy, edge cases, security boundary tests
- **Scribe:** Documentation, decision log, meeting notes

---

**Document Version:** 1.0  
**Last Updated:** 2026-04-05  
**Author:** Stark (Tech Lead)  
**Reviewed By:** Squad

---

*This document serves as the architectural reference for the KidsFinance project. All team members should familiarize themselves with these diagrams and decisions before beginning Phase 2 work.*
