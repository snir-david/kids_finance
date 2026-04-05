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

