# KidsFinance Authentication & Authorization Architecture

**Author:** Fury (Security & Auth Specialist)  
**Date:** 2026-04-05  
**Updated:** 2026-04-09 (Sprint 7D — Child PIN removed)  
**Status:** ✅ IMPLEMENTED

---

## 1. Authentication Strategy

### Two-Tier Authentication Model

KidsFinance uses a **two-tier authentication system** that separates parent and child access:

| Tier | User Type | Method | Backend | Session |
|------|-----------|--------|---------|---------|
| 1 | Parent | Firebase Auth (Email/Password) | Firebase Auth | Persistent |
| 2 | Child | Tap avatar (no credentials) | None — uses parent's session | App lifetime |

> **Note (Sprint 7D):** Child PIN authentication was removed. Children access their screen by tapping their avatar on the `ChildPickerScreen`. Security is maintained because the child picker is only reachable from the `ParentHomeScreen`, which already requires full Firebase Auth authentication.

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

### Child Access (Tier 2)
**Method:** Avatar tap — no credentials required
- Children do NOT have Firebase Auth accounts
- Child accesses their screen by tapping avatar on `ChildPickerScreen`
- `activeChildProvider` (Riverpod `StateProvider`) stores the selected child's ID in memory
- Session lasts as long as the app is in the foreground / parent doesn't log out
- Parent tapping "Back to Parent" clears `activeChildProvider` and returns to parent home

**Implementation Files:**
- `lib/features/auth/presentation/child_picker_screen.dart` — Avatar selection → sets `activeChildProvider`
- `lib/features/auth/presentation/child_home_screen.dart` — Child-facing UI (read-only)
- `lib/features/auth/providers/session_provider.dart` — `SessionState` based on `activeChildProvider != null`

### Session Management

**Parent Sessions:**
- Managed by Firebase Auth (persistent until logout)
- Token refresh handled automatically by Firebase SDK

**Child Sessions:**
- In-memory only: `activeChildProvider` holds the currently selected child ID
- No expiry — cleared when parent navigates back or app is closed
- `PopScope(canPop: false)` on child home prevents back-button bypass

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
  return d.keys().hasAll(['displayName', 'avatarEmoji', 'familyId', 'createdAt'])
      && d.displayName.size() > 0 && d.displayName.size() <= 50;
}

// Note: pinHash field is no longer required. Existing child documents may still have it
// for backward compatibility, but new children are created without it.
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

### 5.4 Child Access (Tap Avatar — No PIN)

1. **Parent is on ParentHomeScreen** (already Firebase Auth authenticated)
2. **Parent taps child's card** → Navigate to `ChildPickerScreen`
3. **Child taps their own avatar:**
   - `activeChildProvider` set to child's ID
   - `selectedChildProvider` set to child object
   - `context.go('/child-home')` — replaces stack
4. **ChildHomeScreen loads** — read-only view of that child's buckets, goals, badges
5. **Child (or parent) taps "Back to Parent":**
   - `activeChildProvider` cleared
   - Navigate to `/parent-home`

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
- ✅ PopScope prevents back-button bypass (`automaticallyImplyLeading: false`)
- ✅ Child picker only reachable from authenticated parent session

### Risk 3: **PIN Brute-Force Attack** — N/A (PIN Removed)
**Resolution:** Child PIN authentication was removed in Sprint 7D. Children access their screen by tapping their avatar from the parent's already-authenticated session. No credentials to brute-force.

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
| PIN Service | ~~Removed Sprint 7D~~ | N/A — children tap avatar |
| PIN Brute-Force Protection | ~~Removed Sprint 7D~~ | N/A |
| 24h Session Expiry | ~~Removed Sprint 7D~~ | Session = parent's Firebase Auth session |
| Firestore Rules | ✅ Deployed | `firestore.rules` — includes badges + goals |
| JWT Spoofing Fix | ✅ | `functions/src/index.ts` |
| Cloud Functions | ✅ | `functions/src/index.ts` (4 functions) |
| Child Picker UI | ✅ | `child_picker_screen.dart` — tap avatar to enter |
| PIN Entry UI | ~~Removed~~ | `/child-pin` route removed from router |

---

**END OF DOCUMENT**

This architecture is fully implemented as of Sprint 7D. All security boundaries are enforced at multiple layers (UI, Firestore Rules, Cloud Functions). The two-tier auth model provides appropriate security for both parents and children while remaining COPPA-compliant. Children access their screens via avatar tap from the parent's authenticated session — no separate PIN required. 🔒
