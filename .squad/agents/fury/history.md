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

### 2026-04-05: Auth & Permission Architecture Design

**Designed complete authentication and authorization system for KidsFinance:**

1. **Two-tier auth approach:**
   - Parents: Email/password or Google Sign-In (verified adults)
   - Children: PIN-based (4-6 digits) for COPPA compliance (under 13, no email required)
   - Optional: Older children (13+) can link Google accounts with parent approval

2. **Role model using Firebase Custom Claims + Firestore:**
   - Custom claims in JWT provide offline rule enforcement (`role`, `familyId`, `childId`)
   - Firestore `/users/{uid}` documents serve as source of truth
   - Cloud Function syncs claims on role changes
   - Parent role: Full family CRUD access
   - Child role: Read-only access to own buckets only

3. **Firestore security rules enforce:**
   - Family isolation (users can only access their own familyId)
   - Parent-only write access to bucket balances
   - Parent-only multiplier and charity reset actions
   - Child read-only access with childId validation
   - No writes allowed for children at all

4. **Multi-parent support via email invitations:**
   - First parent creates family
   - Sends invite to second parent via Cloud Function
   - Invite link deep-links to app
   - Second parent authenticates and joins family with same familyId claim

5. **COPPA compliance by design:**
   - No email collection from children under 13
   - Only first name, age range, avatar selection collected
   - No location data, no photos, no social features
   - Parental consent implicit (parent creates child accounts)
   - Data deletion: "Delete Child" purges all data

6. **Top 3 security risks identified and mitigated:**
   - **Family isolation breach:** Custom claims + strict Firestore rules + server validation
   - **Child privilege escalation:** Explicit deny rules for child writes + Cloud Function role checks
   - **PIN brute-force:** Rate limiting (5 attempts/15min) + account lockout + bcrypt hashing

7. **Key architectural decisions:**
   - PIN stored as bcrypt hash in `/families/{familyId}/children/{childId}/pinHash`
   - Child Firebase Auth users created as anonymous with custom claims (no email)
   - All parent-only actions must validate `request.auth.token.role == "parent"` in Cloud Functions
   - Integration tests required for all cross-family and privilege escalation attempts

**Output:** Complete AUTH_ARCHITECTURE.md document ready for JARVIS implementation.

**Handoff to:** JARVIS (Backend) for Cloud Functions and Firestore rules implementation.

### 2026-04-05: Phase 1 Auth & Security Implementation Complete

**Implemented complete authentication and security layer for KidsFinance:**

1. **AuthService** (`lib/features/auth/data/auth_service.dart`):
   - Email/password authentication with Firebase Auth
   - Google Sign-In integration
   - Family creation with Firestore batch writes
   - Comprehensive error handling for all auth exceptions
   - Account creation, password reset, email verification

2. **PinService** (`lib/features/auth/data/pin_service.dart`):
   - bcrypt-based PIN hashing (4-6 digits)
   - Brute-force protection: 5 attempts, 15-minute lockout
   - Child session management via FlutterSecureStorage (30-day expiry)
   - Sealed class pattern for PinResult (success/wrongPin/locked)
   - Lockout state persistence across app restarts

3. **Auth Providers** (`lib/features/auth/providers/auth_providers.dart`):
   - Riverpod providers for auth state management
   - AppUserRole enum (parent/child/unauthenticated)
   - activeChildProvider for child session tracking
   - familyId and role resolution from Firestore userProfiles
   - Session validation provider per child

4. **Firestore Security Rules** (`firestore.rules`):
   - Complete production-ready rules with family isolation
   - Parent-only write access to all family data
   - Child read-only access to own buckets and transactions
   - Investment multiplier validation (must be >0)
   - Charity donation validation (newBalance must be 0)
   - Helper functions for role/family checking
   - Invitation system rules for multi-parent support

5. **Cloud Functions** (`functions/src/index.ts`):
   - onMultiplyInvestment: validates multiplier >0, atomic batch update
   - onDonateCharity: resets charity bucket to 0, creates transaction
   - onSetMoney: validates amount >=0, creates transaction
   - onSetCustomClaims: syncs JWT claims from Firestore userProfiles
   - All functions enforce parent-only access with role checks
   - Complete TypeScript implementation with proper error handling

6. **Auth Flow Screens** (Flutter UI stubs):
   - login_screen.dart: Email/password + Google sign-in (existing)
   - child_pin_screen.dart: 4-digit PIN entry with visual feedback (existing)
   - family_setup_screen.dart: First-time family name input

**Key Security Decisions:**
- PIN length: 4 digits (10,000 combinations, acceptable for children with rate limiting)
- Session duration: 30 days (balances UX with security)
- Lockout: 15 minutes after 5 failed attempts (prevents brute force without permanent lockout)
- Storage: FlutterSecureStorage for local session/lockout state, Firestore for PIN hash
- Custom claims: role, familyId, childId synced from Firestore to JWT for offline enforcement
- Investment multiplier: MUST be >0 (enforced in rules AND Cloud Functions)
- Charity donation: MUST set balance to 0 (enforced in rules)

**Files Created:**
- `lib/features/auth/data/auth_service.dart` (145 lines)
- `lib/features/auth/data/pin_service.dart` (177 lines)
- `lib/features/auth/providers/auth_providers.dart` (87 lines)
- `firestore.rules` (124 lines)
- `functions/src/index.ts` (304 lines)
- `functions/package.json` (TypeScript + Firebase deps)
- `functions/tsconfig.json` (TS compiler config)
- `functions/.eslintrc.json` (ESLint config)

**Dependencies Added:**
- Dart: bcrypt, flutter_secure_storage, firebase_auth, cloud_firestore, google_sign_in
- TypeScript: firebase-functions, firebase-admin

**Next Steps:**
- Integrate auth providers with routing (GoRouter auth redirect)
- Connect UI screens to actual auth/pin services
- Deploy Cloud Functions to Firebase
- Deploy Firestore rules
- Write integration tests for security boundaries

### 2026-04-05: Phase 1 Complete — Auth & Security Finalized
- **Status:** ✅ PHASE 1 AUTH & SECURITY FINALIZED
- AuthService: Email/password, Google Sign-In, family creation with batch writes
- PinService: bcrypt hashing (4-6 digits), 5-attempt brute-force, 15-min lockout, 30-day sessions
- Auth providers: authStateProvider, role/familyId/childId resolution from Firestore
- Firestore security rules (124 lines): Family isolation, parent-only writes, child read-only, validation enforcement
- Cloud Functions (304 lines TypeScript): onMultiplyInvestment, onDonateCharity, onSetMoney, onSetCustomClaims
- Multi-layer validation: JWT claims + Firestore rules + Cloud Functions
- COPPA compliance: No child email collection, implicit parental consent, data deletion support
- Security decisions locked in: PIN=4 digits, session=30 days, lockout=15 min, multiplier>0, charity→0
- **Orchestration Log:** `.squad/orchestration-log/2026-04-05T18-30-00Z-fury-auth.md`
- **Next:** Rhodey for UI connection, Happy for integration tests (SEC-001 through SEC-008)

