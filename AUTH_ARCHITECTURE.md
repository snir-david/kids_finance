# KidsFinance Authentication & Authorization Architecture

**Author:** Fury (Security & Auth Specialist)  
**Date:** 2026-04-05  
**Status:** Design Complete — Ready for Implementation

---

## 1. Authentication Strategy

### Parent Authentication
**Primary Method:** Firebase Authentication with Email/Password or Google Sign-In
- Parents MUST use a verified authentication method
- Email/Password: Requires email verification before family creation
- Google Sign-In: Preferred for ease of use and verified identity
- Multi-factor authentication (MFA) recommended but optional

**Why Email-Based Auth for Parents:**
- Parents are responsible adults with email accounts
- Email verification ensures valid contact point
- Required for password recovery and security notifications
- Necessary for multi-parent family management (invite system)

### Child Authentication
**Primary Method:** PIN-based access (4–6 digit PIN)
- Children authenticate with a numeric PIN set by their parent
- PIN is tied to the child's profile within the family
- No email required — COPPA-compliant for children under 13
- PIN stored securely (hashed with bcrypt or Argon2 in Firestore)

**Alternative (Optional):** Parent-delegated Google Account
- For older children (13+) with their own Google account
- Parent can optionally link a child's Google account to their profile
- Still restricted by child role permissions
- Useful for children who want access on multiple devices

**Device Access Control:**
- Each device stores authentication state locally (Flutter Secure Storage)
- Parent can remotely revoke a child's device access via admin panel
- Session tokens expire after 30 days (configurable)

---

## 2. Role Model

### Roles in the System

#### **Parent Role**
- **Identifier:** `role: "parent"` (custom claim)
- **Permissions:**
  - Full CRUD on all family data
  - Create and manage child profiles
  - Set bucket balances (Money, Investments, Charity)
  - Trigger investment multiplier events
  - Reset charity bucket (on donation)
  - Invite additional parents to the family
  - Delete family (with confirmation)
  - View all transaction history

#### **Child Role**
- **Identifier:** `role: "child"` (custom claim)
- **Permissions:**
  - **READ-ONLY** access to their own buckets
  - View their own transaction history
  - View donation history (charity resets)
  - **NO write access** to any bucket
  - **NO access** to other children's data
  - **NO access** to family settings

### Role Storage Strategy
**Two-tier approach for reliability:**

1. **Firebase Auth Custom Claims (JWT):**
   - Set on user creation/role assignment
   - Stored in the ID token (validated by Firestore rules)
   - Used for immediate security rule enforcement
   - Requires re-login or token refresh to update

2. **Firestore Document (Source of Truth):**
   - `/users/{userId}` document contains role and metadata
   - Allows dynamic role changes without re-authentication
   - Cloud Function syncs custom claims from Firestore on changes

**Why Both:**
- Custom claims enable offline security rule enforcement
- Firestore document provides flexibility for role updates
- Cloud Function ensures consistency between both

---

## 3. Firebase Custom Claims Design

### Parent JWT Structure
```json
{
  "uid": "parent_abc123",
  "email": "parent@example.com",
  "email_verified": true,
  "custom_claims": {
    "role": "parent",
    "familyId": "family_xyz789",
    "version": 1
  }
}
```

### Child JWT Structure (PIN-based)
```json
{
  "uid": "child_def456",
  "custom_claims": {
    "role": "child",
    "familyId": "family_xyz789",
    "childId": "child_def456",
    "parentUid": "parent_abc123",
    "version": 1
  }
}
```

### Child JWT Structure (Google Account Linked)
```json
{
  "uid": "child_ghi789",
  "email": "child@example.com",
  "email_verified": true,
  "custom_claims": {
    "role": "child",
    "familyId": "family_xyz789",
    "childId": "child_ghi789",
    "parentUid": "parent_abc123",
    "linkedAccount": true,
    "version": 1
  }
}
```

### Claim Update Strategy
- **On family creation:** Parent gets `familyId` claim
- **On child addition:** Child gets `familyId`, `childId`, `parentUid` claims
- **On second parent join:** New parent gets existing `familyId` claim
- **Claim refresh:** Cloud Function `onUserUpdate` syncs claims with Firestore
- **Version field:** Incremented on claim updates for cache invalidation

---

## 4. Firestore Security Rules Skeleton

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Helper functions
    function isAuthenticated() {
      return request.auth != null;
    }
    
    function getRole() {
      return request.auth.token.role;
    }
    
    function getFamilyId() {
      return request.auth.token.familyId;
    }
    
    function getChildId() {
      return request.auth.token.childId;
    }
    
    function isParent() {
      return isAuthenticated() && getRole() == 'parent';
    }
    
    function isChild() {
      return isAuthenticated() && getRole() == 'child';
    }
    
    function belongsToFamily(familyId) {
      return isAuthenticated() && getFamilyId() == familyId;
    }
    
    function isChildOwner(childId) {
      return isChild() && getChildId() == childId;
    }
    
    // ========== FAMILIES ==========
    match /families/{familyId} {
      // Parents can read/write their own family
      allow read: if belongsToFamily(familyId);
      allow write: if isParent() && belongsToFamily(familyId);
      
      // ========== CHILDREN ==========
      match /children/{childId} {
        // Parents can CRUD any child in their family
        allow read, write: if isParent() && belongsToFamily(familyId);
        
        // Children can READ ONLY their own profile
        allow read: if isChildOwner(childId) && belongsToFamily(familyId);
        allow write: if false; // Children can never write
      }
      
      // ========== BUCKETS ==========
      match /children/{childId}/buckets/{bucketType} {
        // Parents have full access to all child buckets
        allow read, write: if isParent() && belongsToFamily(familyId);
        
        // Children can READ ONLY their own buckets
        allow read: if isChildOwner(childId) && belongsToFamily(familyId);
        allow write: if false; // Children can never modify buckets
      }
      
      // ========== TRANSACTIONS ==========
      match /transactions/{transactionId} {
        // Parents can read/write all transactions
        allow read, write: if isParent() && belongsToFamily(familyId);
        
        // Children can READ transactions for their own buckets
        allow read: if isChild() && 
                      belongsToFamily(familyId) && 
                      resource.data.childId == getChildId();
        allow write: if false; // Transactions created only by parents or Cloud Functions
      }
      
      // ========== MULTIPLIER EVENTS ==========
      match /multiplierEvents/{eventId} {
        // PARENT-ONLY: Only parents can trigger multipliers
        allow read: if belongsToFamily(familyId);
        allow create: if isParent() && belongsToFamily(familyId);
        allow update, delete: if false; // Multiplier events immutable
      }
      
      // ========== CHARITY RESETS ==========
      match /charityResets/{resetId} {
        // PARENT-ONLY: Only parents can reset charity buckets
        allow read: if belongsToFamily(familyId);
        allow create: if isParent() && belongsToFamily(familyId);
        allow update, delete: if false; // Charity resets immutable
      }
    }
    
    // ========== USERS (METADATA) ==========
    match /users/{userId} {
      // Users can read their own metadata
      allow read: if isAuthenticated() && request.auth.uid == userId;
      
      // Only parents can update their own metadata
      allow write: if isParent() && request.auth.uid == userId;
    }
    
    // ========== FAMILY INVITATIONS ==========
    match /invitations/{invitationId} {
      // Parents can create invitations for their family
      allow create: if isParent() && request.resource.data.familyId == getFamilyId();
      
      // Anyone can read invitations sent to their email
      allow read: if isAuthenticated() && 
                    request.auth.token.email == resource.data.invitedEmail;
      
      // Parents can delete their own invitations
      allow delete: if isParent() && resource.data.familyId == getFamilyId();
    }
    
    // Deny all other access
    match /{document=**} {
      allow read, write: if false;
    }
  }
}
```

---

## 5. Authentication Flows

### 5.1 Parent First-Time Setup (Create Family)

1. **User opens app → sees welcome screen**
2. **Tap "Get Started as Parent"**
3. **Choose auth method:**
   - Email/Password: Enter email + password → Firebase creates account
   - Google Sign-In: Tap Google button → OAuth flow
4. **Email verification (if email/password):**
   - Firebase sends verification email
   - User clicks link → email verified
5. **Cloud Function `onUserCreated` triggers:**
   - Creates `/users/{userId}` document with `role: "parent"`
   - Creates `/families/{familyId}` document
   - Sets custom claims: `{ role: "parent", familyId: "{familyId}", version: 1 }`
6. **User redirected to "Create Your Family" screen:**
   - Enter family name (e.g., "Smith Family")
   - Optional: Upload family photo
7. **Family created → navigate to "Add Children" screen**
8. **Parent adds first child:**
   - Enter child name, age, avatar selection
   - Set child's PIN (4–6 digits, confirmed twice)
   - Cloud Function creates `/families/{familyId}/children/{childId}`
   - Cloud Function creates Firebase Auth account for child (anonymous + custom claims)
   - Initial buckets created: Money: $0, Investments: $0, Charity: $0
9. **Parent navigates to Parent Dashboard** (can add more children later)

---

### 5.2 Parent Returning Login

1. **User opens app → sees "Welcome Back" screen**
2. **Choose auth method:**
   - Email/Password: Enter credentials
   - Google Sign-In: Tap Google button
3. **Firebase authenticates → ID token with custom claims received**
4. **App reads `role` from token:**
   - If `role == "parent"` → navigate to Parent Dashboard
   - If `role == "child"` → navigate to Child Dashboard
5. **Load family data from `/families/{familyId}`**
6. **Dashboard displays children and bucket summaries**

---

### 5.3 Child Login

**Scenario 1: PIN-based (most common)**

1. **Child opens app on their device → sees "Who Are You?" screen**
2. **Display list of children in the family (fetched via family code or pre-configured)**
3. **Child taps their avatar/name**
4. **PIN entry screen appears (numeric keypad)**
5. **Child enters their PIN**
6. **Cloud Function `authenticateChild` called:**
   - Validates PIN hash against `/families/{familyId}/children/{childId}/pinHash`
   - If valid: generates custom token for child
   - Returns Firebase custom token
7. **App signs in with custom token → receives ID token with child claims**
8. **Navigate to Child Dashboard (read-only view of their buckets)**

**Scenario 2: Google Account Linked (optional, age 13+)**

1. **Child opens app → taps "Sign in with Google"**
2. **Google OAuth flow**
3. **Firebase validates account:**
   - Checks if account is linked to a child profile in Firestore
   - Verifies `role == "child"` in custom claims
4. **Navigate to Child Dashboard**

---

### 5.4 Second Parent Joins Existing Family

1. **First parent (already logged in) goes to Family Settings → "Invite Parent"**
2. **Enter second parent's email address**
3. **Cloud Function `createParentInvitation`:**
   - Creates `/invitations/{invitationId}` document
   - Sends email to invitee with invite link (deep link to app + invitation code)
4. **Second parent receives email → clicks invite link**
5. **App opens to "Join Family" screen:**
   - Shows family name and inviter's name
   - "Accept Invitation" button
6. **Second parent authenticates (email/password or Google)**
7. **Cloud Function `acceptInvitation` triggers:**
   - Adds second parent's UID to `/families/{familyId}/parentUids[]`
   - Sets custom claims on second parent: `{ role: "parent", familyId: "{familyId}", version: 1 }`
   - Deletes invitation document
8. **Second parent sees Parent Dashboard with full family access**

---

## 6. Child Privacy Considerations (COPPA Compliance)

### What NOT to Collect from Children
- ❌ **Email address** (unless 13+ and parent-approved)
- ❌ **Phone number**
- ❌ **Full name** (first name only, no last name)
- ❌ **Date of birth** (age range is sufficient: "5-7", "8-10", "11-12")
- ❌ **Location data** (no GPS, no IP logging)
- ❌ **Photos of the child** (avatar selection from pre-made icons only)
- ❌ **Social features** (no messaging, no friend requests, no public profiles)

### What We CAN Collect
- ✅ **First name** (for personalization, parent-entered)
- ✅ **Age range** (for UI customization)
- ✅ **Bucket balances** (functional data for the app)
- ✅ **Transaction history** (educational, parent-initiated)
- ✅ **Avatar selection** (from pre-made library, not user-uploaded)

### COPPA Compliance Measures
1. **Parental Consent:** Parent creates child account → verifiable consent
2. **No Direct Child Registration:** Children cannot self-register
3. **Parent Control:** Parents can delete child data at any time
4. **No Third-Party Sharing:** Child data never leaves Firebase (no analytics, no ads)
5. **Minimal Data Collection:** Only functional data (bucket balances, transactions)
6. **Secure Storage:** All child data encrypted at rest (Firebase default)
7. **No Persistent Device Identifiers:** No tracking across devices
8. **Data Deletion:** "Delete Child" action purges all child data (GDPR "right to erasure")

### Recommended Privacy Disclosures
- Privacy policy clearly states: "KidsFinance is a parent-managed app. We do not collect personal information from children. All child accounts are created and managed by parents."
- Include COPPA-compliant consent flow during parent signup
- Provide easy "Download My Data" and "Delete My Family" options for parents

---

## 7. Security Risk Surface

### Risk 1: **Family Isolation Breach** (CRITICAL)
**Threat:** Attacker with a child account attempts to access another family's data by manipulating `familyId` in requests.

**Mitigation:**
- ✅ Firestore rules enforce `belongsToFamily(familyId)` on ALL data paths
- ✅ `familyId` stored in JWT custom claims (server-validated, tamper-proof)
- ✅ No client-side trust: all family ID checks happen server-side in rules
- ✅ Cloud Functions ALWAYS validate `request.auth.token.familyId` before mutations
- ✅ Integration tests: attempt cross-family access with crafted requests (MUST fail)

**Test Case:**
```javascript
// Attacker (Child from Family A) tries to read Family B's data
const familyBRef = db.doc('/families/familyB/children/someChild');
await familyBRef.get(); // MUST THROW PERMISSION DENIED
```

---

### Risk 2: **Child Privilege Escalation** (HIGH)
**Threat:** Child user manipulates client state to gain parent permissions (modify bucket balances, trigger multipliers).

**Mitigation:**
- ✅ Firestore rules explicitly deny child writes: `allow write: if false;`
- ✅ Parent-only actions (multiplier, charity reset) enforced in both rules AND Cloud Functions
- ✅ Cloud Functions validate `request.auth.token.role == "parent"` before executing privileged mutations
- ✅ Children receive read-only Firestore listeners (no write methods in child UI code)
- ✅ Code review: ensure no child-facing UI triggers write operations

**Test Case:**
```javascript
// Child tries to update their own bucket balance
const bucketRef = db.doc('/families/familyX/children/childY/buckets/money');
await bucketRef.update({ balance: 9999 }); // MUST THROW PERMISSION DENIED
```

---

### Risk 3: **PIN Brute-Force Attack** (MEDIUM)
**Threat:** Attacker with physical access to a child's device attempts to guess the child's PIN.

**Mitigation:**
- ✅ Rate limiting on PIN attempts (Cloud Function enforces max 5 attempts per 15 minutes)
- ✅ Account lockout after 10 failed attempts (requires parent unlock via email link)
- ✅ PIN length requirement: minimum 4 digits (10,000 combinations)
- ✅ Optional: increase to 6 digits (1,000,000 combinations) for paranoid parents
- ✅ Hashing: PINs stored as bcrypt hashes (computationally expensive to crack)
- ✅ No password hints or recovery for children (parent must reset PIN)
- ✅ Audit log: all failed PIN attempts logged to Firestore for parent review

**Test Case:**
```javascript
// Simulate 6 rapid PIN attempts
for (let i = 0; i < 6; i++) {
  const result = await authenticateChild(childId, '0000');
}
// 6th attempt MUST be rate-limited (403 or 429 error)
```

---

## Implementation Checklist for JARVIS

- [ ] Set up Firebase Authentication project in Firebase Console
- [ ] Enable Email/Password and Google Sign-In providers
- [ ] Deploy Cloud Function: `onUserCreated` (sets custom claims + creates `/users/{uid}`)
- [ ] Deploy Cloud Function: `createFamily` (callable, parent-only)
- [ ] Deploy Cloud Function: `addChild` (callable, parent-only, creates child Firebase Auth user)
- [ ] Deploy Cloud Function: `authenticateChild` (callable, validates PIN, returns custom token)
- [ ] Deploy Cloud Function: `setParentInvitation` (callable, parent-only)
- [ ] Deploy Cloud Function: `acceptInvitation` (callable, adds parent to family)
- [ ] Deploy Firestore security rules (from section 4)
- [ ] Create `/users/{uid}` schema (role, familyId, email, createdAt)
- [ ] Create `/families/{familyId}` schema (name, parentUids[], createdAt)
- [ ] Create `/families/{familyId}/children/{childId}` schema (name, age, pinHash, avatarId)
- [ ] Set up bcrypt or Argon2 for PIN hashing in Cloud Functions
- [ ] Implement rate limiting for PIN authentication (Firebase Realtime Database counters or Firestore)
- [ ] Write integration tests for all security rules (use Firebase Emulator Suite)
- [ ] Implement "Delete Family" Cloud Function (purges all family data, callable by parent)
- [ ] Add audit logging for privileged actions (multiplier triggers, charity resets, child deletions)

---

## Future Enhancements (Post-MVP)

1. **Biometric Authentication for Children** (fingerprint/face unlock as alternative to PIN)
2. **Multi-Device Child Access** (sync child sessions across devices with parent approval)
3. **Parent Activity Notifications** (push notifications when bucket balances change)
4. **Audit Trail UI** (parent-viewable log of all family transactions and auth events)
5. **Emergency Access Codes** (one-time parent override codes for lost PINs)
6. **Granular Parent Permissions** (distinguish "admin parent" vs. "view-only parent")

---

**END OF DOCUMENT**

This architecture is ready for implementation. All security boundaries are clearly defined, COPPA compliance is baked in, and the top 3 risks have concrete mitigations. Let's build a safe app for kids to learn about money. 🔒
