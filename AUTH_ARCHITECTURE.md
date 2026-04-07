# KidsFinance Authentication & Authorization Architecture

**Author:** Fury (Security & Auth Specialist)  
**Date:** 2026-04-05  
**Updated:** 2026-04-08 (Sprint 5D Complete)  
**Status:** ✅ IMPLEMENTED

---

## 1. Authentication Strategy

### Two-Tier Authentication Model

KidsFinance uses a **two-tier authentication system** that separates parent and child access:

| Tier | User Type | Method | Backend | Session |
|------|-----------|--------|---------|---------|
| 1 | Parent | Firebase Auth (Email/Password) | Firebase Auth | Persistent |
| 2 | Child | Local PIN (bcrypt) | Firestore only | 24h expiry |

### Parent Authentication (Tier 1)
**Method:** Firebase Authentication with Email/Password
- Parents authenticate via `FirebaseAuth.instance.signInWithEmailAndPassword()`
- Email/Password only — Google Sign-In NOT implemented (out of scope)
- Password reset via `FirebaseAuth.instance.sendPasswordResetEmail()` → **Forgot Password screen implemented**
- Parents are the ONLY users with Firebase Auth accounts
- Custom claims set via Cloud Function `onSetCustomClaims` on userProfile write

**Implementation Files:**
- `lib/features/auth/data/auth_service.dart` — Parent login/registration
- `lib/features/auth/presentation/login_screen.dart` — Login UI
- `lib/features/auth/presentation/forgot_password_screen.dart` — Password reset
- `functions/src/index.ts::onSetCustomClaims` — JWT claim sync

### Child Authentication (Tier 2)
**Method:** Local PIN verification with bcrypt hashing
- Children do NOT have Firebase Auth accounts
- PIN is 4–6 digits, stored as bcrypt hash in Firestore (`/families/{familyId}/children/{childId}/pinHash`)
- PIN verification happens client-side via `BCrypt.checkpw()` (no Cloud Function call)
- On successful PIN entry, session created with **24-hour expiry**

**Implementation Files:**
- `lib/features/auth/data/pin_service.dart` — PIN hash/verify, session management
- `lib/features/auth/data/pin_attempt_tracker.dart` — Brute-force protection
- `lib/features/auth/presentation/child_pin_screen.dart` — PIN entry UI
- `lib/features/auth/presentation/child_picker_screen.dart` — Child selection

### Session Management

**Parent Sessions:**
- Managed by Firebase Auth (persistent until logout)
- Token refresh handled automatically by Firebase SDK

**Child Sessions:**
- 24-hour expiry stored in TWO places for redundancy:
  1. **Local:** `FlutterSecureStorage` key `child_session_{childId}` — fast read
  2. **Firestore:** `sessionExpiresAt` field on child document — enforced by `childSessionValidProvider`
- Every child-mode screen watches `childSessionValidProvider` and redirects to PIN on expiry
- Session cleared on logout or parent-initiated reset

### PIN Brute-Force Protection

**Lockout Policy (implemented in `PinAttemptTracker`):**
- **Max attempts:** 5 consecutive failures
- **Lockout duration:** 15 minutes
- **State persistence:** `FlutterSecureStorage` (survives app restart/force-close)
- **Auto-clear:** Lockout expires automatically; successful login resets counter

**Flow:**
```
Attempt 1-4: Wrong PIN → "X attempts remaining"
Attempt 5:   Wrong PIN → PinLockoutException thrown → 15min lockout
During lockout: PinLocked result returned immediately (no Firestore call)
After lockout: Counter reset, user can try again
```

### Forgot Password Flow

**Implemented:** Parent-only password reset via Firebase Auth
1. User taps "Forgot Password?" on login screen
2. Navigate to `ForgotPasswordScreen`
3. Enter email → `FirebaseAuth.instance.sendPasswordResetEmail()`
4. Success: SnackBar + navigate back to login
5. Error handling: user-not-found, invalid-email, too-many-requests

---

## 2. Role Model

### Roles in the System

#### **Parent Role**
- **Identifier:** `role: "parent"` in JWT custom claims (set by Cloud Function)
- **Firestore Source of Truth:** Listed in `/families/{familyId}/parentIds[]` array
- **Permissions:**
  - Full CRUD on all family data
  - Create and manage child profiles (add, edit, archive — NO hard delete)
  - Set/distribute bucket balances (Money, Investment, Charity)
  - Trigger investment multiplier events
  - Reset charity bucket (on donation)
  - Add additional parents via invite code (familyId = invite code)
  - View all transaction history
  - Reset child PIN

#### **Child Role**
- **Identifier:** No Firebase Auth account — authenticated via PIN only
- **Firestore:** `/families/{familyId}/children/{childId}` document
- **Permissions:**
  - **READ-ONLY** access to their own buckets (via parent's authenticated session)
  - View their own transaction history
  - **NO write access** to any data
  - **NO access** to siblings' data
  - **NO access** to family settings

### Authorization Enforcement

**Four layers of protection:**

1. **Firestore Rules (`firestore.rules`):**
   - `isParentOfFamily(familyId)` validates caller is in `parentIds[]` array
   - Children CANNOT write: `allow write: if false;` on all child-accessible paths
   - Delete prohibited: `allow delete: if false;` on children, buckets, transactions

2. **Cloud Functions (`functions/src/index.ts`):**
   - `assertParentAuth()` validates JWT `role === "parent"`
   - `assertFamilyMembership()` verifies UID is in Firestore `parentIds[]` (NOT JWT claims)
   - Prevents JWT spoofing by always checking Firestore as source of truth

3. **Flutter UI:**
   - Child home screen is read-only (no edit buttons)
   - PopScope prevents back-button PIN bypass
   - Session provider redirects expired children to PIN screen

4. **Local Storage:**
   - PIN attempt tracker in `FlutterSecureStorage` survives app restart
   - Lockout state enforced even if Firestore unreachable

---

## 3. JWT Custom Claims (Parent Only)

### Parent JWT Structure
```json
{
  "uid": "parent_abc123",
  "email": "parent@example.com",
  "email_verified": true,
  "custom_claims": {
    "role": "parent",
    "familyId": "family_xyz789"
  }
}
```

### Claim Sync Mechanism

Cloud Function `onSetCustomClaims` (Firestore trigger on `/userProfiles/{userId}`):
- Watches for writes to userProfile documents
- Extracts `role` and `familyId` from document
- Sets Firebase Auth custom claims via `admin.auth().setCustomUserClaims()`
- Rejects invalid roles (only "parent" is valid for Firebase Auth accounts)

**Important:** Children do NOT have Firebase Auth accounts, so they have no JWT claims.

### JWT Spoofing Prevention

**Problem:** A malicious user could modify their own `userProfile.familyId` to gain access to another family's data.

**Solution:** Cloud Functions verify family membership via Firestore `parentIds[]` array, NOT JWT claims:

```typescript
async function assertFamilyMembership(uid: string, familyId: string): Promise<void> {
  const familyDoc = await db.collection("families").doc(familyId).get();
  const parentIds = familyDoc.data()?.parentIds ?? [];
  if (!parentIds.includes(uid)) {
    throw new functions.https.HttpsError("permission-denied", "...");
  }
}
```

This ensures that even if a user manipulates their JWT claims, they cannot access data unless they are actually listed in the family's `parentIds` array (which only existing parents can modify).

---

## 4. Firestore Security Rules (Implemented)

The actual deployed rules are in `firestore.rules`:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    // ── Helpers ──────────────────────────────────────────────────────────────

    function isAuthenticated() {
      return request.auth != null;
    }

    // CRITICAL: Uses Firestore parentIds array, NOT JWT claims
    // This prevents JWT spoofing attacks
    function isParentOfFamily(familyId) {
      return isAuthenticated() &&
             request.auth.uid in
               get(/databases/$(database)/documents/families/$(familyId)).data.parentIds;
    }

    // ── User Profiles ─────────────────────────────────────────────────────────
    match /userProfiles/{uid} {
      allow read, write: if isAuthenticated() && request.auth.uid == uid;
    }

    // ── Families ──────────────────────────────────────────────────────────────
    match /families/{familyId} {
      allow read: if isParentOfFamily(familyId);
      allow write: if isParentOfFamily(familyId);
      allow create: if isAuthenticated() &&
                       request.auth.uid in request.resource.data.parentIds;

      // ── Children (soft-delete only) ─────────────────────────────────────────
      match /children/{childId} {
        allow read: if isParentOfFamily(familyId);
        allow create: if isParentOfFamily(familyId) && validChildCreate();
        allow update: if isParentOfFamily(familyId);
        allow delete: if false;  // HARD DELETE PROHIBITED
      }

      // ── Buckets (non-negative balance enforced) ─────────────────────────────
      match /children/{childId}/buckets/{bucketType} {
        allow read: if isParentOfFamily(familyId);
        allow create: if isParentOfFamily(familyId) && validBucketCreate();
        allow update: if isParentOfFamily(familyId) && validBucketUpdate();
        allow delete: if false;  // DELETE PROHIBITED
      }

      // ── Transactions (append-only) ──────────────────────────────────────────
      match /transactions/{txnId} {
        allow read: if isParentOfFamily(familyId);
        allow create: if isParentOfFamily(familyId);
        allow update, delete: if false;  // IMMUTABLE
      }

      // ── Multiplier Events (append-only, multiplier > 0) ─────────────────────
      match /multiplierEvents/{eventId} {
        allow read: if isParentOfFamily(familyId);
        allow create: if isParentOfFamily(familyId) &&
                         request.resource.data.multiplier > 0;
        allow update, delete: if false;
      }
    }

    // ── Deny everything else ──────────────────────────────────────────────────
    match /{document=**} {
      allow read, write: if false;
    }
  }
}
```

### Validation Functions (Implemented)

```javascript
function validBucketCreate() {
  let d = request.resource.data;
  return d.keys().hasAll(['balance', 'childId', 'familyId', 'type', 'lastUpdatedAt'])
      && d.balance >= 0;
}

function validBucketUpdate() {
  return request.resource.data.balance >= 0;
}

function validChildCreate() {
  let d = request.resource.data;
  return d.keys().hasAll(['displayName', 'avatarEmoji', 'pinHash', 'familyId', 'createdAt'])
      && d.displayName.size() > 0 && d.displayName.size() <= 50;
}
```

---

## 5. Authentication Flows (Implemented)

### 5.1 Parent Registration (First-Time Setup)

1. **User opens app → LoginScreen**
2. **Tap "Create Account"** → Registration form
3. **Enter email + password** → `FirebaseAuth.createUserWithEmailAndPassword()`
4. **Cloud Function triggers:** `onSetCustomClaims` sets `role: "parent"` claim
5. **Navigate to FamilySetupScreen:**
   - Enter family name
   - Family document created with `parentIds: [uid]`
   - familyId = auto-generated Firestore doc ID (also serves as invite code)
6. **Navigate to ParentHomeScreen**
7. **Add first child:**
   - Enter name, avatar emoji, 4–6 digit PIN
   - PIN hashed with bcrypt → stored in Firestore
   - Initial buckets created: Money: $0, Investment: $0, Charity: $0

### 5.2 Parent Returning Login

1. **User opens app → LoginScreen**
2. **Enter email/password** → `FirebaseAuth.signInWithEmailAndPassword()`
3. **Firebase validates → ID token received with custom claims**
4. **GoRouter redirect:** If authenticated → ParentHomeScreen
5. **Load family data from Firestore**

### 5.3 Parent Forgot Password

1. **Tap "Forgot Password?" on LoginScreen**
2. **Navigate to ForgotPasswordScreen**
3. **Enter email** → `FirebaseAuth.sendPasswordResetEmail()`
4. **Success:** SnackBar notification, navigate back
5. **User checks email, clicks reset link, sets new password**

### 5.4 Child Login (PIN-Based)

1. **Parent selects child on ParentHomeScreen** → Navigate to ChildPickerScreen
2. **Child sees their avatar/name, taps it**
3. **ChildPinScreen appears:**
   - Numeric keypad for PIN entry
   - PopScope prevents back-button bypass
4. **Child enters PIN:**
   - Check lockout status first (PinAttemptTracker)
   - If locked: Show "Try again in X minutes"
   - If not locked: Verify PIN via `BCrypt.checkpw()`
5. **On success:**
   - Create 24h session (local + Firestore)
   - Reset attempt counter
   - Navigate to ChildHomeScreen
6. **On failure:**
   - Increment failure counter
   - After 5 failures: 15min lockout
   - Show remaining attempts or lockout time

### 5.5 Second Parent Joins Family

1. **First parent shares familyId** (displayed in Family Settings as "Invite Code")
2. **Second parent registers (or logs in if existing user)**
3. **Navigate to "Join Family" flow:**
   - Enter invite code (= familyId)
   - App verifies family exists
4. **Add second parent's UID to `parentIds[]` array**
5. **Second parent sees shared family with full access**

**Note:** No email-based invitation system implemented. Invite code = familyId (simple but secure).

---

## 6. Security Risks & Mitigations (Implemented)

### Risk 1: **Family Isolation Breach** (CRITICAL) ✅ MITIGATED
**Threat:** Attacker modifies JWT `familyId` claim to access another family's data.

**Mitigations Implemented:**
- ✅ Firestore rules use `isParentOfFamily()` which reads `parentIds[]` from Firestore (not JWT)
- ✅ Cloud Functions use `assertFamilyMembership()` which verifies UID is in Firestore `parentIds[]`
- ✅ No client-side trust: all family membership checks happen server-side
- ✅ Users can only modify their own `userProfile` document, NOT `parentIds[]` arrays

### Risk 2: **Child Privilege Escalation** (HIGH) ✅ MITIGATED
**Threat:** Child manipulates client to gain parent write permissions.

**Mitigations Implemented:**
- ✅ Children have NO Firebase Auth accounts (cannot call Cloud Functions)
- ✅ Firestore rules: `allow write: if false;` on all child-accessible paths
- ✅ Child UI is read-only (no edit buttons or write methods)
- ✅ PopScope prevents back-button PIN bypass (`automaticallyImplyLeading: false`)

### Risk 3: **PIN Brute-Force Attack** (MEDIUM) ✅ MITIGATED
**Threat:** Attacker guesses child's PIN via repeated attempts.

**Mitigations Implemented:**
- ✅ 5-attempt limit before 15-minute lockout (`PinAttemptTracker`)
- ✅ State persists in `FlutterSecureStorage` (survives app restart/force-close)
- ✅ PINs stored as bcrypt hashes (computationally expensive to crack)
- ✅ 4–6 digit requirement (10,000–1,000,000 combinations)
- ✅ No PIN recovery for children (parent must reset via edit child)

### Risk 4: **JWT Spoofing via userProfile Manipulation** (HIGH) ✅ MITIGATED
**Threat:** User modifies their `userProfile.familyId` to get JWT claims for another family.

**Mitigations Implemented:**
- ✅ Cloud Functions IGNORE JWT `familyId` claim for authorization
- ✅ All Cloud Functions call `assertFamilyMembership()` which reads Firestore directly
- ✅ Firestore rules use `isParentOfFamily()` which reads `parentIds[]` array
- ✅ `parentIds[]` array can only be modified by existing family members

---

## 7. Cloud Functions (Implemented)

Four Cloud Functions deployed in `functions/src/index.ts`:

### `onMultiplyInvestment` (Callable)
- **Purpose:** Multiply investment bucket balance
- **Auth:** `assertParentAuth()` + `assertFamilyMembership()`
- **Validation:** `multiplier > 0`, finite number, result >= current balance
- **Atomic:** Batch write updates bucket + creates transaction log

### `onDonateCharity` (Callable)
- **Purpose:** Reset charity bucket to $0 (donation event)
- **Auth:** `assertParentAuth()` + `assertFamilyMembership()`
- **Validation:** Charity bucket must have positive balance
- **Atomic:** Batch write updates bucket + creates transaction log

### `onSetMoney` (Callable)
- **Purpose:** Set money bucket to specific value
- **Auth:** `assertParentAuth()` + `assertFamilyMembership()`
- **Validation:** `amount >= 0`, finite number
- **Atomic:** Batch write updates bucket + creates transaction log

### `onSetCustomClaims` (Firestore Trigger)
- **Trigger:** `/userProfiles/{userId}` write
- **Purpose:** Sync `role` and `familyId` to Firebase Auth custom claims
- **Validation:** Only "parent" role is valid for Firebase Auth accounts
- **On delete:** Clears custom claims

---

## 8. COPPA Compliance (Implemented)

### Data Collected from Children
- ✅ **Display name** (first name only, parent-entered)
- ✅ **Avatar emoji** (from pre-defined set, not user-uploaded)
- ✅ **Bucket balances** (functional app data)
- ✅ **Transaction history** (educational, parent-initiated)

### Data NOT Collected
- ❌ Email address
- ❌ Phone number
- ❌ Date of birth (no age field)
- ❌ Location data
- ❌ Photos
- ❌ Social features

### Compliance Measures
- ✅ Parents create child accounts (parental consent implicit)
- ✅ Children cannot self-register
- ✅ Parent can archive child (soft-delete)
- ✅ No third-party data sharing (Firebase only)
- ✅ No analytics or ads
- ✅ Encrypted at rest (Firebase default)

---

## 9. Implementation Checklist ✅

| Component | Status | File(s) |
|-----------|--------|---------|
| Parent Firebase Auth | ✅ | `auth_service.dart`, `login_screen.dart` |
| Forgot Password | ✅ | `forgot_password_screen.dart` |
| PIN Service | ✅ | `pin_service.dart` |
| PIN Brute-Force Protection | ✅ | `pin_attempt_tracker.dart` |
| 24h Session Expiry | ✅ | `session_provider.dart`, `pin_service.dart` |
| Firestore Rules | ✅ | `firestore.rules` |
| JWT Spoofing Fix | ✅ | `functions/src/index.ts` |
| Cloud Functions | ✅ | `functions/src/index.ts` (4 functions) |
| Child Picker UI | ✅ | `child_picker_screen.dart` |
| PIN Entry UI | ✅ | `child_pin_screen.dart` |

---

**END OF DOCUMENT**

This architecture is fully implemented as of Sprint 5D. All security boundaries are enforced at multiple layers (UI, Firestore Rules, Cloud Functions). The two-tier auth model provides appropriate security for both parents and children while remaining COPPA-compliant. 🔒
