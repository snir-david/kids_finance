# KidsFinance Firestore Data Model

**Author:** JARVIS (Backend Developer)  
**Date:** 2026-04-05  
**Version:** 1.0

---

## 1. Collection/Document Structure

```
/families/{familyId}
  - Family metadata and settings
  
  /parents (subcollection)
    /{parentId}
      - Parent user data
  
  /children (subcollection)
    /{childId}
      - Child user data
      - Three buckets: money, investment, charity
  
  /transactions (subcollection)
    /{transactionId}
      - Immutable transaction log
      - Investment multiplications, charity donations, money adjustments

/userProfiles/{userId}
  - User metadata linking to family
  - Role (parent/child)
  - Fast lookup for auth
```

### Design Rationale
- **Family as root:** All data lives under `/families/{familyId}` for easy security rules and data locality
- **Subcollections:** Parents, children, and transactions are subcollections for atomic family operations
- **UserProfiles as top-level:** Fast lookup to find which family a user belongs to (critical for auth)

---

## 2. Data Models

### 2.1 Family Document

**Path:** `/families/{familyId}`

```json
{
  "familyId": "family_abc123",
  "familyName": "The Smith Family",
  "createdAt": "2026-04-01T10:00:00Z",
  "createdBy": "parent_xyz789",
  "updatedAt": "2026-04-05T15:30:00Z",
  "settings": {
    "currency": "USD",
    "currencySymbol": "$",
    "investmentMultiplierDefault": 1.5,
    "allowChildViewTransactions": true
  }
}
```

**Fields:**
- `familyId` (string): Unique family identifier
- `familyName` (string): Display name for the family
- `createdAt` (timestamp): When family was created
- `createdBy` (string): userId of parent who created the family
- `updatedAt` (timestamp): Last modification time
- `settings` (map):
  - `currency` (string): Currency code (USD, EUR, etc.)
  - `currencySymbol` (string): Symbol to display ($, €, etc.)
  - `investmentMultiplierDefault` (number): Default multiplier for investments
  - `allowChildViewTransactions` (boolean): Can children see transaction history?

---

### 2.2 Parent Document

**Path:** `/families/{familyId}/parents/{parentId}`

```json
{
  "userId": "parent_xyz789",
  "email": "parent@example.com",
  "displayName": "John Smith",
  "photoUrl": "https://example.com/photo.jpg",
  "role": "parent",
  "joinedAt": "2026-04-01T10:00:00Z",
  "isOwner": true,
  "permissions": {
    "canAddParents": true,
    "canRemoveParents": true,
    "canDeleteFamily": true,
    "canModifyChildren": true,
    "canMultiplyInvestments": true,
    "canAdjustMoney": true
  }
}
```

**Fields:**
- `userId` (string): Firebase Auth UID
- `email` (string): Parent's email
- `displayName` (string): Display name
- `photoUrl` (string, optional): Profile photo URL
- `role` (string): Always "parent"
- `joinedAt` (timestamp): When parent joined this family
- `isOwner` (boolean): Is this the family creator? (special permissions)
- `permissions` (map): Granular permissions for future expansion

---

### 2.3 Child Document

**Path:** `/families/{familyId}/children/{childId}`

```json
{
  "userId": "child_abc456",
  "displayName": "Emma Smith",
  "photoUrl": "https://example.com/emma.jpg",
  "role": "child",
  "createdAt": "2026-04-01T10:15:00Z",
  "createdBy": "parent_xyz789",
  "updatedAt": "2026-04-05T15:30:00Z",
  "buckets": {
    "money": {
      "amount": 50.00,
      "lastUpdated": "2026-04-05T15:30:00Z",
      "lastUpdatedBy": "parent_xyz789"
    },
    "investment": {
      "amount": 100.00,
      "lastUpdated": "2026-04-05T15:00:00Z",
      "lastUpdatedBy": "parent_xyz789",
      "lastMultipliedAt": "2026-04-05T15:00:00Z",
      "totalEarnings": 50.00
    },
    "charity": {
      "amount": 25.00,
      "lastUpdated": "2026-04-04T12:00:00Z",
      "lastUpdatedBy": "child_abc456",
      "lastDonatedAt": "2026-04-03T10:00:00Z",
      "totalDonated": 75.00
    }
  },
  "stats": {
    "totalInvestmentMultiplications": 3,
    "totalCharityDonations": 2,
    "totalMoneyReceived": 200.00
  }
}
```

**Fields:**
- `userId` (string): Firebase Auth UID (if child has login) or generated ID
- `displayName` (string): Child's name
- `photoUrl` (string, optional): Profile photo URL
- `role` (string): Always "child"
- `createdAt` (timestamp): When child account was created
- `createdBy` (string): userId of parent who created this child
- `updatedAt` (timestamp): Last modification to any bucket
- `buckets` (map): The three buckets
  - `money` (map):
    - `amount` (number): Current money balance
    - `lastUpdated` (timestamp)
    - `lastUpdatedBy` (string): userId of who last modified
  - `investment` (map):
    - `amount` (number): Current investment balance
    - `lastUpdated` (timestamp)
    - `lastUpdatedBy` (string)
    - `lastMultipliedAt` (timestamp, optional): Last multiplication event
    - `totalEarnings` (number): Cumulative earnings from multiplications
  - `charity` (map):
    - `amount` (number): Current charity balance
    - `lastUpdated` (timestamp)
    - `lastUpdatedBy` (string)
    - `lastDonatedAt` (timestamp, optional): Last donation event
    - `totalDonated` (number): Cumulative donations
- `stats` (map): Aggregate statistics for UI display

---

### 2.4 Transaction Document

**Path:** `/families/{familyId}/transactions/{transactionId}`

```json
{
  "transactionId": "txn_202604051530_001",
  "type": "investment_multiply",
  "childId": "child_abc456",
  "performedBy": "parent_xyz789",
  "timestamp": "2026-04-05T15:00:00Z",
  "data": {
    "bucketType": "investment",
    "previousAmount": 50.00,
    "multiplier": 2.0,
    "addedAmount": 50.00,
    "newAmount": 100.00
  },
  "description": "Investment multiplied by 2x"
}
```

**Transaction Types:**

#### 2.4.1 Investment Multiplication
```json
{
  "transactionId": "txn_202604051530_001",
  "type": "investment_multiply",
  "childId": "child_abc456",
  "performedBy": "parent_xyz789",
  "timestamp": "2026-04-05T15:00:00Z",
  "data": {
    "bucketType": "investment",
    "previousAmount": 50.00,
    "multiplier": 2.0,
    "addedAmount": 50.00,
    "newAmount": 100.00
  },
  "description": "Investment multiplied by 2x"
}
```

#### 2.4.2 Charity Donation
```json
{
  "transactionId": "txn_202604031000_002",
  "type": "charity_donate",
  "childId": "child_abc456",
  "performedBy": "child_abc456",
  "timestamp": "2026-04-03T10:00:00Z",
  "data": {
    "bucketType": "charity",
    "previousAmount": 25.00,
    "donatedAmount": 25.00,
    "newAmount": 0.00,
    "donationTarget": "Local Food Bank"
  },
  "description": "Donated $25 to Local Food Bank"
}
```

#### 2.4.3 Money Adjustment
```json
{
  "transactionId": "txn_202604011200_003",
  "type": "money_adjust",
  "childId": "child_abc456",
  "performedBy": "parent_xyz789",
  "timestamp": "2026-04-01T12:00:00Z",
  "data": {
    "bucketType": "money",
    "previousAmount": 30.00,
    "adjustmentAmount": 20.00,
    "newAmount": 50.00,
    "reason": "Weekly allowance"
  },
  "description": "Added $20 - Weekly allowance"
}
```

#### 2.4.4 Transfer Between Buckets
```json
{
  "transactionId": "txn_202604021400_004",
  "type": "bucket_transfer",
  "childId": "child_abc456",
  "performedBy": "child_abc456",
  "timestamp": "2026-04-02T14:00:00Z",
  "data": {
    "fromBucket": "money",
    "toBucket": "investment",
    "amount": 25.00,
    "fromPreviousAmount": 75.00,
    "fromNewAmount": 50.00,
    "toPreviousAmount": 50.00,
    "toNewAmount": 75.00
  },
  "description": "Moved $25 from Money to Investment"
}
```

**Fields:**
- `transactionId` (string): Unique transaction ID
- `type` (string): Transaction type (investment_multiply, charity_donate, money_adjust, bucket_transfer)
- `childId` (string): Which child this affects
- `performedBy` (string): userId who performed the action
- `timestamp` (timestamp): When transaction occurred
- `data` (map): Type-specific transaction data
- `description` (string): Human-readable description for display

---

### 2.5 UserProfile Document

**Path:** `/userProfiles/{userId}`

```json
{
  "userId": "parent_xyz789",
  "email": "parent@example.com",
  "displayName": "John Smith",
  "role": "parent",
  "familyId": "family_abc123",
  "createdAt": "2026-04-01T10:00:00Z",
  "lastLoginAt": "2026-04-05T09:00:00Z"
}
```

**Purpose:** Fast lookup to determine which family a user belongs to without querying subcollections.

**Fields:**
- `userId` (string): Firebase Auth UID
- `email` (string): User email
- `displayName` (string): Display name
- `role` (string): "parent" or "child"
- `familyId` (string): Reference to family document
- `createdAt` (timestamp): Account creation time
- `lastLoginAt` (timestamp): Last login time

---

## 3. Transaction/Event Design

### Immutable Transaction Log

All state-changing operations are recorded as **immutable transactions**:
1. Transaction document is created with complete before/after state
2. Child's bucket is updated atomically
3. Child's stats are updated

**Benefits:**
- Complete audit trail for parents
- Undo/rollback capability (future feature)
- Data analytics (e.g., "How much has Emma earned from investments?")
- Debugging and support

### Transaction Creation Flow

```
Parent triggers investment multiplication:
1. Read current investment bucket amount
2. Calculate new amount (current × multiplier)
3. Batch write:
   a. Create transaction document
   b. Update child.buckets.investment.amount
   c. Update child.buckets.investment.totalEarnings
   d. Update child.stats.totalInvestmentMultiplications
   e. Update child.updatedAt
```

**Cloud Function enforces atomicity** — all updates succeed or all fail.

---

## 4. Real-Time Sync Considerations

### Collections Requiring Real-Time Listeners

| Collection | Real-Time? | Reason |
|------------|-----------|---------|
| `/families/{familyId}` | ✅ Yes | Settings changes should reflect immediately |
| `/families/{familyId}/children` | ✅ Yes | Bucket amounts update in real-time (parent multiplies investment → child sees it immediately) |
| `/families/{familyId}/transactions` | ⚠️ Partial | Only recent transactions (last 50) — full history is one-time fetch |
| `/families/{familyId}/parents` | ❌ No | Parent list rarely changes |
| `/userProfiles/{userId}` | ❌ No | One-time fetch on login |

### Listener Strategy

**For Children (Most Critical):**
```dart
// Real-time stream of all children in family
Stream<List<Child>> watchChildren(String familyId)

// Real-time stream of single child's buckets
Stream<Child> watchChild(String familyId, String childId)
```

**For Transactions:**
```dart
// Real-time stream of recent transactions (last 50)
Stream<List<Transaction>> watchRecentTransactions(String familyId, {String? childId})

// One-time fetch of full history
Future<List<Transaction>> getTransactionHistory(String familyId, {String? childId, int limit = 100})
```

**For Family:**
```dart
// Real-time stream of family settings
Stream<Family> watchFamily(String familyId)
```

---

## 5. Riverpod Provider Sketch

### 5.1 Core Providers

```dart
// === Authentication & User Context ===

/// Current user's Firebase Auth UID
final authUserIdProvider = StreamProvider<String?>((ref) {
  final authState = FirebaseAuth.instance.authStateChanges();
  return authState.map((user) => user?.uid);
});

/// Current user's profile (with familyId)
final userProfileProvider = StreamProvider<UserProfile?>((ref) async* {
  final userId = await ref.watch(authUserIdProvider.future);
  if (userId == null) {
    yield null;
    return;
  }
  
  yield* FirebaseFirestore.instance
    .collection('userProfiles')
    .doc(userId)
    .snapshots()
    .map((snap) => UserProfile.fromFirestore(snap));
});

/// Current user's familyId
final familyIdProvider = Provider<String?>((ref) {
  final userProfile = ref.watch(userProfileProvider).value;
  return userProfile?.familyId;
});

// === Family Data ===

/// Family document (real-time)
final familyProvider = StreamProvider<Family?>((ref) async* {
  final familyId = ref.watch(familyIdProvider);
  if (familyId == null) {
    yield null;
    return;
  }
  
  yield* FirebaseFirestore.instance
    .collection('families')
    .doc(familyId)
    .snapshots()
    .map((snap) => Family.fromFirestore(snap));
});

// === Children Data ===

/// All children in family (real-time)
final childrenProvider = StreamProvider<List<Child>>((ref) async* {
  final familyId = ref.watch(familyIdProvider);
  if (familyId == null) {
    yield [];
    return;
  }
  
  yield* FirebaseFirestore.instance
    .collection('families')
    .doc(familyId)
    .collection('children')
    .orderBy('displayName')
    .snapshots()
    .map((snapshot) => snapshot.docs
        .map((doc) => Child.fromFirestore(doc))
        .toList());
});

/// Single child's buckets (real-time)
final childBucketsProvider = StreamProvider.family<Child, String>((ref, childId) async* {
  final familyId = ref.watch(familyIdProvider);
  if (familyId == null) {
    throw Exception('No family ID found');
  }
  
  yield* FirebaseFirestore.instance
    .collection('families')
    .doc(familyId)
    .collection('children')
    .doc(childId)
    .snapshots()
    .map((snap) => Child.fromFirestore(snap));
});

// === Transaction History ===

/// Recent transactions (real-time, last 50)
final recentTransactionsProvider = StreamProvider<List<Transaction>>((ref) async* {
  final familyId = ref.watch(familyIdProvider);
  if (familyId == null) {
    yield [];
    return;
  }
  
  yield* FirebaseFirestore.instance
    .collection('families')
    .doc(familyId)
    .collection('transactions')
    .orderBy('timestamp', descending: true)
    .limit(50)
    .snapshots()
    .map((snapshot) => snapshot.docs
        .map((doc) => Transaction.fromFirestore(doc))
        .toList());
});

/// Transactions for specific child (real-time, last 50)
final childTransactionsProvider = StreamProvider.family<List<Transaction>, String>((ref, childId) async* {
  final familyId = ref.watch(familyIdProvider);
  if (familyId == null) {
    yield [];
    return;
  }
  
  yield* FirebaseFirestore.instance
    .collection('families')
    .doc(familyId)
    .collection('transactions')
    .where('childId', isEqualTo: childId)
    .orderBy('timestamp', descending: true)
    .limit(50)
    .snapshots()
    .map((snapshot) => snapshot.docs
        .map((doc) => Transaction.fromFirestore(doc))
        .toList());
});

/// Full transaction history (one-time fetch with pagination)
final transactionHistoryProvider = FutureProvider.autoDispose.family<List<Transaction>, TransactionHistoryParams>(
  (ref, params) async {
    final familyId = params.familyId;
    
    Query query = FirebaseFirestore.instance
      .collection('families')
      .doc(familyId)
      .collection('transactions')
      .orderBy('timestamp', descending: true);
    
    if (params.childId != null) {
      query = query.where('childId', isEqualTo: params.childId);
    }
    
    if (params.lastDocument != null) {
      query = query.startAfterDocument(params.lastDocument!);
    }
    
    final snapshot = await query.limit(params.limit).get();
    return snapshot.docs.map((doc) => Transaction.fromFirestore(doc)).toList();
  },
);

// === Parents ===

/// All parents in family (one-time fetch, rarely changes)
final parentsProvider = FutureProvider<List<Parent>>((ref) async {
  final familyId = ref.watch(familyIdProvider);
  if (familyId == null) {
    return [];
  }
  
  final snapshot = await FirebaseFirestore.instance
    .collection('families')
    .doc(familyId)
    .collection('parents')
    .get();
  
  return snapshot.docs.map((doc) => Parent.fromFirestore(doc)).toList();
});
```

### 5.2 Helper Types

```dart
class TransactionHistoryParams {
  final String familyId;
  final String? childId;
  final int limit;
  final DocumentSnapshot? lastDocument;
  
  TransactionHistoryParams({
    required this.familyId,
    this.childId,
    this.limit = 100,
    this.lastDocument,
  });
}
```

---

## 6. Cloud Functions Needed

### 6.1 `multiplyInvestment`

**Trigger:** HTTPS Callable  
**Input:**
```json
{
  "familyId": "family_abc123",
  "childId": "child_abc456",
  "multiplier": 2.0
}
```

**Logic:**
1. Verify caller is a parent in the family (check `/families/{familyId}/parents/{callerId}`)
2. Read current investment bucket amount
3. Calculate new amount: `newAmount = currentAmount * multiplier`
4. Calculate earnings: `earnings = newAmount - currentAmount`
5. Batch write:
   - Create transaction document
   - Update `child.buckets.investment.amount = newAmount`
   - Update `child.buckets.investment.totalEarnings += earnings`
   - Update `child.buckets.investment.lastMultipliedAt = now`
   - Update `child.stats.totalInvestmentMultiplications += 1`
   - Update `child.updatedAt = now`

**Output:**
```json
{
  "success": true,
  "transactionId": "txn_202604051530_001",
  "previousAmount": 50.00,
  "newAmount": 100.00,
  "earnings": 50.00
}
```

**Error Cases:**
- Caller is not a parent → `PERMISSION_DENIED`
- Child not found → `NOT_FOUND`
- Invalid multiplier (<= 0) → `INVALID_ARGUMENT`

---

### 6.2 `donateCharity`

**Trigger:** HTTPS Callable  
**Input:**
```json
{
  "familyId": "family_abc123",
  "childId": "child_abc456",
  "donationTarget": "Local Food Bank"
}
```

**Logic:**
1. Verify caller is the child OR a parent in the family
2. Read current charity bucket amount
3. If `amount === 0`, return error (nothing to donate)
4. Batch write:
   - Create transaction document with `donatedAmount = currentAmount`
   - Update `child.buckets.charity.amount = 0`
   - Update `child.buckets.charity.totalDonated += donatedAmount`
   - Update `child.buckets.charity.lastDonatedAt = now`
   - Update `child.stats.totalCharityDonations += 1`
   - Update `child.updatedAt = now`

**Output:**
```json
{
  "success": true,
  "transactionId": "txn_202604031000_002",
  "donatedAmount": 25.00,
  "donationTarget": "Local Food Bank"
}
```

**Error Cases:**
- Caller not authorized → `PERMISSION_DENIED`
- Charity bucket is empty → `FAILED_PRECONDITION`
- Child not found → `NOT_FOUND`

---

### 6.3 `adjustMoney`

**Trigger:** HTTPS Callable  
**Input:**
```json
{
  "familyId": "family_abc123",
  "childId": "child_abc456",
  "newAmount": 75.00,
  "reason": "Weekly allowance"
}
```

**Logic:**
1. Verify caller is a parent in the family
2. Validate `newAmount >= 0`
3. Read current money bucket amount
4. Calculate adjustment: `adjustmentAmount = newAmount - currentAmount`
5. Batch write:
   - Create transaction document
   - Update `child.buckets.money.amount = newAmount`
   - Update `child.stats.totalMoneyReceived += adjustmentAmount` (if positive)
   - Update `child.updatedAt = now`

**Output:**
```json
{
  "success": true,
  "transactionId": "txn_202604011200_003",
  "previousAmount": 50.00,
  "newAmount": 75.00,
  "adjustmentAmount": 25.00
}
```

**Error Cases:**
- Caller is not a parent → `PERMISSION_DENIED`
- Invalid amount (< 0) → `INVALID_ARGUMENT`
- Child not found → `NOT_FOUND`

---

### 6.4 `transferBetweenBuckets`

**Trigger:** HTTPS Callable  
**Input:**
```json
{
  "familyId": "family_abc123",
  "childId": "child_abc456",
  "fromBucket": "money",
  "toBucket": "investment",
  "amount": 25.00
}
```

**Logic:**
1. Verify caller is the child OR a parent in the family
2. Validate `fromBucket` and `toBucket` are different
3. Validate `amount > 0`
4. Read current amounts from both buckets
5. Validate `fromBucket.amount >= amount`
6. Batch write:
   - Create transaction document
   - Update `child.buckets[fromBucket].amount -= amount`
   - Update `child.buckets[toBucket].amount += amount`
   - Update `child.updatedAt = now`

**Output:**
```json
{
  "success": true,
  "transactionId": "txn_202604021400_004",
  "fromBucket": "money",
  "toBucket": "investment",
  "amount": 25.00
}
```

**Error Cases:**
- Caller not authorized → `PERMISSION_DENIED`
- Insufficient balance → `FAILED_PRECONDITION`
- Invalid bucket names → `INVALID_ARGUMENT`
- Child not found → `NOT_FOUND`

---

### 6.5 `createFamily` (Bonus)

**Trigger:** HTTPS Callable  
**Input:**
```json
{
  "familyName": "The Smith Family",
  "settings": {
    "currency": "USD",
    "currencySymbol": "$"
  }
}
```

**Logic:**
1. Get caller's userId from auth context
2. Generate unique `familyId`
3. Batch write:
   - Create family document
   - Create parent document in `/families/{familyId}/parents/{userId}`
   - Create/update user profile in `/userProfiles/{userId}`

**Output:**
```json
{
  "success": true,
  "familyId": "family_abc123"
}
```

---

### 6.6 `addChild`

**Trigger:** HTTPS Callable  
**Input:**
```json
{
  "familyId": "family_abc123",
  "displayName": "Emma Smith",
  "photoUrl": "https://example.com/emma.jpg",
  "initialMoney": 0.00
}
```

**Logic:**
1. Verify caller is a parent in the family
2. Generate unique `childId`
3. Create child document with initialized buckets (all at 0.00)
4. Optionally create initial money adjustment if `initialMoney > 0`

**Output:**
```json
{
  "success": true,
  "childId": "child_abc456"
}
```

---

## 7. Security Considerations

### Data Access Rules (for Fury to implement)

**Family-level:**
- Only parents in family can read/write family document
- Only parents can read parents subcollection
- Only parents can write to children subcollection
- Children can read their own document only

**Transaction-level:**
- Parents can read all transactions in family
- Children can only read transactions where `childId === their ID` (if `allowChildViewTransactions === true`)
- Only Cloud Functions can write transactions (security via callable functions)

**UserProfile-level:**
- Users can only read/write their own profile
- Cloud Functions can write any profile

---

## 8. Index Requirements

Firestore will auto-create most single-field indexes. Composite indexes needed:

1. **Transactions by child + timestamp:**
   ```
   Collection: transactions
   Fields: childId (Ascending), timestamp (Descending)
   ```

2. **Children by family (auto-created via subcollection)**

---

## 9. Data Migration & Versioning

### Schema Version Field

Add to family document:
```json
{
  "schemaVersion": "1.0.0"
}
```

Future schema changes can check this field and run migrations via Cloud Functions.

---

## 10. Example Data Flow: Parent Multiplies Investment

1. **Parent taps "Multiply Investment 2x" button in UI**
2. **Rhodey (Mobile):** Calls Cloud Function via Riverpod action:
   ```dart
   final result = await ref.read(multiplyInvestmentProvider(
     familyId: familyId,
     childId: childId,
     multiplier: 2.0,
   ).future);
   ```

3. **JARVIS (Backend):** Cloud Function `multiplyInvestment` executes:
   - Validates parent permission
   - Reads current investment: `$50.00`
   - Calculates new amount: `$50.00 × 2.0 = $100.00`
   - Creates transaction document
   - Updates child buckets atomically

4. **Real-time sync:** Firestore pushes update to all listeners
5. **Rhodey (Mobile):** `childBucketsProvider` receives update, UI re-renders
6. **Child sees:** Investment bucket animates from $50 → $100 🎉

---

## Summary

This data model provides:
- ✅ Multi-parent support (multiple parents in `/families/{familyId}/parents`)
- ✅ Multi-child support (multiple children in `/families/{familyId}/children`)
- ✅ Three buckets per child (money, investment, charity)
- ✅ Immutable transaction log for complete audit trail
- ✅ Real-time sync for critical data (buckets, recent transactions)
- ✅ Efficient queries via Riverpod providers
- ✅ Secure operations via Cloud Functions (parents can't directly edit child docs)
- ✅ Scalability (subcollections, indexed queries)
- ✅ Flexibility for future features (permissions, settings, stats)

**Next Steps:**
1. Fury implements Firestore Security Rules based on this model
2. JARVIS implements Cloud Functions (Node.js/TypeScript in `/functions`)
3. Rhodey implements Riverpod providers and data models (Dart classes)
4. Happy writes integration tests for Cloud Functions
