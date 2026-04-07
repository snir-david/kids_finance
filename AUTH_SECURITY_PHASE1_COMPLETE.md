# KidsFinance — Security Status Document

**Maintained by:** JARVIS (Backend Dev) + Fury (Security Lead)
**Last Updated:** 2026-04-08 (through Sprint 5C security hardening)
**Platforms Supported:** Android only (iOS: not supported; Web: not supported)

---

## Authentication Architecture

### Two-Tier Auth

| User Type | Auth Method | Session Length | Storage |
|-----------|-------------|----------------|---------|
| Parent    | Firebase Auth (email/password) | Firebase-managed | Firebase SDK |
| Child     | bcrypt PIN (4-6 digits) | 24 hours | FlutterSecureStorage + Firestore |

### Parent Auth Flow
1. Parent enters email + password
2. Firebase Auth verifies and returns JWT token
3. Firestore security rules validate membership via parentIds array (not JWT claims)
4. JWT familyId claim is NOT trusted for access decisions (Sprint 5C fix)

### Child Auth Flow
1. Parent selects child from picker
2. Child enters PIN on dot-keypad screen
3. PinService fetches pinHash from Firestore, verifies with BCrypt
4. On success: writes sessionExpiresAt (24h) to Firestore + local FlutterSecureStorage
5. On failure: increments attempt counter; after 5 failures -> 15min lockout
6. Session checked on every child-mode screen via isChildSessionValidProvider

---

## Security Hardening (Sprint 5C)

### 1. JWT Spoofing Fix (Critical)

**Problem:** Original design trusted JWT custom claims (familyId, role) for access decisions.
A malicious user could manipulate their own userProfile document to change their familyId claim,
gaining read access to another family's data.

**Fix:** All security-critical checks now read parentIds directly from Firestore:
- Firestore rules: isParentOfFamily(familyId) reads families/{familyId}.parentIds
- Cloud Functions: assertFamilyMembership(uid, familyId) reads the same array
- JWT claims are still set for convenience but are NOT the source of truth for access

### 2. PIN Lockout

- 5 consecutive failures -> 15-minute lockout
- State persists across app restarts (FlutterSecureStorage)
- Implementation: PinAttemptTracker in lib/features/auth/data/pin_attempt_tracker.dart
- On successful PIN: attempt counter resets to 0

### 3. Session Expiry (24 hours)

- Changed from 30 days to 24 hours (Sprint 5C)
- sessionExpiresAt written to Firestore as Timestamp.fromDate(expiry)
- Session also cached locally in FlutterSecureStorage for fast reads
- Both sources checked; Firestore is authoritative
- Expired sessions require PIN re-entry

### 4. Firestore Rules Hardening (Sprint 5C)

New validation helpers added:
- validBucketCreate(): enforces required fields + balance >= 0 on creation
- validBucketUpdate(): enforces balance >= 0 on every update
- validChildCreate(): enforces displayName, pinHash, familyId present + non-empty

Hard-delete prohibition:
- children: allow delete: if false
- buckets: allow delete: if false
- transactions/multiplierEvents/charityResets: allow update, delete: if false

Input validation in Cloud Functions:
- typeof x !== 'number' || !isFinite(x) -- rejects Infinity, NaN, string-as-number attacks
- multiplier <= 0 -- rejected at both Cloud Function and Firestore rule level

---

## Current Security Posture

### What Is Protected

| Threat | Protection |
|--------|-----------|
| Cross-family data access | isParentOfFamily() reads Firestore parentIds; default deny rule |
| JWT claim manipulation | parentIds array in Firestore is source of truth, not JWT |
| Child data modification | Children have no write access; parents only |
| Negative balances | balance >= 0 enforced in Firestore rules on every write |
| Zero/negative multipliers | multiplier > 0 enforced in Cloud Function + Firestore rules |
| PIN brute force | 5 attempts -> 15min lockout (FlutterSecureStorage, survives restart) |
| Stale child sessions | 24h expiry in Firestore + local storage |
| Data deletion | Hard delete prohibited on children, buckets, transactions |
| COPPA compliance | No email/personal info for children; parent-controlled accounts |

### Cloud Functions (4 callable functions)

| Function | Auth Check | Input Validation |
|----------|-----------|-----------------|
| createFamily | isAuthenticated | - |
| addFundsToChild | assertParentAuth + assertFamilyMembership | amount > 0, isFinite |
| multiplyBucket | assertParentAuth + assertFamilyMembership | multiplier > 0, isFinite |
| distributeFunds | assertParentAuth + assertFamilyMembership | each amount >= 0, total > 0 |

assertFamilyMembership reads families/{familyId}.parentIds in Firestore.

### Firestore Rules Summary

```
/userProfiles/{uid}       -> read/write own profile only
/families/{familyId}      -> isParentOfFamily() required for all access
  /children/{childId}     -> parent read/write; create validates schema; delete prohibited
  /children/{childId}/buckets/{type}
                          -> parent read/write; balance >= 0 on create/update; delete prohibited
  /transactions/{txnId}   -> parent create only; no update/delete
  /multiplierEvents/{id}  -> parent create only; multiplier > 0; no update/delete
  /charityResets/{id}     -> parent create only; no update/delete
```

Everything else: default deny.

---

## Known Limitations

### Platform Support
- Android: Fully supported
- iOS: NOT supported (FlutterSecureStorage Keychain entitlements not configured)
- Web: NOT supported (firebase_auth web, FlutterSecureStorage, and Hive offline queue not configured)

### PIN Recovery
- No parent-initiated remote PIN reset
- If a child forgets their PIN, a parent must update it via the updateChild flow
- PIN lockout can be cleared by the parent resetting the PIN

### Session Revocation
- No parent dashboard to forcibly revoke a child's active session
- Sessions expire naturally after 24h

### Google Sign-In
- Not implemented (was in original design, removed due to google_sign_in package not in pubspec)
- Email/password only for parents

### Audit Logging
- Failed PIN attempts are tracked locally but NOT logged to Firestore
- No centralized audit trail for failed auth events

---

## File Reference

| File | Purpose |
|------|---------|
| lib/features/auth/data/auth_service.dart | Firebase Auth; createFamily |
| lib/features/auth/data/pin_service.dart | bcrypt PIN verify; session management |
| lib/features/auth/data/pin_attempt_tracker.dart | Lockout state in FlutterSecureStorage |
| lib/features/auth/providers/auth_providers.dart | Auth state Riverpod providers |
| firestore.rules | Firestore security rules (production) |
| functions/src/index.ts | Cloud Functions (TypeScript) |

---

_JARVIS + Fury — last updated Sprint 5C (2026-04-07)_
