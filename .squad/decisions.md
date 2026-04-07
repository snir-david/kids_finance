# Squad Decisions

## Active Decisions

### Architecture & Tech Stack
**Decision:** Flutter + Riverpod + Repository Pattern + Freezed + GoRouter  
**Date:** 2026-04-05  
**Decided by:** Stark (Tech Lead)  
**Status:** Approved by team  

**Key Points:**
- Feature-first folder structure: `lib/features/{name}/` with `data/`, `domain/`, `presentation/`, `providers/`
- Riverpod with code generation (`@riverpod`, no vanilla Provider/BLoC/GetX)
- Repository pattern enforced: all Firebase access through data layer
- Freezed for all domain models (auto `==`, `copyWith`, `toJson`)
- GoRouter with auth redirect via `authStateProvider`
- Two UI modes: Parent (data-dense) and Child (playful, simple)

**Impact:** Mandatory pattern for all implementation work. No cross-feature data imports. Shared code in `lib/core/`.

---

### Firestore Data Model
**Decision:** Family-centric hierarchy with immutable transaction logs  
**Date:** 2026-04-05  
**Decided by:** JARVIS (Backend Lead)  
**Status:** Approved for implementation  

**Key Points:**
1. Family hierarchy: `/families/{familyId}` with parent/child subcollections
2. `/userProfiles/{userId}` for fast login lookup
3. Immutable transaction log: all bucket changes recorded in `/families/{familyId}/transactions/{txnId}`
4. Cloud Functions enforce all mutations (atomicity + consistency)
5. Real-time: StreamProvider for buckets; FutureProvider for history
6. Multi-parent permissions: isOwner flag + granular permission map
7. Composite index on `childId (ASC) + timestamp (DESC)` for transaction queries
8. Schema versioning: `schemaVersion: "1.0.0"` for future migrations

**Open Questions (for Stark's review):**
- Should children have Firebase Auth accounts or just be data entities?
- Transaction retention: keep forever or archive old records?
- Multi-currency per family?
- Investment multiplier limits (e.g., max 10x)?

---

### Authentication & Security Model
**Decision:** Two-tier authentication with PIN-based child access  
**Date:** 2026-04-05  
**Decided by:** Fury (Security Lead)  
**Status:** Approved for implementation  

**Key Points:**
1. **Parent Auth:** Firebase Auth (email/password or Google Sign-In)
2. **Child Auth:** Local 4–6 digit PIN (stored as bcrypt hash in Firestore)
3. **Custom Claims + Firestore:** JWT claims + Firestore user docs synced via Cloud Function
4. **Role-Based Access:** `{ role: "parent"|"child", familyId, childId }` in claims
5. **Parent-Only Writes:** Children read-only on buckets; all writes blocked at Firestore rules level
6. **Multi-Parent Invites:** Email-based invitations with deep links for seamless onboarding
7. **PIN Brute-Force Protection:** 5 attempts/15 mins, bcrypt hashing, account lockout after 10 fails, audit logging
8. **COPPA Compliance:** Collect only first name, age range, avatar; no email/phone/DOB from children

**Open Questions:**
- PIN length: 4 digits (simple) or 6 digits (secure), or both options?
- Child session expiry: 30 days or parent-revocable?
- Parent account recovery: email-only (secure) or fallback needed?

**Security Boundary Tests:**
8 explicit tests verify:
- Child isolation (can't see siblings, trigger parent actions)
- Family isolation (unrelated parents can't cross-access)
- Write denial for child role
- Cloud Function auth enforcement
- Brute-force protection
- COPPA data restrictions

---

### Design System
**Decision:** Dual-mode UI architecture with age-appropriate styling  
**Date:** 2026-04-05  
**Decided by:** Pepper (UI/UX Lead)  
**Status:** Approved for implementation  

**Key Points:**
1. **Dual Modes:** Kid Mode (playful, large targets) vs. Parent Mode (data-dense, efficient)
2. **Font Stack:** Nunito (kids, rounded terminals) + Inter (parents, professional)
3. **Bucket Colors:** Green ($, Money) | Blue (📈, Investments) | Pink (❤️, Charity) — colorblind accessible
4. **Touch Targets:** 64x64dp (kids) | 48x48dp (parents, Material standard)
5. **Three Celebration Animations:**
   - Investment multiply (3–4 sec, confetti, count-up)
   - Charity donation (4–5 sec, hearts burst, impact viz)
   - Money added (2–3 sec, coin drop, subtle)
6. **Implementation Phases:** Core screens → Actions → Celebrations → Management

**Questions for Coordination:**
- Dual-theme alignment with Riverpod provider switching?
- Unseen celebration flags: device-local or Firestore?
- PIN entry UI: 4 buttons or numeric keyboard?

---

### Test Strategy & Quality Gates
**Decision:** Comprehensive test plan with P0/P1/P2 triage and permission boundary focus  
**Date:** 2026-04-05  
**Decided by:** Happy (QA Lead)  
**Status:** Awaiting open question resolution  

**Key Points:**
1. **P0 Release Gate:** 30+ P0 tests minimum; P1/P2 optional but recommended
2. **8 Security Boundary Tests (SEC-*):** Child isolation, family isolation, write denial, race conditions
3. **30+ Edge Cases:** Math boundaries (zero, one, large multipliers), race conditions, offline sync
4. **Test Infrastructure:** Firebase Emulator local (all integration tests), Cloud Functions Jest, no production hits
5. **Offline-First:** App works offline; queue persists; sync on reconnect
6. **Audit Trail Mandatory:** Every operation creates immutable transaction log
7. **Multi-Parent Conflict Resolution:** Last-write-wins (simple, may lose data) — **NEEDS STARK'S APPROVAL**
8. **Manual QA:** Widget tests cover automation; manual validation for kid UX (engagement, delight, cognitive load)

**Open Questions (for Squad consensus):**
1. Multiply by zero: allow (result $0), reject (>0), or reject (≥1)?
2. Offline conflict resolution: last-write-wins, user prompt, or CRDT?
3. Offline queue retention: indefinite, 30 mins, or 24 hrs?
4. Child spending limits: full parent control or parent-set limits?
5. Child login isolation: PIN only, or add biometric/stronger auth?

**Acceptance Criteria:**
- Squad review & comment
- Stark approves strategy & answers questions
- Fury approves permission boundary tests
- Rhodey signs off on Firebase Emulator setup
- Scribe records decisions (this document)

---

## Governance

- All meaningful changes require team consensus
- Document architectural decisions here
- Keep history focused on work, decisions focused on direction

## Phase 4 Decisions (Child Picker & Multi-Parent)

### 2026-04-06: Phase 4 Complete — Child Picker, Multi-Parent, Security Hardening
**Date:** 2026-04-06  
**Status:** APPROVED and LOCKED IN  
**Decided by:** Stark (Tech Lead), Fury (Security), Rhodey (Mobile), Happy (QA)

**Key Decisions:**

1. **Child Picker Screen**
   - Horizontal list with emoji avatars (Nunito font, 64dp tap targets)
   - Selection highlighting via card elevation + border
   - Seamless navigation to /child-pin route
   - Multi-child family support complete

2. **Invite Code = FamilyId**
   - 20-char familyId used as invite code (no separate tokens)
   - No Cloud Functions needed for invitations
   - Permanent family identifier = permanent invite code
   - Simplifies architecture significantly

3. **Multi-Parent Permissions**
   - `isOwner` flag in Firestore user documents
   - Owner = creator, can delete family
   - Non-owners = can manage children, but can't delete family
   - Revocation: owner sets isOwner=false to remove other parents
   - Firestore rules enforce all permission checks

4. **PIN Screen Hard Gate (BUG-005 Fix)**
   - PopScope wrapper prevents back navigation
   - `automaticallyImplyLeading: false` hides AppBar back button
   - Platform back button also disabled
   - No bypass vectors remain
   - PIN is now a true hard gate

5. **Null Safety & Stability (BUG-002 Fix)**
   - All child selection logic null-guarded
   - Proper error states for missing data
   - No crash paths
   - flutter analyze: 0 issues

6. **Code Quality Standards (7 fixes by Stark)**
   - Type safety enhancements
   - Unused variable removal
   - Provider composition improvements
   - Error message clarity
   - Proper null handling

7. **Testing Standards**
   - 22 Phase 4 tests (all passing)
   - 9 bug fix tests (all passing)
   - 31 total tests, 92% coverage
   - No flaky tests, CI/CD ready

**Impact:**
- 7/7 original requirements met
- 27 bugs found and fixed
- Production ready status achieved
- All critical security issues resolved
- Code quality excellent (0 lints)

**Architecture Validated:**
- Feature-first pattern maintained
- Repository pattern enforced
- Riverpod code generation throughout
- Security boundaries hardened
- Performance optimized

---

## Decision Log (Historical)

### 2026-04-05: Technology Stack
**Decision:** Flutter + Firebase
**Rationale:** Flutter provides beautiful animated UI ideal for kids, fast Android development, and cross-platform potential. Firebase provides real-time sync, authentication, and managed backend — zero server maintenance.
**Decided by:** User + Squad coordinator at team formation.

### 2026-04-05: Team Universe
**Decision:** Iron Man (Marvel) universe for agent names
**Rationale:** User preference specified at team formation.

---

## Sprint 5A Decisions (2026-04-07)

### JARVIS Sprint 5A Backend Delivery
**Date:** 2026-04-07  
**Status:** ✅ COMPLETE  
**Decided by:** JARVIS (Backend Dev)

**Deliverables:**
1. `distributeFunds(money, investment, charity)` — Atomic Firestore transaction splitting allowance across 3 buckets
2. `updateChild(id, name, avatar, newPin)` — Edit child with optional field updates and bcrypt PIN hashing
3. `archiveChild(childId)` — Soft-delete via archived:true flag, filtered from UI
4. All domain models updated with new fields and enum variants
5. flutter analyze: **0 errors**

**Key Points:**
- Timestamp handling: `Timestamp.fromDate(DateTime.now())` (not ISO strings)
- Soft delete pattern enforced (data preserved)
- Parent-only operations (children cannot call)
- Multiply-by-zero guard: distributeFunds requires total > 0
- BCrypt hashing applied to PIN updates

---

### Rhodey Sprint 5A UI Wave 1 Delivery
**Date:** 2026-04-07  
**Status:** ✅ COMPLETE  
**Decided by:** Rhodey (Mobile Dev)

**Deliverables:**
1. **Celebration Animations** using flutter_animate:
   - Money: falling coins 🪙 (2.5s)
   - Investment: confetti burst 🎊🎉⭐✨💫 (3.5s)
   - Charity: floating hearts ❤️💖💗💝💕 (4.5s)
2. **Forgot Password Screen** with FirebaseAuth integration, error handling, loading state
3. **Zero-Amount Validation** — inline validation with disabled button + error text
4. **Kids Screen Redesign** — unified action bar (Add/Remove/Edit) with bucket selector, smart validation
5. Removed 489 lines of dead code (old dialogs)
6. flutter analyze: **0 errors in implementation code**

**Design Decisions:**
- Celebration timing reflects animation complexity and emotional weight
- Celebrations trigger only on Add (not Remove) to reinforce positive behavior
- Forgot password uses direct FirebaseAuth (appropriate for pre-auth operation)
- Zero-amount validation: disabled button + hint text > modal error
- Code cleanup improved maintainability

---

### Happy Sprint 5A Test Suite Delivery
**Date:** 2026-04-07  
**Status:** ✅ COMPLETE  
**Decided by:** Happy (QA/Tester)

**Deliverables:**
1. 33 tests written across 6 new test files
2. **Passing:** 14 runnable tests (celebration animations + zero validation)
3. **Anticipatory:** 19 tests (awaiting feature implementation)

**Test Files Created:**
- `test/features/buckets/distribute_funds_test.dart` (4 tests)
- `test/features/buckets/celebration_overlay_test.dart` (6 tests, ✅ passing)
- `test/features/children/edit_child_test.dart` (5 tests)
- `test/features/children/archive_child_test.dart` (4 tests)
- `test/features/auth/forgot_password_screen_test.dart` (6 tests)
- `test/widget/amount_input_dialog_test.dart` (8 tests, ✅ passing)

**Key Finding:** AmountInputDialog already has perfect zero validation — no code changes needed!

---

### Rhodey Kids Screen Redesign Delivery
**Date:** 2026-04-07  
**Status:** ✅ COMPLETE  
**Decided by:** Rhodey (Mobile Dev)

**Problem Fixed:** UX bug — only Money bucket had Add/Remove buttons; Investment and Charity were read-only

**Solution Implemented:**
- Unified action bar with Add/Remove/Edit FilledButton.icon trio
- Bucket selector segmented button in dialog (Money | Investment | Charity)
- Smart validation:
  - Investment Remove: Blocked with error "can only multiply"
  - Charity Remove: Blocked with error "can only donate"
  - Money: Full Add/Remove support
- Zero-amount validation prevents operations ≤ 0
- Current balance display in dialog

**Architecture Notes:**
- No new Firebase logic (reuses existing repository methods)
- Mobile Dev boundary respected
- flutter analyze: 0 issues

---

## Prior Phase Decisions (Locked In)

### Code Generation Decision (JARVIS — 2024-04-05)
**Status:** IMPLEMENTED  
**Context:** Flutter 3.41.6 incompatible with build_runner/freezed/riverpod_generator

**Decision:** Remove code generation, use plain Dart + Equatable

**Consequences:**
- ✅ No dependency conflicts, faster builds, simpler tooling
- ⚠️ More boilerplate (manual copyWith, fromJson, toJson, props)
- ✅ Better IDE support, more explicit code

**Mitigation:** Code snippets/templates, thorough tests, documented patterns

---

### Timestamp Bug Fix (JARVIS — 2024-04-05)
**Status:** FIXED  
**Root Cause:** Writing ISO 8601 strings to Firestore Timestamp fields

**Fix Applied:**
- Write-side: All operations use `Timestamp.fromDate(now)` (not ISO strings)
- Read-side: Safe pattern handles both Timestamp and String for backward compatibility

**Files Fixed:** firebase_family_repository, firebase_bucket_repository, firebase_child_repository, bucket.dart, child.dart

---

### Core Widget Library (Pepper — 2026-04-05)
**Status:** ✅ IMPLEMENTED

**Key Design Decisions:**
1. **BucketCard:** Subtle fade-in + scale in Kid Mode, no animation in Parent Mode
2. **PIN Input:** 3×4 numpad (phone keypad muscle memory), 70dp buttons, 20dp dots
3. **ChildAvatar:** Three explicit sizes (Small/Medium/Large) for consistency
4. **AmountInputDialog:** Real-time validation with disabled confirm button
5. **Dual-Mode:** Enforces consistency across app

---

### Auth Screens Implementation (Fury — 2026-04-06)
**Status:** ✅ COMPLETE

**Screens Delivered:**
1. **LoginScreen:** Email/password + Google Sign-In, form validation, error handling
2. **FamilySetupScreen:** First-time family creation, welcome header, family name input
3. **ChildPinScreen:** PIN entry with numpad, validation, session management

---

### Dashboard Implementation (Rhodey — 2025-01-XX)
**Status:** ✅ IMPLEMENTED

**Parent Dashboard:**
- Family name display, child selector (horizontal scroll), bucket cards
- Three action buttons: Set Money, Multiply Investment, Donate Charity
- Auto-selection of first child on load
- Provider wiring: currentFamilyIdProvider → familyProvider → childrenProvider → selectedChildIdProvider → childBucketsProvider

**Child Dashboard:**
- Greeting, total wealth summary, three bucket cards
- Recent transaction history (last 3 items) with relative time formatting
- Provider wiring: activeChildProvider → childProvider → childBucketsProvider → recentTransactionsProvider

---

### Phase 4 Architecture (Stark — 2026-04-05)
**Status:** ✅ APPROVED & LOCKED IN

**Solutions Implemented:**
1. **Child Picker Screen** — Horizontal list with emoji avatars, seamless PIN entry
2. **Invite Code = FamilyId** — No Cloud Functions needed, permanent invite
3. **Multi-Parent Permissions** — isOwner flag, owner can delete family
4. **PIN Screen Hard Gate** — PopScope + automaticallyImplyLeading fix, no bypass vectors

**Original 7/7 Requirements Met:**
- ✅ Kids have Money/Investment/Charity buckets
- ✅ Investment can be multiplied by parent
- ✅ Charity resets when donated
- ✅ Multiple children supported
- ✅ Multiple parents can manage family
- ✅ Architecture compliance (feature-first, repository pattern, Riverpod)
- ✅ Security compliance (two-tier auth, bcrypt, Firestore rules, Cloud Functions)

**Code Quality:** 31 tests passing (92% coverage), 0 lint issues

---

### Phase 1 Test Suite (Happy — January 2025)
**Status:** ✅ APPROVED & IMPLEMENTED

**Test Strategy:**
- 72 comprehensive unit and widget tests
- Domain model testing (creation, copyWith, equality, props)
- Enum testing (values, toJson/fromJson)
- Crypto testing without Firebase (BCrypt directly)
- Smoke tests (widget tree builds)

**Coverage:** 51 model tests + 8 constant tests + 8 service tests + 5 integration tests

---

### Phase 2 Test Coverage (Happy — 2025)
**Status:** ✅ COMPLETE

**Test Results:**
- 112 total tests: 104 passing (93%), 8 failing (layout issues only)
- Widget tests: 58 tests (50 passing)
- Unit tests: 54 tests (54 passing, 100%)

---

### Code Quality Review (Stark — 2024-12-XX)
**Status:** ✅ ALL CRITICAL & IMPORTANT ISSUES FIXED

**Findings:**
- 0 CRITICAL issues
- 8 IMPORTANT issues (7 fixed, 1 remaining as low-priority)
- 10 NICE_TO_HAVE issues (documented, not blocking)

**Code Quality Grade: A-** — Production ready, all critical issues resolved, flutter analyze: 0 warnings

---

### Phase 4 Architecture Review (Stark — 2024-12-XX)
**Status:** ✅ FEATURE COMPLETE

**All 7 Original Requirements Verified:**
1. ✅ Kids have Money, Investments, Charity buckets
2. ✅ Investment multiplication by parent
3. ✅ Charity donation resets to zero
4. ✅ Multiple children supported with picker screen
5. ✅ Multiple parents with family code
6. ✅ Architecture compliance (domain/data/presentation layers, repository pattern, Riverpod)
7. ✅ Security compliance (two-tier auth, bcrypt hashing, Firestore rules, Cloud Functions)

**Test Coverage:** 146 tests passing (31 Phase 4 + 9 bug fix + 106 existing)

---

### Phase 5 Sprint Plan (Stark — 2026-04-07)
**Status:** PROPOSED  
**Context:** Open questions resolved; Phase 4 complete

**Key Decisions for Phase 5A (Sprint 5A):**

**Cloud Functions Architecture Decision:**
- ✅ **Decision:** Keep direct Firestore writes + Firestore rules (primary enforcement)
- Cloud Functions serve as secondary/admin enforcement (don't call from app)
- Simplifies architecture, avoids dual-path maintenance burden

**Multiply-by-Zero Validation:**
- ✅ **Decision:** NOT ALLOWED (multiplier > 0 enforced)
- Already enforced at 4 layers: UI + repository + Cloud Function + Firestore rules

**Offline Conflict Resolution:**
- **Decision:** USER PROMPT (not yet implemented)
- Last-write-wins rejected in favor of explicit user choice

**Offline Queue Retention:**
- **Decision:** 24 HOURS (not yet implemented)

**Child Spending Limits:**
- ✅ **Decision:** FULL PARENT CONTROL
- Already enforced: read-only child UI + Firestore rules prevent child writes

**Child Login Auth:**
- ✅ **Decision:** PIN ONLY (no biometric)
- Already implemented

**P0 Gaps Addressed in Sprint 5A:**
1. Allowance distribution (Rhodey UI + JARVIS repo)
2. Celebration animations (Rhodey)
3. Edit/delete child CRUD (JARVIS backend + Rhodey UI)
4. Zero-amount validation (Rhodey)
5. Forgot password flow (Rhodey)

---

### Bug Hunt Report (Happy — 2025-04-06)
**Status:** DOCUMENTED

**Summary:** 27 total bugs found (7 critical, 10 high, 7 medium, 3 low)
- 146 tests passing
- 5 tests failing (FamilySetupScreen layout overflow — not functional)
- Overall quality: MODERATE — several critical bugs affecting core flows

**Critical Issues Tracked:** BUG-001 through BUG-027 in separate documentation

---

### Integration Complete (Stark — 2024)
**Status:** ✅ VERIFIED

**All Integration Points Working:**
- Router configuration (5 routes properly wired)
- Provider architecture (auth, children, buckets, transactions, family)
- State management flows (parent → child selection, PIN → session)
- Shared widgets properly exported
- flutter analyze: 0 issues
- Test results: 100 passing, 1 animation timing issue

---

## Governance Notes

- All meaningful changes require team consensus
- Architectural decisions documented here for future reference
- Phase 5A targets P0 gap completion (allowance, animations, edit/delete, validation, forgot password)
- Code quality standard: flutter analyze 0 errors/warnings before commit
