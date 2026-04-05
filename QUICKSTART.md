# Quick Reference: Data Layer

## 🚀 Getting Started

```bash
# 1. Install dependencies
flutter pub get

# 2. Generate code (REQUIRED!)
flutter pub run build_runner build --delete-conflicting-outputs

# 3. Create Firestore index in Firebase Console
# Collection: families/{familyId}/transactions
# Fields: childId (ASC), performedAt (DESC)
```

## 📦 What's Included

- ✅ 5 Freezed domain models (Family, ParentUser, Child, Bucket, Transaction)
- ✅ 4 repository interfaces + Firebase implementations
- ✅ 4 Riverpod provider files with 15+ providers
- ✅ Complete documentation (4 markdown files)
- ✅ 1,464 lines of production Dart code

## 🎯 Usage Examples

### Watch child's buckets
```dart
final bucketsAsync = ref.watch(childBucketsProvider(
  childId: childId,
  familyId: familyId,
));
```

### Multiply investment (>0 only!)
```dart
await ref.read(bucketRepositoryProvider).multiplyInvestment(
  childId: childId,
  familyId: familyId,
  multiplier: 2.0,  // Must be > 0
  performedByUid: currentUser.uid,
);
```

### Donate charity
```dart
await ref.read(bucketRepositoryProvider).donateCharity(
  childId: childId,
  familyId: familyId,
  performedByUid: currentUser.uid,
);
```

## 📚 Documentation

- **Setup Guide:** `SETUP_DATA_LAYER.md`
- **Full Docs:** `lib/DATA_LAYER.md`
- **Manifest:** `DATA_LAYER_MANIFEST.md`
- **Decisions:** `.squad/decisions/inbox/jarvis-phase1.md`

## ⚠️ Critical Notes

1. **Investment multiplier MUST be > 0** (throws ArgumentError)
2. **All mutations create transaction logs** (immutable audit trail)
3. **Atomic operations** (bucket + transaction updated together)
4. **Code generation required** before compilation
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
