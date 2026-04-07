# KidsFinance Firestore Data Model

**Author:** JARVIS (Backend Developer)  
**Date:** 2026-04-08  
**Version:** 2.0 — Updated for Sprints 5A–5D

---

## 1. Collection/Document Structure

```
/families/{familyId}
  - Family metadata: name, parentIds[], childIds[], inviteCode, createdAt

  /children/{childId}
    - Child: displayName, avatarEmoji, pinHash, sessionExpiresAt, archived, createdAt

    /buckets/{bucketType}          ← bucketType is "money", "investment", or "charity"
      - Bucket: id, childId, familyId, type, balance, lastUpdatedAt

  /transactions/{transactionId}
    - Immutable log of all balance-changing events (all children in the family)
    - Filtered by childId when querying per-child history
```

> ⚠️ **No `/parents` subcollection** — parents are identified via the `parentIds` array in the family document.  
> ⚠️ **No `/userProfiles` top-level collection** — family membership is always verified by reading `families/{familyId}.parentIds`.

### Design Rationale
- **Family as root:** All data lives under `/families/{familyId}` for clear security rule scoping
- **Buckets as subcollection:** Each bucket is a separate document under the child, not a nested map — enables atomic per-bucket writes without re-writing the whole child doc
- **Family-level transaction log:** One flat `transactions` collection per family, filtered by `childId` — avoids Collection Group Index complications and keeps audit trail in one place

---

## 2. Data Models

### 2.1 Family Document

**Path:** `/families/{familyId}`

```json
{
  "id": "family_abc123",
  "name": "The Smiths",
  "parentIds": ["uid_parent1", "uid_parent2"],
  "childIds": ["child_abc456"],
  "createdAt": "<Timestamp>",
  "schemaVersion": "1.0.0"
}
```

**Fields:**
- `id` (string): Firestore document ID — same as `familyId`
- `name` (string): Display name of the family
- `parentIds` (array of strings): Firebase Auth UIDs of all parents — used by security rules and Cloud Functions to verify family membership (JWT spoofing-safe)
- `childIds` (array of strings): IDs of all children in the family
- `createdAt` (Timestamp): When family was created — stored as `Timestamp.fromDate()`
- `schemaVersion` (string): Data model version, currently `"1.0.0"`

> ❌ **Not implemented:** `familyName`, `settings`, `createdBy`, `updatedAt`, `inviteCode` — these were planned but are not in the current domain model or security rules.

---

### 2.2 Child Document

**Path:** `/families/{familyId}/children/{childId}`

```json
{
  "id": "child_abc456",
  "familyId": "family_abc123",
  "displayName": "Emma",
  "avatarEmoji": "🦄",
  "pinHash": "$2b$10$...",
  "sessionExpiresAt": "<Timestamp or null>",
  "createdAt": "<Timestamp>",
  "archived": false
}
```

**Fields:**
- `id` (string): Document ID
- `familyId` (string): Parent family's ID
- `displayName` (string): Child's first name (1–50 chars, required)
- `avatarEmoji` (string): Single emoji for the child's avatar
- `pinHash` (string): bcrypt hash of the child's PIN — never stored plaintext
- `sessionExpiresAt` (Timestamp | null): When the child's current login session expires (24h from last PIN entry). Null means no active session.
- `createdAt` (Timestamp): Account creation time — stored as `Timestamp.fromDate()`
- `archived` (bool): Soft-delete flag. `true` = child hidden from UI but data preserved. Default `false`.

> ❌ **Not implemented:** `userId`, `photoUrl`, `role`, `createdBy`, `updatedAt`, `buckets` (map), `stats` — these were in the old design. Buckets are now a separate subcollection.

---

### 2.3 Bucket Document

**Path:** `/families/{familyId}/children/{childId}/buckets/{bucketType}`

`{bucketType}` is one of: `money`, `investment`, `charity`

```json
{
  "id": "money",
  "childId": "child_abc456",
  "familyId": "family_abc123",
  "type": "money",
  "balance": 50.00,
  "lastUpdatedAt": "<Timestamp>"
}
```

**Fields:**
- `id` (string): Document ID — same as `type` value (`money`, `investment`, or `charity`)
- `childId` (string): Owner child's ID (non-empty)
- `familyId` (string): Owner family's ID (non-empty)
- `type` (string): One of `money`, `investment`, `charity`
- `balance` (number): Current balance. Always `>= 0` (enforced by security rules)
- `lastUpdatedAt` (Timestamp): Last write time — stored as `Timestamp.fromDate()`

> ❌ **Not implemented:** `lastUpdatedBy`, `totalEarnings`, `totalDonated`, `lastMultipliedAt`, `lastDonatedAt` — simplified from original design.

---

### 2.4 Transaction Document

**Path:** `/families/{familyId}/transactions/{transactionId}`

All transactions share the same base structure. The document is **immutable** — created once, never updated or deleted.

```json
{
  "id": "txn_20260407_abc123",
  "familyId": "family_abc123",
  "childId": "child_abc456",
  "bucketType": "investment",
  "type": "investmentMultiplied",
  "amount": 50.00,
  "multiplier": 2.0,
  "previousBalance": 50.00,
  "newBalance": 100.00,
  "note": "Great savings!",
  "performedByUid": "uid_parent1",
  "performedAt": "<Timestamp>"
}
```

**Fields:**
- `id` (string): Document ID
- `familyId` (string): Family this transaction belongs to
- `childId` (string): Which child's bucket was affected
- `bucketType` (string): `money`, `investment`, or `charity`
- `type` (string): Transaction type (see below)
- `amount` (number): Absolute amount involved in the operation (always >= 0)
- `multiplier` (number | null): Only set for `investmentMultiplied` — the multiplication factor applied
- `previousBalance` (number): Bucket balance before the operation
- `newBalance` (number): Bucket balance after the operation
- `note` (string | null): Optional parent-supplied note
- `performedByUid` (string): Firebase Auth UID of the actor (parent's UID)
- `performedAt` (Timestamp): When the operation occurred — stored as `Timestamp.fromDate()`

**Transaction Types (`type` field values):**

| Type | Bucket | Description |
|------|--------|-------------|
| `moneySet` | money | Parent set money balance to a specific amount |
| `moneyAdded` | money | Parent added money to money bucket |
| `moneyRemoved` | money | Parent removed money from money bucket |
| `investmentMultiplied` | investment | Parent multiplied investment by a factor (must be > 0) |
| `charityDonated` | charity | Charity bucket reset to 0 (full donation) |
| `distributed` | money / investment / charity | Allowance split across all 3 buckets atomically |

> ❌ **Not implemented:** `investment_multiply`, `charity_donate`, `money_adjust`, `bucket_transfer` — these were the old type names. The real enum values are listed above.  
> ❌ **Removed:** `transactionId`, `performedBy`, `timestamp`, `data` (map), `description` — replaced by the flat field structure above.  
> ⚠️ **`distributed` type:** Creates **one log entry per affected bucket** in the same Firestore transaction. All three entries share the same logical operation but are separate documents.

---

## 3. Timestamp Rule

> **All date/time fields use `Timestamp.fromDate(DateTime)` — never ISO 8601 strings.**

```dart
// ✅ Correct
'createdAt': Timestamp.fromDate(DateTime.now()),
'sessionExpiresAt': Timestamp.fromDate(expiry),

// ❌ Wrong — caused a production crash (Sprint 5A)
'createdAt': DateTime.now().toIso8601String(),
```

When reading, `fromJson` methods use a dual-type guard for backward compatibility:
```dart
final raw = json['createdAt'];
final dt = raw is Timestamp ? raw.toDate() : DateTime.parse(raw as String);
```

---

## 4. Security Rules Summary

See `firestore.rules` for full implementation. Key points:

- **Family isolation:** `isParentOfFamily(familyId)` reads the `parentIds` array directly from Firestore — not from JWT claims (JWT spoofing fix, Sprint 5C)
- **Child documents:** Parent read/write, no hard delete (`allow delete: if false`)
- **Bucket documents:** Parent read/write, `balance >= 0` enforced on every write, no hard delete
- **Transaction documents:** Append-only — parents can create, no one can update or delete
- **Everything else:** Default deny (`allow read, write: if false`)

---

## 5. Cloud Functions

Four callable functions in `functions/src/index.ts`:

| Function | What it does |
|----------|--------------|
| `createFamily` | Creates family doc, writes `parentIds`, sets custom JWT claim |
| `addFundsToChild` | Validates amount > 0, verifies `parentIds` membership, writes to bucket + transaction |
| `multiplyBucket` | Validates multiplier > 0, verifies `parentIds` membership, multiplies investment balance |
| `distributeFunds` | Splits amount across ≥1 buckets; validates each amount ≥ 0 and total > 0 |

All functions use `assertFamilyMembership(uid, familyId)` — reads `families/{familyId}.parentIds` in Firestore instead of trusting JWT `familyId` claim.

---

## 6. Index Requirements

One composite index is required:

```
Collection: families/{familyId}/transactions
Fields: childId (Ascending), performedAt (Descending)
```

This enables per-child transaction history queries. Create via Firebase Console → Firestore → Indexes.

---

## 7. Offline Sync (Hive)

When a device is offline, write operations are queued in Hive (`PendingOperation` objects). On reconnect, `SyncEngine` replays the queue:

- **Conflict detection:** For `setMoney`, `distribute`, `multiply`, `donate` — compares server balance to the `baseValue` captured at queue time
- **Conflict resolution:** User prompt (use local or use server) — never silent last-write-wins for balance ops
- **TTL:** Operations older than 24h are purged. Warning appears at 23h.
- **No-conflict ops:** `addMoney`, `removeMoney`, `updateChild`, `archiveChild` — always last-write-wins

---

_JARVIS — last updated Sprint 5D (2026-04-08)_
