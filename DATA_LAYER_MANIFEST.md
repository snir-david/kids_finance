# Data Layer Implementation Manifest

**Implemented by:** JARVIS (Backend Dev)  
**Date:** 2026-04-05  
**Status:** ✅ Complete (pending code generation)

---

## Files Created (24 total)

### Domain Models (5 files)
```
lib/features/family/domain/
  ✓ family.dart                    — Family entity with Freezed
  ✓ parent_user.dart              — ParentUser entity with Freezed

lib/features/children/domain/
  ✓ child.dart                     — Child entity with Freezed

lib/features/buckets/domain/
  ✓ bucket.dart                    — Bucket entity + BucketType enum

lib/features/transactions/domain/
  ✓ transaction.dart              — Transaction entity + TransactionType enum
```

### Repository Interfaces (4 files)
```
lib/features/family/domain/
  ✓ family_repository.dart        — Abstract FamilyRepository interface

lib/features/children/domain/
  ✓ child_repository.dart         — Abstract ChildRepository interface

lib/features/buckets/domain/
  ✓ bucket_repository.dart        — Abstract BucketRepository interface

lib/features/transactions/domain/
  ✓ transaction_repository.dart   — Abstract TransactionRepository interface
```

### Firebase Implementations (4 files)
```
lib/features/family/data/
  ✓ firebase_family_repository.dart    — Firestore implementation

lib/features/children/data/
  ✓ firebase_child_repository.dart     — Firestore implementation

lib/features/buckets/data/
  ✓ firebase_bucket_repository.dart    — Firestore implementation (3.8KB)

lib/features/transactions/data/
  ✓ firebase_transaction_repository.dart — Firestore implementation
```

### Riverpod Providers (4 files)
```
lib/features/family/providers/
  ✓ family_providers.dart         — family, currentUserProfile providers

lib/features/children/providers/
  ✓ children_providers.dart       — children, child, selectedChild providers

lib/features/buckets/providers/
  ✓ buckets_providers.dart        — childBuckets, totalWealth, bucketByType providers

lib/features/transactions/providers/
  ✓ transaction_providers.dart    — transactionHistory, recentTransactions providers
```

### Documentation (3 files)
```
lib/
  ✓ DATA_LAYER.md                 — Complete data layer documentation (9.6KB)

/
  ✓ SETUP_DATA_LAYER.md           — Setup guide for team (4.8KB)
  ✓ DATA_LAYER_MANIFEST.md        — This file

.squad/decisions/inbox/
  ✓ jarvis-phase1.md              — Implementation decisions (7.8KB)

.squad/agents/jarvis/
  ✓ history.md (updated)          — Added Phase 1 learnings
```

---

## Statistics

| Category | Count | Total Size |
|----------|-------|------------|
| Domain Models | 5 | ~3.0 KB |
| Repository Interfaces | 4 | ~3.6 KB |
| Firebase Implementations | 4 | ~17.2 KB |
| Riverpod Providers | 4 | ~6.1 KB |
| Documentation | 4 | ~22.3 KB |
| **TOTAL** | **21** | **~52.2 KB** |

---

## Code Generation Required

⚠️ **IMPORTANT:** The code will NOT compile until you run:

```bash
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
```

This will generate approximately 21 additional files:
- 5 `*.freezed.dart` files (one per model)
- 5 `*.g.dart` files (JSON serialization)
- 4 `*_providers.g.dart` files (Riverpod)

---

## Validation Checklist

Before integrating with UI:

- [ ] Run `flutter pub get`
- [ ] Run `flutter pub run build_runner build --delete-conflicting-outputs`
- [ ] Verify no compilation errors
- [ ] Create Firestore composite index (childId + performedAt)
- [ ] Update security rules to match collection structure
- [ ] Write unit tests for repositories
- [ ] Write unit tests for providers
- [ ] Test investment multiplier validation (must reject ≤ 0)
- [ ] Test transaction logging (every mutation creates a log)
- [ ] Test atomic operations (bucket + transaction are atomic)

---

## Key Implementation Decisions

1. ✅ Investment multiplier MUST be > 0 (throws ArgumentError)
2. ✅ Charity donation sets balance to 0
3. ✅ All mutations logged as immutable transactions
4. ✅ Firestore transactions for atomic bucket updates
5. ✅ Batch writes for multi-document creates
6. ✅ Repository pattern enforced (no direct Firestore in UI)
7. ✅ Riverpod code generation (@riverpod annotation)
8. ✅ Real-time streams for buckets, children, transactions
9. ✅ Archive old transactions to separate collection
10. ✅ Session expiry stored as nullable DateTime

---

## Firestore Paths

```
/families/{familyId}
  /children/{childId}
    /buckets/{bucketType}       ← money, investment, charity
  /transactions/{txnId}          ← all children in family
  /archivedTransactions/{txnId}

/userProfiles/{uid}              ← top-level for fast lookup
```

---

## Next Steps

1. **Rhodey/Pepper:** Integrate providers into UI screens
2. **Fury:** Update Firestore security rules
3. **Happy:** Write unit tests for repositories and providers
4. **Stark:** Review architecture and approve decisions
5. **JARVIS:** Implement Cloud Functions if needed for server-side validation

---

**Questions?** See `.squad/decisions/inbox/jarvis-phase1.md` for detailed decisions.
