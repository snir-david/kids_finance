# Quick Reference: KidsFinance App

## 🚀 Getting Started

```bash
# 1. Install dependencies
flutter pub get

# 2. Configure Firebase (required!)
dart pub global activate flutterfire_cli
flutterfire configure

# 3. Run the app
flutter run
```

## 📱 Current Features (Sprint 5 Complete)

### Parent Features
- ✅ Email/password and Google Sign-In authentication
- ✅ Create family or join existing via invite code
- ✅ Add/edit/archive children with emoji avatars
- ✅ Distribute allowance across three buckets (Money, Investment, Charity)
- ✅ Multiply investments for teaching compound growth
- ✅ Donate charity bucket to reset
- ✅ View transaction history per child
- ✅ Invite another parent via family code

### Child Features
- ✅ PIN authentication (4-6 digits) with brute-force protection
- ✅ View-only dashboard with three buckets
- ✅ See recent activity
- ✅ Switch between children (multi-child families)

### Offline & Security
- ✅ Offline queue with 24-hour TTL
- ✅ Conflict resolution dialog for concurrent edits
- ✅ 24-hour session expiry
- ✅ PIN lockout after 5 failed attempts (15 minutes)

## 📦 What's Included

- ✅ 57 Dart files in lib/ (0 lint issues)
- ✅ 5 domain models (Family, ParentUser, Child, Bucket, Transaction)
- ✅ 4 repository interfaces + Firebase implementations
- ✅ Offline sync engine with Hive queue
- ✅ Dual UI modes (Parent dashboard, Child view)

## 🎯 Usage Examples

### Watch child's buckets
```dart
final bucketsAsync = ref.watch(childBucketsProvider((
  childId: childId,
  familyId: familyId,
)));
```

### Distribute allowance
```dart
await ref.read(bucketRepositoryProvider).distributeFunds(
  childId: childId,
  familyId: familyId,
  moneyAmount: 10.0,
  investmentAmount: 5.0,
  charityAmount: 5.0,
  performedByUid: currentUser.uid,
);
```

### Multiply investment
```dart
await ref.read(bucketRepositoryProvider).multiplyInvestment(
  childId: childId,
  familyId: familyId,
  multiplier: 2.0,  // Must be > 0
  performedByUid: currentUser.uid,
);
```

## 📚 Documentation

- **Setup Guide:** `SETUP.md`
- **Architecture:** `docs/architecture.md`
- **Auth Design:** `AUTH_ARCHITECTURE.md`
- **Data Model:** `FIRESTORE_DATA_MODEL.md`

## ⚠️ Critical Notes

1. **Investment multiplier MUST be > 0** (throws ArgumentError)
2. **All mutations create transaction logs** (immutable audit trail)
3. **Atomic operations** (bucket + transaction updated together)
4. **Firebase configuration required** before running
5. **Firestore index required** for transaction queries

## 🔗 Firestore Structure

```
/families/{familyId}
  /children/{childId}
    /buckets/money
    /buckets/investment
    /buckets/charity
  /transactions/{txnId}

/userProfiles/{uid}
```

## 👥 Team Responsibilities

- **Rhodey/Pepper:** UI integration with providers
- **Fury:** Firestore security rules
- **Happy:** Unit tests (repositories + providers)
- **Stark:** Architecture review + approval
