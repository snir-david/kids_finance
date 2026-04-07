# KidsFinance — Functional Requirements Document

**Version:** 1.0  
**Status:** Current  
**Sprint:** 5D Complete  
**Last Updated:** 2026-04-08  
**Author:** Stark (Tech Lead)

---

## 1. Overview

### 1.1 Product Description

KidsFinance is a mobile application designed to teach financial literacy to children through a hands-on three-bucket money management system. Parents manage allowances and rewards; children observe their savings grow across three purpose-driven buckets: Money (spending), Investment (growth), and Charity (giving).

### 1.2 Target Users

- **Primary:** Families with children ages 5–12
- **Parent Users:** Adults managing household finances
- **Child Users:** Children learning about money management

### 1.3 Platform

- **Primary:** Android (minSdk 21, targetSdk 34)
- **Backend:** Firebase (Firestore, Auth, Cloud Functions)
- **Offline:** Supported via Hive local storage

### 1.4 Tech Stack

- Flutter 3.x + Dart
- Riverpod (state management)
- GoRouter (navigation)
- Firebase Firestore (database)
- Firebase Auth (parent authentication)
- Cloud Functions (business logic enforcement)
- Hive (offline queue persistence)
- bcrypt (PIN hashing)

---

## 2. User Roles

### FR-ROLE-01: Parent User
The system SHALL support a **Parent** role with full read/write access to family data.

| Attribute | Value |
|-----------|-------|
| Authentication | Firebase Auth (email/password) |
| Session Duration | Persistent until logout |
| Permissions | Full CRUD on family, children, buckets, transactions |

**Status:** ✅ Implemented

### FR-ROLE-02: Child User
The system SHALL support a **Child** role with read-only access to their own bucket data.

| Attribute | Value |
|-----------|-------|
| Authentication | Local PIN (4–6 digits, bcrypt hash) |
| Session Duration | 24 hours |
| Permissions | Read-only on own buckets and transactions |

**Status:** ✅ Implemented

---

## 3. Authentication & Authorization

### Parent Authentication

**FR-AUTH-01:** The system SHALL allow parents to register with email and password.  
**Status:** ✅ Implemented (`login_screen.dart`)

**FR-AUTH-02:** The system SHALL allow parents to log in with email and password.  
**Status:** ✅ Implemented (`auth_service.dart`)

**FR-AUTH-03:** The system SHALL allow parents to reset their password via email link.  
**Status:** ✅ Implemented (`forgot_password_screen.dart`)

**FR-AUTH-04:** The system SHALL NOT support Google Sign-In for parents.  
**Status:** ✅ By design (out of scope for MVP)

**FR-AUTH-05:** The system SHALL set Firebase Auth custom claims (`role: "parent"`, `familyId`) on parent registration.  
**Status:** ✅ Implemented (`onSetCustomClaims` Cloud Function)

### Child Authentication

**FR-AUTH-06:** The system SHALL allow children to authenticate via a 4–6 digit numeric PIN.  
**Status:** ✅ Implemented (`pin_service.dart`)

**FR-AUTH-07:** The system SHALL store child PINs as bcrypt hashes in Firestore.  
**Status:** ✅ Implemented (`pin_service.dart::hashPin()`)

**FR-AUTH-08:** The system SHALL NOT create Firebase Auth accounts for children.  
**Status:** ✅ Implemented (children exist only as Firestore documents)

**FR-AUTH-09:** The system SHALL validate child PIN entry against the stored bcrypt hash.  
**Status:** ✅ Implemented (`pin_service.dart::verifyChildPin()`)

### Session Management

**FR-AUTH-10:** The system SHALL create a 24-hour session for children upon successful PIN entry.  
**Status:** ✅ Implemented (`pin_service.dart::_createSession()`)

**FR-AUTH-11:** The system SHALL store child session expiry in both local storage (FlutterSecureStorage) and Firestore (`sessionExpiresAt`).  
**Status:** ✅ Implemented

**FR-AUTH-12:** The system SHALL redirect children to the PIN screen when their session expires.  
**Status:** ✅ Implemented (`session_provider.dart::childSessionValidProvider`)

**FR-AUTH-13:** The system SHALL prevent children from bypassing PIN entry via the back button.  
**Status:** ✅ Implemented (`child_pin_screen.dart` with PopScope)

### Brute-Force Protection

**FR-AUTH-14:** The system SHALL track consecutive failed PIN attempts per child.  
**Status:** ✅ Implemented (`pin_attempt_tracker.dart`)

**FR-AUTH-15:** The system SHALL lock out a child for 15 minutes after 5 consecutive failed PIN attempts.  
**Status:** ✅ Implemented (`PinAttemptTracker.maxAttempts = 5`, `lockoutDuration = 15min`)

**FR-AUTH-16:** The system SHALL persist lockout state in FlutterSecureStorage to survive app restart.  
**Status:** ✅ Implemented

**FR-AUTH-17:** The system SHALL automatically clear lockout state after the lockout period expires.  
**Status:** ✅ Implemented (`lockoutRemaining()` auto-clears expired lockouts)

**FR-AUTH-18:** The system SHALL reset the failure counter on successful PIN entry.  
**Status:** ✅ Implemented (`_tracker.resetAttempts(childId)`)

### Family Isolation

**FR-AUTH-19:** The system SHALL enforce family isolation via Firestore security rules.  
**Status:** ✅ Implemented (`isParentOfFamily()` in `firestore.rules`)

**FR-AUTH-20:** The system SHALL verify family membership via Firestore `parentIds[]` array, NOT JWT claims.  
**Status:** ✅ Implemented (`assertFamilyMembership()` in Cloud Functions)

**FR-AUTH-21:** The system SHALL deny all cross-family data access requests.  
**Status:** ✅ Implemented (Firestore rules + Cloud Functions)

---

## 4. Parent Features

### Family Management

**FR-PARENT-01:** The system SHALL allow parents to create a new family during registration.  
**Status:** ✅ Implemented (`family_setup_screen.dart`)

**FR-PARENT-02:** The system SHALL assign a unique familyId to each family (auto-generated Firestore document ID).  
**Status:** ✅ Implemented

**FR-PARENT-03:** The system SHALL use the familyId as the family invite code (no separate code needed).  
**Status:** ✅ Implemented

**FR-PARENT-04:** The system SHALL allow additional parents to join a family using the invite code.  
**Status:** ✅ Implemented (parent added to `parentIds[]` array)

**FR-PARENT-05:** The system SHALL store multiple parent UIDs in the `parentIds[]` array on the family document.  
**Status:** ✅ Implemented

### Child Management

**FR-PARENT-06:** The system SHALL allow parents to add children to the family.  
**Status:** ✅ Implemented (`parent_home_screen.dart`)

**FR-PARENT-07:** The system SHALL require a display name, avatar emoji, and PIN for each child.  
**Status:** ✅ Implemented (`validChildCreate()` in Firestore rules)

**FR-PARENT-08:** The system SHALL allow parents to edit a child's name, avatar, and PIN.  
**Status:** ✅ Implemented

**FR-PARENT-09:** The system SHALL allow parents to archive (soft-delete) a child.  
**Status:** ✅ Implemented (`archived: true` field on child document)

**FR-PARENT-10:** The system SHALL NOT allow hard deletion of child records.  
**Status:** ✅ Implemented (`allow delete: if false` in Firestore rules)

**FR-PARENT-11:** The system SHALL filter archived children from the active children list.  
**Status:** ✅ Implemented (`childrenProvider` filters `archived != true`)

### Allowance Distribution

**FR-PARENT-12:** The system SHALL allow parents to distribute funds across all three buckets in a single operation.  
**Status:** ✅ Implemented (`distributeFunds()`)

**FR-PARENT-13:** The system SHALL create a `distributed` transaction type for multi-bucket distributions.  
**Status:** ✅ Implemented (`TransactionType.distributed`)

**FR-PARENT-14:** The system SHALL allow parents to add money to the Money bucket.  
**Status:** ✅ Implemented (`addMoney()`)

**FR-PARENT-15:** The system SHALL allow parents to remove money from the Money bucket.  
**Status:** ✅ Implemented (`removeMoney()`)

**FR-PARENT-16:** The system SHALL allow parents to set the Money bucket to a specific value.  
**Status:** ✅ Implemented (`setMoneyBalance()`)

### Investment Multiplier

**FR-PARENT-17:** The system SHALL allow parents to multiply the Investment bucket balance.  
**Status:** ✅ Implemented (`multiplyInvestment()`)

**FR-PARENT-18:** The system SHALL require the multiplier to be greater than 0.  
**Status:** ✅ Implemented (validated at UI, repository, Cloud Function, and Firestore rules)

**FR-PARENT-19:** The system SHALL NOT allow a multiplier that decreases the Investment balance.  
**Status:** ✅ Implemented (`newBalance >= currentBalance` check in Cloud Function)

**FR-PARENT-20:** The system SHALL log multiplier events in the transaction history.  
**Status:** ✅ Implemented (`TransactionType.investmentMultiplied`)

### Charity Donation

**FR-PARENT-21:** The system SHALL allow parents to donate the Charity bucket (reset to $0).  
**Status:** ✅ Implemented (`donateCharity()`)

**FR-PARENT-22:** The system SHALL require a positive Charity balance before donation.  
**Status:** ✅ Implemented (`previousBalance > 0` check in Cloud Function)

**FR-PARENT-23:** The system SHALL log charity donations in the transaction history.  
**Status:** ✅ Implemented (`TransactionType.charityDonated`)

### Transaction History

**FR-PARENT-24:** The system SHALL allow parents to view all transaction history for the family.  
**Status:** ✅ Implemented (`transaction_history_screen.dart`)

**FR-PARENT-25:** The system SHALL display transactions sorted by date (newest first).  
**Status:** ✅ Implemented

---

## 5. Child Features

### Bucket Viewing

**FR-CHILD-01:** The system SHALL allow children to view their three bucket balances (Money, Investment, Charity).  
**Status:** ✅ Implemented (`child_home_screen.dart`)

**FR-CHILD-02:** The system SHALL display child-friendly bucket colors (Green=Money, Blue=Investment, Pink=Charity).  
**Status:** ✅ Implemented (`app_theme.dart`)

**FR-CHILD-03:** The system SHALL display a total wealth summary across all three buckets.  
**Status:** ✅ Implemented (`totalWealthProvider`)

### Read-Only Access

**FR-CHILD-04:** The system SHALL NOT allow children to modify bucket balances.  
**Status:** ✅ Implemented (no edit buttons + Firestore rules deny writes)

**FR-CHILD-05:** The system SHALL NOT allow children to access other children's data.  
**Status:** ✅ Implemented (family isolation + child-specific queries)

**FR-CHILD-06:** The system SHALL NOT allow children to access family settings.  
**Status:** ✅ Implemented (no family settings in child UI)

### Session Management

**FR-CHILD-07:** The system SHALL display a child picker screen before PIN entry.  
**Status:** ✅ Implemented (`child_picker_screen.dart`)

**FR-CHILD-08:** The system SHALL display the child's avatar and name on the PIN screen.  
**Status:** ✅ Implemented

**FR-CHILD-09:** The system SHALL provide a numeric keypad for PIN entry.  
**Status:** ✅ Implemented (`pin_input_widget.dart`)

---

## 6. Bucket System

### Bucket Types

**FR-BUCKET-01:** The system SHALL support exactly three bucket types: Money, Investment, Charity.  
**Status:** ✅ Implemented (`BucketType` enum)

**FR-BUCKET-02:** Each child SHALL have exactly three buckets (one of each type).  
**Status:** ✅ Implemented (created on child addition)

**FR-BUCKET-03:** Bucket balances SHALL be initialized to $0 on creation.  
**Status:** ✅ Implemented

### Balance Validation

**FR-BUCKET-04:** The system SHALL NOT allow negative bucket balances.  
**Status:** ✅ Implemented (`validBucketUpdate()` in Firestore rules: `balance >= 0`)

**FR-BUCKET-05:** The system SHALL validate bucket balances on every write operation.  
**Status:** ✅ Implemented (Firestore rules + repository validation)

### Bucket Operations

**FR-BUCKET-06:** The system SHALL support `add` operation on Money bucket.  
**Status:** ✅ Implemented

**FR-BUCKET-07:** The system SHALL support `remove` operation on Money bucket.  
**Status:** ✅ Implemented

**FR-BUCKET-08:** The system SHALL support `set` operation on Money bucket.  
**Status:** ✅ Implemented

**FR-BUCKET-09:** The system SHALL support `multiply` operation on Investment bucket.  
**Status:** ✅ Implemented

**FR-BUCKET-10:** The system SHALL support `donate` operation on Charity bucket (reset to $0).  
**Status:** ✅ Implemented

**FR-BUCKET-11:** The system SHALL support `distribute` operation across all three buckets.  
**Status:** ✅ Implemented

---

## 7. Offline Support

### Offline Queue

**FR-OFFLINE-01:** The system SHALL queue write operations when offline.  
**Status:** ✅ Implemented (`offline_queue.dart`)

**FR-OFFLINE-02:** The system SHALL persist queued operations using Hive.  
**Status:** ✅ Implemented (`Hive.box<PendingOperation>('pending_operations')`)

**FR-OFFLINE-03:** The system SHALL assign a unique ID to each queued operation.  
**Status:** ✅ Implemented (`generateId()`)

### TTL & Expiry

**FR-OFFLINE-04:** Queued operations SHALL expire after 24 hours.  
**Status:** ✅ Implemented (`purgeExpired()` checks `inHours >= 24`)

**FR-OFFLINE-05:** The system SHALL automatically purge expired operations.  
**Status:** ✅ Implemented (called during sync)

**FR-OFFLINE-06:** The system SHALL warn users about operations expiring within 1 hour.  
**Status:** ✅ Implemented (`getExpiring()` returns ops with `inHours >= 23`)

### Sync Engine

**FR-OFFLINE-07:** The system SHALL automatically sync queued operations when connectivity is restored.  
**Status:** ✅ Implemented (`sync_engine.dart`)

**FR-OFFLINE-08:** The system SHALL process queued operations in FIFO order.  
**Status:** ✅ Implemented (`ops.sort((a, b) => a.createdAt.compareTo(b.createdAt))`)

**FR-OFFLINE-09:** The system SHALL detect conflicts when server data has changed since the operation was queued.  
**Status:** ✅ Implemented (`_checkAndApplyBucketOp()`)

### Conflict Resolution

**FR-OFFLINE-10:** The system SHALL present a conflict resolution dialog when conflicts are detected.  
**Status:** ✅ Implemented (`conflict_resolution_dialog.dart`)

**FR-OFFLINE-11:** The system SHALL allow users to choose between local and server values.  
**Status:** ✅ Implemented (`ConflictResolution.useLocal`, `ConflictResolution.useServer`)

**FR-OFFLINE-12:** The system SHALL apply the chosen resolution and remove the operation from the queue.  
**Status:** ✅ Implemented (`resolveConflict()`)

### Connectivity Monitoring

**FR-OFFLINE-13:** The system SHALL monitor network connectivity status.  
**Status:** ✅ Implemented (`connectivity_service.dart`)

**FR-OFFLINE-14:** The system SHALL display an offline status banner when disconnected.  
**Status:** ✅ Implemented (`offline_status_banner.dart`)

**FR-OFFLINE-15:** The system SHALL trigger sync automatically on reconnection.  
**Status:** ✅ Implemented (`connectivity_provider.dart`)

---

## 8. Security Requirements

### Data Protection

**FR-SEC-01:** The system SHALL encrypt all data at rest using Firebase's default encryption.  
**Status:** ✅ Implemented (Firebase default)

**FR-SEC-02:** The system SHALL encrypt all data in transit using HTTPS/TLS.  
**Status:** ✅ Implemented (Firebase default)

**FR-SEC-03:** The system SHALL store sensitive local data in FlutterSecureStorage.  
**Status:** ✅ Implemented (PIN lockout state, session expiry)

### Access Control

**FR-SEC-04:** The system SHALL enforce family isolation at the Firestore rules level.  
**Status:** ✅ Implemented (`isParentOfFamily()` checks `parentIds[]`)

**FR-SEC-05:** The system SHALL enforce parent-only writes at the Firestore rules level.  
**Status:** ✅ Implemented

**FR-SEC-06:** The system SHALL enforce family membership verification in Cloud Functions.  
**Status:** ✅ Implemented (`assertFamilyMembership()`)

### Data Integrity

**FR-SEC-07:** The system SHALL NOT allow deletion of child records (soft-delete only).  
**Status:** ✅ Implemented (`allow delete: if false`)

**FR-SEC-08:** The system SHALL NOT allow deletion of bucket records.  
**Status:** ✅ Implemented (`allow delete: if false`)

**FR-SEC-09:** The system SHALL NOT allow deletion or modification of transaction records.  
**Status:** ✅ Implemented (`allow update, delete: if false`)

**FR-SEC-10:** The system SHALL NOT allow negative bucket balances.  
**Status:** ✅ Implemented (`balance >= 0` validation)

**FR-SEC-11:** The system SHALL NOT allow multipliers ≤ 0.  
**Status:** ✅ Implemented (`multiplier > 0` validation at 4 layers)

### Authentication Security

**FR-SEC-12:** The system SHALL hash child PINs with bcrypt before storage.  
**Status:** ✅ Implemented

**FR-SEC-13:** The system SHALL rate-limit PIN attempts (5 attempts per 15 minutes).  
**Status:** ✅ Implemented

**FR-SEC-14:** The system SHALL prevent back-button bypass of PIN entry.  
**Status:** ✅ Implemented (PopScope + automaticallyImplyLeading=false)

**FR-SEC-15:** The system SHALL verify family membership via Firestore, NOT JWT claims (prevent spoofing).  
**Status:** ✅ Implemented

---

## 9. Non-Functional Requirements

### NFR-01: Performance
The system SHOULD load family data within 2 seconds on a 4G connection.  
**Status:** ✅ Implemented (Firestore optimistic updates + local cache)

### NFR-02: Reliability
The system SHALL continue functioning offline for up to 24 hours.  
**Status:** ✅ Implemented (Hive queue with 24h TTL)

### NFR-03: Platform Support
The system SHALL support Android devices with API level 21+ (Lollipop 5.0).  
**Status:** ✅ Implemented (`minSdkVersion 21`)

### NFR-04: Code Quality
The system SHALL have zero Flutter analyzer issues.  
**Status:** ✅ Implemented (`flutter analyze` = 0 issues)

### NFR-05: Maintainability
The system SHALL follow feature-first folder structure with repository pattern.  
**Status:** ✅ Implemented

### NFR-06: Accessibility
The system SHOULD meet basic accessibility guidelines (touch target ≥ 48dp for parents, ≥ 64dp for children).  
**Status:** ✅ Implemented (`app_theme.dart`)

### NFR-07: Localization
The system MAY support multiple languages in future versions.  
**Status:** 🔶 Partial (structure supports it, but only English implemented)

---

## 10. Out of Scope

The following features were explicitly NOT built for MVP:

| Feature | Reason |
|---------|--------|
| iOS support | Android-first strategy |
| Web support | Mobile-first strategy |
| Google Sign-In | Email/password sufficient for MVP |
| Biometric auth for children | PIN sufficient for target age group |
| Recurring allowances | Manual distribution preferred for teaching moments |
| Push notifications | Future enhancement |
| Parent activity audit trail UI | Transaction history sufficient for MVP |
| Hard delete child/family | Data safety (soft-delete only) |
| Multi-currency support | USD only for MVP |
| Investment portfolio simulation | Simple multiplier sufficient for MVP |
| Charity recipient tracking | Simple reset-to-zero sufficient for MVP |
| Child spending requests | Full parent control for MVP |
| Child-to-child transfers | Not needed for core learning goals |

---

## Appendix A: Data Model Reference

### Firestore Collections

```
/families/{familyId}
  - name: string
  - parentIds: string[]
  - createdAt: timestamp

/families/{familyId}/children/{childId}
  - displayName: string
  - avatarEmoji: string
  - pinHash: string (bcrypt)
  - familyId: string
  - sessionExpiresAt: timestamp (nullable)
  - createdAt: timestamp
  - archived: boolean

/families/{familyId}/children/{childId}/buckets/{bucketType}
  - balance: number (≥ 0)
  - childId: string
  - familyId: string
  - type: string (money|investment|charity)
  - lastUpdatedAt: timestamp

/families/{familyId}/transactions/{txnId}
  - familyId: string
  - childId: string
  - bucketType: string
  - type: string (enum)
  - amount: number
  - multiplier: number (nullable)
  - previousBalance: number
  - newBalance: number
  - note: string (nullable)
  - performedByUid: string
  - performedAt: timestamp

/userProfiles/{userId}
  - role: string (parent)
  - familyId: string
  - email: string
```

---

## Appendix B: Glossary

| Term | Definition |
|------|------------|
| Bucket | A category for child's money (Money, Investment, Charity) |
| Distribute | Split an amount across all three buckets |
| Multiply | Increase Investment bucket by a factor (simulating interest/growth) |
| Donate | Reset Charity bucket to $0 (simulating a charitable contribution) |
| Archive | Soft-delete a child record (hidden but not deleted) |
| familyId | Unique identifier for a family (also serves as invite code) |
| parentIds | Array of Firebase Auth UIDs for all parents in a family |
| sessionExpiresAt | Timestamp when a child's PIN session expires (24h after login) |

---

**END OF DOCUMENT**
