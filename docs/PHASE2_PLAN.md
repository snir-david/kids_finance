# KidsFinance Phase 2: Screen Implementation Plan

**Tech Lead:** Stark  
**Version:** 1.0  
**Date:** 2026-04-05

---

## Overview

**Phase 1 Status:** ✅ Complete  
- Architecture defined
- Data models implemented (Family, ParentUser, Child, Bucket, Transaction, AppUser)
- Riverpod providers set up for all features
- Repository pattern established (abstract interfaces + Firebase implementations)
- GoRouter configured with auth-aware redirects
- Dual themes defined (Kid Mode + Parent Mode)
- Firestore security rules in place
- Auth services implemented (Firebase Auth + PIN service with brute-force protection)

**Phase 2 Goal:** Build all user-facing screens and wire them to the data layer.

**Success Criteria:**
- Parents can log in → see all children → modify bucket balances
- Children can log in with PIN → view their 3 buckets (read-only)
- Investment multiplier triggers celebration animation
- Charity donation triggers celebration animation
- All actions create immutable transaction logs
- App works end-to-end with real Firestore data

---

## Phase 2 Goals

### Parent Journey
1. **Login** → Email/password or Google Sign-In
2. **Family Setup** → First-time users create family + add first child
3. **Parent Dashboard** → View all children, select one to manage
4. **Bucket Actions:**
   - Set Money (input dollar amount)
   - Multiply Investment (input multiplier, see celebration)
   - Donate Charity (reset to $0, see celebration)
5. **Transaction History** → View log of all actions per child

### Child Journey
1. **Child PIN Entry** → 4-digit PIN with brute-force feedback
2. **Kid Dashboard** → View 3 buckets with playful UI
3. **Celebration Screens** → Full-screen animations for investment/charity events
4. **Transaction History** → View recent transactions (last 5-10)

---

## Architecture Decisions for Phase 2

### 1. UI Mode Switching

**Decision:** Use a `StateProvider` to toggle between themes.

```dart
// In core/theme/theme_providers.dart
final currentThemeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.parent);

enum ThemeMode { parent, kid }

// In app.dart
final themeMode = ref.watch(currentThemeProvider);
final theme = themeMode == ThemeMode.kid
    ? AppTheme.kidTheme()
    : AppTheme.parentTheme();

return MaterialApp.router(
  theme: theme,
  // ...
);
```

**Switching Logic:**
- Parent login → `ThemeMode.parent`
- Child PIN success → `ThemeMode.kid`
- Logout → reset to `ThemeMode.parent`

**Owner:** Pepper (design tokens), Rhodey (implementation)

---

### 2. Provider Usage per Screen

| Screen | Providers Used | Why |
|--------|---------------|-----|
| **LoginScreen** | `firebaseAuthStateProvider` | Check if already logged in, redirect if so |
| **FamilySetupScreen** | `currentFamilyIdProvider`, `familyProvider` | Create family, add first child |
| **ParentDashboard** | `currentFamilyIdProvider`, `childrenProvider`, `selectedChildProvider` | List all children, track selection |
| **ChildDetailView** | `childBucketsProvider`, `totalWealthProvider` | Show 3 buckets + total balance |
| **ChildPinScreen** | `activeChildProvider`, `PinService` (not a provider, just a service) | Verify PIN, create session |
| **KidDashboard** | `activeChildProvider`, `childBucketsProvider`, `recentTransactionsProvider` | Show child's 3 buckets + recent history |
| **TransactionHistory** | `transactionHistoryProvider` | Show full audit log |

**Key Insight:** Most screens will use `family` + `child` + `buckets` providers in combination. Derive the familyId from `currentFamilyIdProvider`.

---

### 3. Navigation Flow

**Parent Flow:**
```
/login → /parent-home → (select child) → /parent-home (with selectedChildProvider set)
                      ↓
                  [Bottom sheet actions: Set Money, Multiply, Donate]
                      ↓
                  [Celebration animation] → back to /parent-home
```

**Child Flow:**
```
/login → /child-pin → /child-home → [View-only buckets]
                                  ↓
                              /transaction-history (read-only)
```

**Implementation:**
- Parent screens use bottom sheets/dialogs for actions (no new routes)
- Child screens are full-screen, no bottom sheets (keep UX simple)
- Celebration animations overlay on current screen (use `showDialog` with custom animation)

---

### 4. Bucket Action Patterns

All bucket modifications follow this pattern:

1. **Parent initiates action** (e.g., taps "Multiply Investment")
2. **Show input dialog** (e.g., "Enter multiplier: 1.5×")
3. **Validate input** (e.g., multiplier > 0.01)
4. **Call repository method** (e.g., `bucketRepository.multiplyInvestment(childId, familyId, multiplier)`)
5. **Repository updates bucket + creates transaction** (atomic Firestore batch write)
6. **StreamProvider rebuilds** → UI updates automatically
7. **Show celebration animation** (if investment or charity)

**Key:** All mutations go through repositories. Widgets never call Firestore directly.

---

### 5. Celebration Animation Strategy

**Trigger Logic:**
- **Investment Multiply:** When `transactionHistoryProvider` emits a new transaction with `type == investmentMultiplied`, check if user has seen this transaction
- **Charity Donation:** When `type == charityDonated`, check if user has seen this transaction

**Tracking "Unseen" Celebrations:**

**Option A (Simple):** Device-local flag in `SharedPreferences`
```dart
final seenTransactions = await SharedPreferences.getInstance();
final key = 'seen_txn_${txnId}';
if (!seenTransactions.containsKey(key)) {
  // Show celebration
  await seenTransactions.setBool(key, true);
}
```

**Option B (Cross-Device):** Firestore field `celebrationSeenAt: Timestamp?` on transaction
- Pro: Works across devices
- Con: Requires extra Firestore write

**Decision for Phase 2:** Use Option A (device-local). Option B is a Phase 3 enhancement.

**Owner:** Pepper (animation design), Rhodey (implementation)

---

### 6. Error Handling Pattern

**UI-Friendly Error Messages:**

All repository methods return `Result<T, AppError>` (to be added in Phase 2):

```dart
sealed class AppError {
  String get userMessage;
}

class NetworkError extends AppError {
  String get userMessage => 'No internet connection. Try again.';
}

class PermissionError extends AppError {
  String get userMessage => 'You don't have permission to do that.';
}

class ValidationError extends AppError {
  final String message;
  String get userMessage => message;
}
```

**Widget Error Handling:**
```dart
final result = await ref.read(bucketRepositoryProvider).setMoney(...);
result.fold(
  onSuccess: (bucket) {
    // Show success snackbar
  },
  onError: (error) {
    // Show error snackbar with error.userMessage
  },
);
```

**Owner:** JARVIS (backend error types), Rhodey (UI error handling)

---

## Step-by-Step Implementation Plan

### Phase 2 Breakdown (6 Steps)

Each step is a self-contained unit of work that can be executed sequentially.

---

## **Step 1: Core Widgets**

**Goal:** Build reusable UI components used across all screens.

### Widgets to Build

1. **BucketCard** (`lib/core/widgets/bucket_card.dart`)
   - Props: `BucketType type, double balance, VoidCallback? onTap`
   - Layout: Icon (emoji) + Label + Balance
   - Kid Mode: Large (64dp height), rounded corners, Nunito font
   - Parent Mode: Compact (48dp height), Inter font

2. **ChildAvatar** (`lib/core/widgets/child_avatar.dart`)
   - Props: `String emoji, double size`
   - Circular container with emoji centered

3. **PinInputWidget** (`lib/core/widgets/pin_input_widget.dart`)
   - 4-dot PIN display (filled/empty states)
   - Numpad (0-9 + backspace)
   - Callback: `void Function(String pin)`
   - Show brute-force feedback: "X attempts remaining" or "Locked until Y"

4. **LoadingOverlay** (`lib/core/widgets/loading_overlay.dart`)
   - Full-screen semi-transparent overlay with spinner
   - Used during async operations

5. **ErrorWidget** (`lib/core/widgets/error_widget.dart`)
   - Red banner with error message + retry button
   - Props: `String message, VoidCallback onRetry`

6. **CelebrationAnimation** (`lib/core/widgets/celebration_animation.dart`)
   - Full-screen overlay with Lottie animation
   - Two variants: `investment` (confetti) and `charity` (hearts)
   - Auto-dismiss after 3-5 seconds

### Files to Create
- `lib/core/widgets/bucket_card.dart`
- `lib/core/widgets/child_avatar.dart`
- `lib/core/widgets/pin_input_widget.dart`
- `lib/core/widgets/loading_overlay.dart`
- `lib/core/widgets/error_widget.dart`
- `lib/core/widgets/celebration_animation.dart`

### Dependencies
- None (this is the foundation)

### Owner
- **Pepper:** Design specifications (colors, sizing, animation timing)
- **Rhodey:** Implementation

### Acceptance Criteria
- [ ] BucketCard displays correctly in both Kid + Parent themes
- [ ] PinInputWidget handles 4-digit input with backspace
- [ ] CelebrationAnimation plays confetti and hearts (use `lottie` package or custom AnimatedBuilder)
- [ ] All widgets are documented with dartdoc comments

---

## **Step 2: Auth Screens**

**Goal:** Build login and family setup flows.

### Screens to Build

1. **LoginScreen** (`lib/features/auth/presentation/login_screen.dart`)
   - Email/password form (TextFormField with validation)
   - "Sign in with Google" button (with Google logo)
   - "Forgot Password?" link
   - "Create Account" button → calls `AuthService.createAccountWithEmailPassword()`
   - On success: `firebaseAuthStateProvider` rebuilds → GoRouter redirects to `/parent-home`
   - Use `LoadingOverlay` during sign-in

2. **FamilySetupScreen** (`lib/features/auth/presentation/family_setup_screen.dart`)
   - First-time onboarding screen (triggered when parent has no family)
   - Step 1: "Name your family" (text input)
   - Step 2: "Add your first child" (name + emoji picker + PIN setup)
   - Calls `AuthService.createFamily()` + `ChildRepository.createChild()`
   - On success: redirect to `/parent-home`

3. **ChildPinScreen** (`lib/features/auth/presentation/child_pin_screen.dart`)
   - Uses `PinInputWidget`
   - Shows child avatar + name at top
   - On correct PIN: set `activeChildProvider`, switch to `ThemeMode.kid`, navigate to `/child-home`
   - On wrong PIN: show `PinWrongPin.attemptsRemaining` message
   - On locked: show `PinLocked.unlocksAt` countdown timer

### Files to Create
- `lib/features/auth/presentation/login_screen.dart` (replace stub)
- `lib/features/auth/presentation/family_setup_screen.dart` (replace stub)
- `lib/features/auth/presentation/child_pin_screen.dart` (replace stub)

### Files to Modify
- `lib/routing/app_router.dart` (add `/family-setup` route, update redirect logic to check for familyId)

### Dependencies
- Step 1 (Core Widgets) must be complete

### Owner
- **Fury:** Security logic (PIN verification, brute-force feedback)
- **Rhodey:** UI implementation
- **JARVIS:** Firestore wiring (family creation, child creation)

### Acceptance Criteria
- [ ] Parent can create account → create family → add first child
- [ ] Parent can log in with email/password or Google
- [ ] Child can enter PIN → see brute-force feedback → unlock after 15 mins
- [ ] Firestore `/userProfiles/{uid}` and `/families/{familyId}` documents created correctly
- [ ] GoRouter redirects work (login → family-setup → parent-home)

---

## **Step 3: Parent Dashboard**

**Goal:** Build the main parent screen showing all children with bucket overviews.

### Screens to Build

1. **ParentHomeScreen** (`lib/features/auth/presentation/parent_home_screen.dart`)
   - AppBar: Family name (from `familyProvider`), logout button
   - Body: List of children (from `childrenProvider`)
   - Each child card:
     - Avatar (emoji)
     - Name
     - Total wealth (from `totalWealthProvider`)
     - 3 mini bucket cards (from `childBucketsProvider`)
     - Tap to expand → show action buttons
   - FAB: "Add Child" → navigate to AddChildScreen

2. **ChildSelectorWidget** (`lib/features/auth/presentation/widgets/child_selector_widget.dart`)
   - Horizontal scrollable list of child avatars
   - Tapping a child sets `selectedChildProvider`
   - Selected child has highlight border

3. **BucketsOverview** (`lib/features/auth/presentation/widgets/buckets_overview.dart`)
   - For the selected child, show 3 full-size `BucketCard` widgets
   - Each card is tappable → shows action bottom sheet

4. **Action Bottom Sheets:**
   - **SetMoneySheet** (`lib/features/auth/presentation/widgets/set_money_sheet.dart`)
     - Input: dollar amount (TextField with number keyboard)
     - Button: "Set Money"
     - Calls `bucketRepository.setMoney(childId, familyId, amount)`
   - **MultiplyInvestmentSheet** (`lib/features/auth/presentation/widgets/multiply_investment_sheet.dart`)
     - Input: multiplier (TextField, validates > 0.01)
     - Preview: "New balance: $X × Y = $Z"
     - Button: "Multiply"
     - Calls `bucketRepository.multiplyInvestment(...)`
     - On success: show `CelebrationAnimation.investment`
   - **DonateCharitySheet** (`lib/features/auth/presentation/widgets/donate_charity_sheet.dart`)
     - Confirmation message: "Donate $X to charity? This will reset the balance to $0."
     - Button: "Donate"
     - Calls `bucketRepository.donateCharity(...)`
     - On success: show `CelebrationAnimation.charity`

### Files to Create/Modify
- `lib/features/auth/presentation/parent_home_screen.dart` (replace stub)
- `lib/features/auth/presentation/widgets/child_selector_widget.dart`
- `lib/features/auth/presentation/widgets/buckets_overview.dart`
- `lib/features/auth/presentation/widgets/set_money_sheet.dart`
- `lib/features/auth/presentation/widgets/multiply_investment_sheet.dart`
- `lib/features/auth/presentation/widgets/donate_charity_sheet.dart`

### Files to Add (Repository Methods)
- `lib/features/buckets/data/firebase_bucket_repository.dart`
  - Add methods:
    - `Future<void> setMoney(String childId, String familyId, double amount)`
    - `Future<void> multiplyInvestment(String childId, String familyId, double multiplier)`
    - `Future<void> donateCharity(String childId, String familyId)`
  - Each method:
    1. Fetches current bucket balance
    2. Computes new balance
    3. Writes batch:
       - Update bucket balance + lastUpdatedAt
       - Create transaction document
    4. Commits batch atomically

### Dependencies
- Step 1 (Core Widgets)
- Step 2 (Auth Screens) — parent must be logged in to see dashboard

### Owner
- **Rhodey:** Parent dashboard UI
- **JARVIS:** Repository methods (Firestore atomic writes)
- **Pepper:** Action sheet design, celebration animations

### Acceptance Criteria
- [ ] Parent sees list of all children in family
- [ ] Parent can select a child → see 3 buckets
- [ ] Parent can tap "Set Money" → input amount → bucket balance updates
- [ ] Parent can tap "Multiply Investment" → input multiplier → see celebration animation → bucket balance updates
- [ ] Parent can tap "Donate Charity" → confirm → see celebration animation → bucket resets to $0
- [ ] Each action creates a transaction document in Firestore
- [ ] StreamProviders rebuild automatically (no manual refresh)

---

## **Step 4: Kid Dashboard**

**Goal:** Build the child-facing dashboard with playful UI.

### Screens to Build

1. **ChildHomeScreen** (`lib/features/auth/presentation/child_home_screen.dart`)
   - Uses `AppTheme.kidTheme()` (Nunito font, large tap targets)
   - AppBar: Child avatar + name, "Logout" button (clears session, returns to `/child-pin`)
   - Body: 3 full-size `BucketCard` widgets (read-only, no tap actions)
   - Layout: Vertical stack with generous spacing
   - Show total wealth at top: "You have $X total!"
   - Bottom section: "Recent Activity" → last 5 transactions (from `recentTransactionsProvider`)

2. **TransactionListItem** (`lib/core/widgets/transaction_list_item.dart`)
   - Shows: emoji (based on `TransactionType`), description, amount, date
   - Examples:
     - 💰 "Money added: +$25.00" (Apr 5)
     - 📈 "Investment multiplied: $10 → $15" (Apr 4)
     - ❤️ "Charity donated: $5" (Apr 3)

### Files to Create/Modify
- `lib/features/auth/presentation/child_home_screen.dart` (replace stub)
- `lib/core/widgets/transaction_list_item.dart`

### Files to Modify
- `lib/app.dart` — add logic to switch theme based on `currentThemeProvider`

### Dependencies
- Step 1 (Core Widgets)
- Step 2 (Auth Screens) — child must enter PIN to see dashboard

### Owner
- **Rhodey:** Kid dashboard UI
- **Pepper:** Kid-friendly visual design (emoji, colors, layout)

### Acceptance Criteria
- [ ] Child sees their 3 buckets with current balances
- [ ] Child sees total wealth at top
- [ ] Child sees last 5 transactions in "Recent Activity"
- [ ] Child can tap "Logout" → session cleared → return to `/child-pin`
- [ ] UI uses Nunito font, large buttons (64dp), playful colors

---

## **Step 5: Navigation Wiring**

**Goal:** Replace all stub screens in GoRouter with real implementations.

### Tasks

1. **Update `app_router.dart`:**
   - Remove stub screens (`SplashScreen`, etc.)
   - Add real screen imports
   - Add new routes:
     - `/family-setup` (for first-time users)
     - `/transaction-history/:childId` (for viewing full transaction log)
   - Update redirect logic:
     - If `currentFamilyIdProvider` is null → `/family-setup`
     - If parent is logged in → `/parent-home`
     - If child session is active → `/child-home`

2. **Add Theme Switching Logic in `app.dart`:**
   ```dart
   final themeMode = ref.watch(currentThemeProvider);
   final theme = themeMode == ThemeMode.kid
       ? AppTheme.kidTheme()
       : AppTheme.parentTheme();
   
   return MaterialApp.router(
     theme: theme,
     // ...
   );
   ```

3. **Test Navigation Flows:**
   - Parent login → dashboard → select child → action → celebration → back to dashboard
   - Child PIN → dashboard → logout → back to PIN
   - First-time user → family setup → add child → dashboard

### Files to Modify
- `lib/routing/app_router.dart`
- `lib/app.dart`
- `lib/core/theme/theme_providers.dart` (create new file for `currentThemeProvider`)

### Dependencies
- Steps 2, 3, 4 (all screens must exist)

### Owner
- **Rhodey:** Navigation logic, GoRouter config
- **Fury:** Auth redirect edge cases (e.g., expired session)

### Acceptance Criteria
- [ ] All routes navigate to real screens (no stubs)
- [ ] Auth redirects work correctly (unauthenticated → `/login`, parent → `/parent-home`, child → `/child-pin`)
- [ ] Theme switches when child logs in
- [ ] Deep linking works (e.g., `/transaction-history/child123` navigates to correct screen)

---

## **Step 6: Firebase Integration Test**

**Goal:** Verify that the app works end-to-end with real Firestore data.

### Tasks

1. **Smoke Test Scenarios:**
   - **Scenario 1: New User Flow**
     1. Create parent account (email/password)
     2. Create family ("Test Family")
     3. Add first child ("Alice", 🦁, PIN: 1234)
     4. Verify Firestore documents:
        - `/userProfiles/{uid}` exists with `role: parent`, `familyId: X`
        - `/families/{familyId}` exists with `name: "Test Family"`, `parentIds: [uid]`
        - `/families/{familyId}/children/{childId}` exists with `displayName: "Alice"`, `pinHash: ...`
        - `/families/{familyId}/children/{childId}/buckets/money` exists with `balance: 0`
        - `/families/{familyId}/children/{childId}/buckets/investment` exists with `balance: 0`
        - `/families/{familyId}/children/{childId}/buckets/charity` exists with `balance: 0`
   
   - **Scenario 2: Set Money**
     1. Parent selects Alice
     2. Taps "Set Money" → enters $50
     3. Verify:
        - Bucket balance updates to $50
        - Transaction document created with `type: moneySet`, `newBalance: 50`
   
   - **Scenario 3: Multiply Investment**
     1. Parent sets investment to $10
     2. Parent taps "Multiply Investment" → enters 1.5×
     3. Verify:
        - Bucket balance updates to $15
        - Transaction document created with `type: investmentMultiplied`, `multiplier: 1.5`
        - Celebration animation plays
   
   - **Scenario 4: Donate Charity**
     1. Parent sets charity to $20
     2. Parent taps "Donate Charity" → confirms
     3. Verify:
        - Bucket balance updates to $0
        - Transaction document created with `type: charityDonated`
        - Celebration animation plays
   
   - **Scenario 5: Child Login**
     1. Parent logs out
     2. Child enters PIN (1234)
     3. Verify:
        - Child sees their 3 buckets (read-only)
        - Theme switches to Kid Mode
        - Child sees transaction history (last 5)

2. **Security Rules Test:**
   - **Test 1:** Child tries to modify bucket balance via Firestore console → **Denied**
   - **Test 2:** Parent from different family tries to access another family's buckets → **Denied**
   - **Test 3:** Unauthenticated user tries to read buckets → **Denied**

3. **Edge Cases:**
   - **Test 1:** Multiply investment by 0 → **Rejected** (validation error: "Multiplier must be > 0.01")
   - **Test 2:** Enter wrong PIN 5 times → **Locked** for 15 minutes
   - **Test 3:** Offline mode → make changes → come online → **Sync succeeds**

### Files to Create
- `test/integration/smoke_test.dart` (manual test script, not automated)
- `test/security/rules_test.dart` (Firebase Emulator test)

### Owner
- **Happy:** Test plan execution, bug reporting
- **JARVIS:** Firestore rules testing
- **Fury:** Security edge cases (PIN lockout, cross-family isolation)

### Acceptance Criteria
- [ ] All 5 smoke test scenarios pass
- [ ] Security rules tests pass (child cannot write, family isolation enforced)
- [ ] Edge cases handled gracefully (validation errors, PIN lockout)
- [ ] No console errors or warnings during test run

---

## Phase 2 → Phase 3 Transition

### What's Complete After Phase 2
- ✅ All screens built and wired to Firestore
- ✅ Parent can manage children's buckets
- ✅ Child can view buckets (read-only)
- ✅ Celebration animations for investment/charity
- ✅ Transaction audit log works
- ✅ Auth flows tested (parent + child)

### What's Deferred to Phase 3
- **Transaction History Screen:** Full paginated list (currently only "last 5" on dashboard)
- **Multi-Child Management:** Add/edit/remove children (currently only "add first child")
- **Multi-Parent Invitations:** Invite co-parents to join family
- **Archive Logic:** Move transactions older than 1 year to archive collection
- **Advanced Animations:** Counter animations (count-up effect on balance change)
- **Settings Screens:** Parent settings (notifications, family name), Child settings (avatar picker)
- **Offline Queue:** Persist pending writes when offline (currently relies on Firestore offline cache)
- **Error Boundaries:** Graceful error handling for all failure modes
- **Freezed Migration:** Convert all models to use `@freezed` (currently manual `copyWith`)
- **Unit Tests:** Comprehensive test coverage (Phase 2 only has integration smoke tests)

### Phase 3 Goals (High-Level)
1. **Polish:** Animations, loading states, error messages
2. **Management:** Multi-child CRUD, multi-parent invites
3. **History:** Transaction history with pagination, filters, search
4. **Settings:** User preferences, notifications, family management
5. **Testing:** Unit tests, widget tests, integration tests (Firebase Emulator)
6. **Performance:** Query optimization, lazy loading, caching strategies

---

## Team Roles & Responsibilities

| Agent | Role | Phase 2 Responsibilities |
|-------|------|--------------------------|
| **Stark** | Tech Lead | Architecture review, code quality, technical decisions |
| **JARVIS** | Backend Lead | Repository methods, Firestore atomic writes, security rules testing |
| **Rhodey** | Frontend Lead | All screen implementations, navigation wiring, UI logic |
| **Pepper** | UI/UX Designer | Widget design specs, celebration animations, theme switching |
| **Fury** | Security Lead | PIN verification logic, brute-force protection, auth edge cases |
| **Happy** | QA Lead | Smoke tests, edge case testing, bug triage |

---

## Risk Mitigation

### Risk 1: Firestore Atomic Writes Complexity
**Mitigation:**
- All bucket mutations use Firestore batched writes (atomic)
- JARVIS owns all repository methods (single source of truth)
- Unit tests for each repository method (Phase 3)

### Risk 2: Celebration Animations Not Triggering
**Mitigation:**
- Step 1 builds `CelebrationAnimation` widget in isolation (testable)
- Step 3 wires it to repository callbacks
- Happy tests all 3 celebration triggers (investment multiply, charity donate, money added)

### Risk 3: PIN Brute-Force Logic Has Bugs
**Mitigation:**
- `PinService` already implemented in Phase 1 (battle-tested logic)
- Fury owns PIN screen UI (separate from service logic)
- Happy tests all PIN edge cases (wrong PIN, lockout, expiry)

### Risk 4: Theme Switching Breaks UI
**Mitigation:**
- All widgets use theme-aware colors/fonts (no hardcoded values)
- Pepper defines both themes upfront
- Rhodey tests theme switching on every screen

---

## Timeline Estimate

**Assumptions:**
- 1 step = 1-2 days of focused work
- Steps 1-4 can be partially parallelized (different agents)
- Steps 5-6 are sequential (depend on Steps 1-4)

**Estimated Timeline:**
- **Step 1 (Core Widgets):** 2 days (Pepper + Rhodey)
- **Step 2 (Auth Screens):** 2 days (Fury + Rhodey + JARVIS)
- **Step 3 (Parent Dashboard):** 3 days (Rhodey + JARVIS + Pepper)
- **Step 4 (Kid Dashboard):** 2 days (Rhodey + Pepper)
- **Step 5 (Navigation Wiring):** 1 day (Rhodey + Fury)
- **Step 6 (Firebase Integration Test):** 1 day (Happy + JARVIS + Fury)

**Total:** ~11 days (calendar time may vary based on parallelization)

---

## Definition of Done (Phase 2)

Phase 2 is **complete** when:

- [ ] All 6 steps are complete with acceptance criteria met
- [ ] Parent can create account → create family → add child → manage buckets (set money, multiply investment, donate charity)
- [ ] Child can log in with PIN → view buckets (read-only) → see transaction history
- [ ] Celebration animations play for investment multiply and charity donation
- [ ] All Firestore documents are created correctly (userProfiles, families, children, buckets, transactions)
- [ ] GoRouter navigation works end-to-end (no stub screens)
- [ ] Theme switches between Kid Mode and Parent Mode
- [ ] Security rules enforced (child cannot write, family isolation)
- [ ] Smoke tests pass (5 scenarios)
- [ ] No critical bugs or console errors

**Sign-Off Required From:**
- Stark (architecture review)
- JARVIS (Firestore data integrity)
- Rhodey (UI completeness)
- Pepper (design fidelity)
- Fury (security validation)
- Happy (QA approval)

---

## Appendix: Key Files to Create in Phase 2

### New Files (Widgets)
- `lib/core/widgets/bucket_card.dart`
- `lib/core/widgets/child_avatar.dart`
- `lib/core/widgets/pin_input_widget.dart`
- `lib/core/widgets/loading_overlay.dart`
- `lib/core/widgets/error_widget.dart`
- `lib/core/widgets/celebration_animation.dart`
- `lib/core/widgets/transaction_list_item.dart`

### New Files (Providers)
- `lib/core/theme/theme_providers.dart` (for `currentThemeProvider`)

### New Files (Screens)
- `lib/features/auth/presentation/widgets/child_selector_widget.dart`
- `lib/features/auth/presentation/widgets/buckets_overview.dart`
- `lib/features/auth/presentation/widgets/set_money_sheet.dart`
- `lib/features/auth/presentation/widgets/multiply_investment_sheet.dart`
- `lib/features/auth/presentation/widgets/donate_charity_sheet.dart`

### Modified Files (Screens)
- `lib/features/auth/presentation/login_screen.dart` (replace stub)
- `lib/features/auth/presentation/family_setup_screen.dart` (replace stub)
- `lib/features/auth/presentation/parent_home_screen.dart` (replace stub)
- `lib/features/auth/presentation/child_pin_screen.dart` (replace stub)
- `lib/features/auth/presentation/child_home_screen.dart` (replace stub)

### Modified Files (Repositories)
- `lib/features/buckets/data/firebase_bucket_repository.dart` (add `setMoney`, `multiplyInvestment`, `donateCharity`)

### Modified Files (Config)
- `lib/routing/app_router.dart` (add routes, remove stubs)
- `lib/app.dart` (add theme switching logic)

---

**Document Maintained by:** Stark (Tech Lead)  
**Last Updated:** 2026-04-05  
**Status:** Phase 2 Ready to Start
