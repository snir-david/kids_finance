# KidsFinance Master Test Plan

**Status:** v1.0 — Master test specification  
**Owner:** Happy (QA/Tester)  
**Last Updated:** 2026-04-05  
**Scope:** Flutter + Firebase app for kids' finance management

---

## Overview

This is the **living test specification** that defines what must pass before any feature ships. Tests are organized into logical categories, with explicit critical path tests, permission boundaries, and edge cases.

**Core Domain:** Three buckets per child (Money 💰, Investments 📈, Charity ❤️), parent controls, multi-child, multi-parent family model.

---

## 1. Test Categories

### 1.1 Authentication & Authorization
- User signup/login (parent & child accounts)
- Session management & token refresh
- Multi-device parent access
- Account recovery & password reset

### 1.2 Bucket Operations
- Money bucket: set, view, increment, decrement
- Investments bucket: multiply transaction, view balance
- Charity bucket: donate, reset to zero
- Bucket data persistence

### 1.3 Investment Multiplier
- Single multiply operation on positive balance
- Multiply stores transaction history correctly
- Multiply on zero balance (edge case)
- Multiple consecutive multiplies
- Investment transaction audit trail

### 1.4 Charity Reset
- Charity bucket resets to zero after donation
- Child sees updated balance immediately
- Parent sees audit trail of donation
- Reset with zero balance (idempotent)

### 1.5 Permissions & Access Control
- Child can only see own buckets
- Child cannot modify any buckets
- Child cannot see sibling buckets or data
- Parent can see all children in family
- Parent can modify all children's buckets
- Parent cannot see unrelated families

### 1.6 Multi-Parent Scenarios
- Two parents can both access same family
- Parent A edits child's money, Parent B sees update in real-time
- Concurrent edits by two parents (conflict resolution)
- New parent invited to family (permission grant)
- Parent revoke access (remove from family)

### 1.7 Multi-Child Scenarios
- Family with 2+ children
- Child isolation (can't see siblings' buckets)
- Parent can manage all children
- Add new child to family

### 1.8 Offline & Network Resilience
- App works offline (local-first)
- Changes queue when offline
- Sync on reconnect with conflict resolution
- Stale data handling (concurrent changes)
- Push notifications for updates

### 1.9 UI & UX
- Kid Mode: simple, colorful, intuitive
- Parent Mode: full control, audit trail visible
- Mode switching
- Animations & visual feedback
- Error messages (child-friendly & parent-detailed)

---

## 2. Critical Path Test Cases

These **MUST PASS** before any release.

### 2.1 Authentication

| ID | Test Name | Given | When | Then | Priority |
|---|---|---|---|---|---|
| AUTH-001 | Parent can sign up | Unregistered user on signup screen | Parent enters email, password, confirms | Account created, parent logged in, ready to create/join family | P0 |
| AUTH-002 | Parent can log in | Registered parent with valid credentials | Parent enters email, password | Login succeeds, parent dashboard shown | P0 |
| AUTH-003 | Child account created by parent | Parent in family setup | Parent creates child profile (name, age, PIN) | Child account created, child can log in with PIN | P0 |
| AUTH-004 | Logout clears session | Logged-in user | User taps logout | Session destroyed, login screen shown | P0 |
| AUTH-005 | Invalid password rejected | Registered parent | Parent enters wrong password | Login fails with clear error, user stays on login screen | P1 |

### 2.2 Bucket Operations - Money

| ID | Test Name | Given | When | Then | Priority |
|---|---|---|---|---|---|
| MONEY-001 | Parent sets child money to positive value | Parent logged in, child exists | Parent enters $50 | Child money bucket = $50, audit entry created | P0 |
| MONEY-002 | Parent sets child money to zero | Child has $100 | Parent changes value to $0 | Child money bucket = $0, valid state | P0 |
| MONEY-003 | Child views own money bucket | Child logged in | Child opens Money bucket | Child sees correct balance, can't edit | P0 |
| MONEY-004 | Child cannot modify money bucket | Child logged in | Child tries to modify money value (UI disabled or blocked) | Modification rejected, balance unchanged | P0 |
| MONEY-005 | Money persists after app close | Parent sets money, app closes | Reopen app | Money value still correct | P0 |
| MONEY-006 | Parent cannot set negative money | Parent in child bucket editor | Parent tries to enter -$10 | Input validation rejects negative, only 0+ allowed | P1 |
| MONEY-007 | Multiple rapid updates by same parent | Parent sets $10, then $20, then $30 | All three updates in quick succession | Final balance = $30, all edits in audit trail | P1 |

### 2.3 Investment Bucket

| ID | Test Name | Given | When | Then | Priority |
|---|---|---|---|---|---|
| INVEST-001 | Parent multiplies investment (2x) | Child investments = $100 | Parent clicks "Multiply by 2" | Investments = $200, transaction recorded with multiplier=2 | P0 |
| INVEST-002 | Child views investment bucket | Child logged in | Child opens Investments bucket | Child sees current balance, can't edit | P0 |
| INVEST-003 | Investment multiply creates transaction | Parent multiplies $50 by 3 | Multiply operation completes | Transaction audit shows: original $50 → $150, timestamp, parent name | P0 |
| INVEST-004 | Multiple consecutive multiplies work | Investments = $10 | Parent multiplies by 2, then by 5 | Balance = $100 ($10 → $20 → $100), both transactions recorded | P0 |
| INVEST-005 | Multiply by 1 is no-op | Investments = $50 | Parent multiplies by 1 | Balance still $50, transaction still recorded | P1 |
| INVEST-006 | Multiply on zero balance is valid | Investments = $0 | Parent multiplies by 10 | Balance = $0, transaction recorded (0 × 10 = 0) | P1 |

### 2.4 Charity Bucket

| ID | Test Name | Given | When | Then | Priority |
|---|---|---|---|---|---|
| CHARITY-001 | Parent initializes charity bucket | Parent setting up child buckets | Parent sets charity to $25 | Charity bucket = $25 | P0 |
| CHARITY-002 | Child can donate (reset to zero) | Child has $75 in charity | Child taps "Donate" button | Charity resets to $0, confirmation shown to child | P0 |
| CHARITY-003 | Charity reset creates audit entry | Child donates $75 | Reset completes | Audit shows: donation of $75, timestamp, child name | P0 |
| CHARITY-004 | Parent sees donation history | Parent viewing charity bucket | Parent opens history/audit trail | Parent sees all past donations with dates | P0 |
| CHARITY-005 | Reset charity with zero balance | Charity = $0 | Child taps donate | Balance stays $0, operation is idempotent | P1 |
| CHARITY-006 | Charity cannot go negative | Parent tries to set charity to -$10 | Input validation blocks entry | Only 0+ values accepted | P1 |

### 2.5 Permissions - Child Isolation

| ID | Test Name | Given | When | Then | Priority |
|---|---|---|---|---|---|
| PERM-001 | Child A cannot see Child B buckets | Family with Child A and Child B, each logged in separately | Child A logs in, tries to view Child B profile | Only Child A's buckets visible, Child B data hidden | P0 |
| PERM-002 | Child cannot trigger parent action | Child A logged in, tries to multiply investments | Multiply button is disabled/absent for child | Child cannot multiply investments | P0 |
| PERM-003 | Child cannot reset charity bucket | Child logged in, tries to trigger reset (not donate) | Reset function unavailable or blocked | Only donate action available | P0 |
| PERM-004 | Child cannot access Parent Mode | Child logs in | Child cannot switch to Parent Mode or access parent controls | Parent Mode inaccessible without parent PIN/password | P0 |

### 2.6 Permissions - Parent Access

| ID | Test Name | Given | When | Then | Priority |
|---|---|---|---|---|---|
| PERM-005 | Parent can see all children in family | Parent with 3 children | Parent opens family dashboard | All 3 children listed and selectable | P0 |
| PERM-006 | Parent can edit any child's buckets | Parent with 2 children | Parent edits Child 2's money bucket | Change succeeds, Child 2 sees update | P0 |
| PERM-007 | Parent sees full audit trail | Parent viewing history | Parent opens any bucket's audit trail | Parent sees all transactions with timestamps, actors, values | P0 |
| PERM-008 | Parent cannot see unrelated family | Parent A (Family 1) tries to access Family 2 | Attempt to load Family 2 data | Access denied, only Family 1 visible | P0 |

### 2.7 Multi-Parent Scenarios

| ID | Test Name | Given | When | Then | Priority |
|---|---|---|---|---|---|
| MULTI-P-001 | Two parents see same family | Parent A and Parent B both invited to Family 1 | Both parents logged in on separate devices | Both see Family 1 with same child data | P0 |
| MULTI-P-002 | Parent A edits child money, Parent B sees update | Parent A sets money to $50 | Parent B refreshes or sync triggers | Parent B sees $50 immediately | P0 |
| MULTI-P-003 | Concurrent edits: Parent A and B both edit money at same time | Parent A changes money to $30, Parent B changes to $40 (same instant) | Both edits sent to backend | Last-write-wins or conflict resolved deterministically, final state consistent | P1 |
| MULTI-P-004 | New parent invited to family | Parent A invites Parent B via email/link | Parent B accepts invitation | Parent B gains access to family, sees all children | P1 |
| MULTI-P-005 | Parent revoke: Parent A removes Parent B from family | Parent A has admin, Parent B is member | Parent A revokes Parent B access | Parent B can no longer access family, gets error on next sync | P1 |
| MULTI-P-006 | Two parents multiply same investment (sequential) | Parent A multiplies by 2, then Parent B multiplies by 3 | Both operations complete | Balance correct ($100 → $200 → $600), both transactions in audit | P1 |

### 2.8 Multi-Child Scenarios

| ID | Test Name | Given | When | Then | Priority |
|---|---|---|---|---|---|
| MULTI-C-001 | Family with 2+ children, parent manages all | Parent with 2 children | Parent opens family dashboard | Both children listed, both buckets manageable | P0 |
| MULTI-C-002 | Add new child to family | Parent on family settings | Parent creates new child profile | Child added to family, visible to parent, isolated from siblings | P0 |
| MULTI-C-003 | Child 1 cannot see Child 2's buckets | Family with 2 children | Child 1 logs in | Only Child 1's buckets shown, no access to Child 2 data | P0 |

### 2.9 Offline & Sync

| ID | Test Name | Given | When | Then | Priority |
|---|---|---|---|---|---|
| OFFLINE-001 | App works offline (local-first) | Device online, user performs action, then goes offline | Offline mode activated | App continues to show data, allows local edits | P1 |
| OFFLINE-002 | Changes queue when offline | Offline, parent changes money to $100 | Parent reconnects to internet | Queued change syncs to backend, backend state updated | P1 |
| OFFLINE-003 | Conflict resolution on sync | Offline edit: money → $100; Backend changed to $80 meanwhile | Device reconnects | Conflict resolved (last-write-wins or prompt user), final state consistent | P1 |
| OFFLINE-004 | Stale data warning | Device was offline for 5 mins | Device reconnects | UI shows data is refreshing, no stale values shown | P1 |

### 2.10 UI & UX

| ID | Test Name | Given | When | Then | Priority |
|---|---|---|---|---|---|
| UI-001 | Kid Mode is simple & colorful | Child logs in | Kid Mode home shown | Large buttons, clear icons (💰 🎓 ❤️), minimal text | P1 |
| UI-002 | Parent Mode shows controls | Parent logs in | Parent Mode shown | Edit buttons, audit trails, settings visible | P1 |
| UI-003 | Mode switching works | Parent in Parent Mode | Parent taps "Switch to Kid Mode" (if applicable) | Mode changes, appropriate UI shown | P1 |
| UI-004 | Error messages are clear | Invalid input on parent form | Submit fails | Error message explains issue in parent language | P1 |

---

## 3. Permission Boundary Tests

These tests explicitly verify the **security model** and prevent privilege escalation.

### 3.1 Child Security Boundaries

| ID | Test Case | Expected Result |
|---|---|---|
| SEC-CHILD-001 | Child attempts to set own money bucket directly (API bypass) | Request rejected at backend, auth check prevents modification |
| SEC-CHILD-002 | Child attempts to view sibling's UID/buckets via direct API | Backend permission check denies access |
| SEC-CHILD-003 | Child tries to invoke multiply endpoint | Backend rejects (parent-only action) |
| SEC-CHILD-004 | Child logs in with parent PIN | System rejects child PIN during parent auth, child account opened instead |
| SEC-CHILD-005 | Child account token used to edit parent-controlled field | API rejects token scoping, action forbidden |

### 3.2 Parent Security Boundaries

| ID | Test Case | Expected Result |
|---|---|---|
| SEC-PARENT-001 | Parent A tries to edit Parent B's personal settings | Permission denied, only own settings editable |
| SEC-PARENT-002 | Parent A from Family 1 tries to access Child from Family 2 | API returns 403 Forbidden, family isolation enforced |
| SEC-PARENT-003 | Parent A tries to revoke own access (self-remove) | System allows or warns, handled gracefully |
| SEC-PARENT-004 | Parent with member role tries to invite new parent | System checks role, invitation rejected if not admin |
| SEC-PARENT-005 | Parent token expires, tries to perform action | Request rejected, re-login required |

### 3.3 Family Isolation

| ID | Test Case | Expected Result |
|---|---|---|
| SEC-FAMILY-001 | Query via URL/ID: Family A child data, but user belongs to Family B | Backend rejects query, 403 Forbidden |
| SEC-FAMILY-002 | Two unrelated families fetch data simultaneously (stress test) | Data isolation maintained, no leakage |
| SEC-FAMILY-003 | Parent removed from family, still has old auth token | Token revoked or next action fails, access denied |

---

## 4. Edge Cases & Boundary Values

These are tricky scenarios that MUST be tested:

### 4.1 Money Bucket Boundaries

| Edge Case | Test |
|---|---|
| **Zero balance** | Parent sets money to $0, child can view, parent can increment |
| **Large values** | Parent sets money to $999,999.99, system handles without overflow |
| **Decimal precision** | Parent sets money to $10.50, displayed correctly, calculations exact |
| **Concurrent increments** | Parent A adds $10, Parent B adds $5 simultaneously, final = $15 |
| **Rapid back-to-back sets** | Parent sets $10, $20, $15, $25 in 100ms intervals, final = $25 |

### 4.2 Investment Multiplier Edge Cases

| Edge Case | Test |
|---|---|
| **Multiply by 0** | Investment $100, multiply by 0 → should result in $0 (or error, TBD by product) |
| **Multiply by 1** | Investment $50, multiply by 1 → $50, transaction recorded |
| **Multiply on zero** | Investment $0, multiply by 100 → $0 (mathematically correct) |
| **Very large multiplier** | Investment $1, multiply by 1,000,000 → $1,000,000 |
| **Fractional multiplier** | Investment $100, multiply by 1.5 → $150 |
| **Negative multiplier** | Investment $50, multiply by -2 (should reject) |
| **Transaction audit correctness** | 10 consecutive multiplies, all recorded with correct values |

### 4.3 Charity Reset Edge Cases

| Edge Case | Test |
|---|---|
| **Reset zero balance** | Charity $0, child donates → still $0, idempotent |
| **Multiple rapid resets** | Child taps donate 5 times rapidly → balance $0 after each, no double-donation |
| **Concurrent: parent sets + child resets** | Parent adding $50 while child donating → conflict resolved, state consistent |

### 4.4 Offline & Sync Edge Cases

| Edge Case | Test |
|---|---|
| **Offline for extended period (1+ hour)** | Offline queue doesn't lose data, all changes sync when reconnected |
| **Offline with stale local data** | Offline, user sees old cached data; reconnect → fresh data fetched |
| **Reconnect with diverged state** | Offline: set money to $50; Backend: parent changed to $100 → conflict resolution |
| **Network flaky (intermittent drops)** | Rapid online/offline cycles → sync retries, eventual consistency |
| **Offline purchase / critical action** | Action queued offline, priority order maintained on sync |

### 4.5 Multi-Parent Race Conditions

| Race Condition | Test |
|---|---|
| **Parent A and B edit same child, same field, exact same moment** | Last-write-wins or merge, final state consistent |
| **Parent A multiplies, Parent B multiplies, concurrently** | Both transactions recorded, balance correct ($100 × 2 × 3 = $600) |
| **Parent A removes Parent B while B is editing** | B's edit either succeeds (already in-flight) or fails gracefully (permission revoked mid-action) |
| **Parent A invites Parent B, B accepts, A revokes before accept completes** | State is consistent; B either has access or doesn't, no half-states |

### 4.6 Data Type & Input Validation

| Edge Case | Test |
|---|---|
| **Money input: non-numeric string** | "abc" rejected, error message shown |
| **Money input: special characters** | "$100", "100€" handled or rejected gracefully |
| **Money input: whitespace** | "  100  " trimmed and processed |
| **Multiplier input: non-numeric** | "2x" or "two" rejected |
| **Child name: very long string (100+ chars)** | Accepted or truncated gracefully, no crash |
| **Child name: special characters/emoji** | "Child 🎓", "José", accepted and displayed correctly |
| **Family name: empty string** | Rejected, required field |

### 4.7 Session & Auth Edge Cases

| Edge Case | Test |
|---|---|
| **Session timeout on parent** | Idle 30+ mins, next action requires re-login |
| **Parent logs in on two devices** | Both sessions valid, changes sync across devices |
| **Parent logs out on Device A while editing on Device B** | Device B session continues (or invalidated, TBD), Device A requires re-login |
| **Firebase token refresh** | Token expires, system silently refreshes, user unaware (or minimal interruption) |
| **App backgrounded, foregrounded after 10 mins** | Data re-synced if offline-capable, fresh state |

---

## 5. Test Infrastructure Requirements

### 5.1 Firebase Setup

- **Firebase Emulator Suite**
  - Local Firestore emulator
  - Firebase Auth emulator
  - Local Cloud Functions emulator (for business logic)
  - Allows fast test iteration without hitting production

- **Test Data Fixtures**
  - Seed script to create test families (Parent A + 2 Children, Parent B, shared family, etc.)
  - Reset script to clear test data between test runs
  - Known test credentials (test-parent@example.com, test-child-pin: 1234, etc.)

### 5.2 Flutter Test Harness

- **Unit Tests**
  - Bucket calculation logic (multiply, reset, validation)
  - Permission checks (child vs. parent role)
  - Transaction audit creation

- **Widget Tests**
  - Kid Mode UI (buttons, layouts, accessibility)
  - Parent Mode UI (forms, controls)
  - Mode switching
  - Error dialogs

- **Integration Tests**
  - Full user flow: parent login → create child → set money → child login → view buckets
  - Multi-parent concurrent edits
  - Offline scenario: edit offline, reconnect, verify sync
  - Firebase emulator integration tests

### 5.3 Cloud Functions Testing

- **Test Framework**
  - Firebase Functions emulator + Jest/Mocha
  - Test permission checks on sensitive operations (multiply, reset, invite parent)
  - Test conflict resolution (concurrent edits)
  - Test transaction audit creation

- **Critical Functions to Test**
  - `setChildMoney(familyId, childId, amount)` — permission + validation
  - `multiplyInvestment(familyId, childId, multiplier)` — audit trail creation
  - `resetCharity(familyId, childId)` — idempotence
  - `inviteParent(familyId, parentEmail)` — permission checks
  - `removeParent(familyId, parentId)` — session invalidation

### 5.4 Mock & Fake Providers

- **Firebase Mock**
  - In-memory Firestore for fast unit tests
  - Mock Auth for auth flow testing
  - Fake Cloud Functions for offline development

- **Network Mocks**
  - HTTP interceptor to simulate offline mode
  - Latency injection (100ms, 500ms, 5s delays)
  - Failure simulation (404, 500, timeout)

- **User & Family Test Fixtures**
  ```
  Family 1:
    - Parent A (admin)
    - Parent B (member)
    - Child 1 (money: $50, investments: $100, charity: $25)
    - Child 2 (money: $0, investments: $0, charity: $0)
  
  Family 2:
    - Parent C (admin)
    - Child 3 (money: $500, investments: $1000, charity: $100)
  ```

### 5.5 CI/CD Integration

- **Test Stages**
  1. **Unit Tests** — Fast, run on every commit (< 1 min)
  2. **Widget Tests** — UI tests, run on PR (< 2 min)
  3. **Integration Tests** — Full flow with Firebase emulator, run on PR (< 5 min)
  4. **Cloud Functions Tests** — Jest on functions/, run on PR (< 1 min)

- **Coverage Requirements**
  - Minimum 80% code coverage on critical paths (auth, bucket operations, multiplier)
  - 100% coverage on permission checks
  - 100% coverage on transaction audit creation

### 5.6 Manual Testing & QA

- **Devices**
  - Physical Android device (primary)
  - Android emulator (backup)
  - iOS device (future, Flutter allows)

- **Test Scenarios**
  - Full end-to-end flow with real Firebase (staging environment)
  - Multi-device parent testing (two phones editing simultaneously)
  - Offline testing (toggle airplane mode, edit, reconnect)
  - Network throttling (Chrome DevTools network tab simulation)

- **Accessibility Testing**
  - Kid-friendly UI (font size, colors, touch targets)
  - Parent-mode readability (audit trail font, table layouts)
  - Voice-over / TalkBack support (future)

---

## 6. Test Execution Strategy

### 6.1 Pre-Release Gates

**Before any feature ships, ALL of these must pass:**
1. ✅ All P0 tests pass
2. ✅ All permission boundary tests pass (SEC-*)
3. ✅ All critical edge cases pass (Sections 4.1–4.7)
4. ✅ Code coverage ≥ 80% on critical paths
5. ✅ Manual QA sign-off on Android device
6. ✅ Offline scenario tested & passing

### 6.2 Regression Testing

After each release:
1. Run full test suite (unit + integration) — should take < 10 mins
2. Spot-check key user flows on device
3. Monitor Firebase for unexpected errors
4. Gather user feedback on kids' experience

### 6.3 Load & Stress Testing (Future)

Once MVP is live:
- Simulate 100+ families, 500+ children, 2+ parent concurrent edits
- Firebase emulator scaling tests
- Network resilience under high load

---

## 7. Definition of Done

A feature is **DONE** when:
1. ✅ Code passes linter (Flutter/Dart standards)
2. ✅ Tests written & passing (unit + widget + integration)
3. ✅ Edge cases covered (if applicable)
4. ✅ Permission checks validated
5. ✅ Firebase emulator integration tested
6. ✅ Manual QA testing completed
7. ✅ Audit trail / transaction logging verified (if applicable)
8. ✅ Offline behavior tested (if applicable)
9. ✅ PR reviewed by tech lead (Stark) + security lead (Fury)
10. ✅ Merged to main, no test regressions

---

## 8. Test Categories Summary Table

| Category | Test Count | P0 Count | Priority | Notes |
|---|---|---|---|---|
| Authentication | 5 | 2 | High | Must work before any feature |
| Bucket Operations | 7 | 4 | High | Core feature, tested extensively |
| Investment | 6 | 3 | High | Complex logic, needs edge case coverage |
| Charity | 6 | 3 | High | Reset idempotence critical |
| Permissions (Child) | 4 | 4 | Critical | Security-critical |
| Permissions (Parent) | 4 | 4 | Critical | Security-critical |
| Multi-Parent | 6 | 3 | High | Complex concurrent scenarios |
| Multi-Child | 3 | 2 | Medium | Family isolation |
| Offline & Sync | 4 | 0 | Medium | P1, but essential for reliability |
| UI & UX | 4 | 0 | Medium | P1, child experience critical |
| **Boundary & Edge Cases** | **30+** | — | High | Spread across sections 4.1–4.7 |
| **Permission Boundaries** | **8** | **8** | Critical | Explicit security model validation |
| **TOTAL** | **60+** | **30+** | — | Covers MVP + key scenarios |

---

## 9. Success Criteria

KidsFinance **MVP is production-ready when:**

1. **All P0 tests pass** — 30+ critical tests passing on Android device & Firebase emulator
2. **Permission model holds** — No child can modify buckets, no family leakage
3. **Data consistency** — Multi-parent edits resolve deterministically
4. **Offline works** — Changes queue & sync on reconnect
5. **Audit trail accurate** — All transactions logged with timestamp, actor, values
6. **Kid UX validated** — Child can login, view buckets, donate (no parent intervention needed)
7. **Parent controls solid** — Parent can set money, multiply investments, manage family
8. **Zero security issues** — Fury (Security & Auth) sign-off on auth, permission checks, token handling

---

**Document Owner:** Happy (QA/Tester)  
**Last Review:** 2026-04-05  
**Next Review:** After MVP launch
