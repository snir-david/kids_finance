// Manually written fake BucketRepository for unit tests.
// No build_runner / code generation required (Flutter 3.41.6 incompatibility).
//
// Implements the full BucketRepository interface in memory so tests run
// immediately without a real Firestore instance.

import 'package:kids_finance/features/buckets/domain/bucket.dart';
import 'package:kids_finance/features/buckets/domain/bucket_repository.dart';

class FakeBucketRepository implements BucketRepository {
  final Map<BucketType, double> _balances = {
    BucketType.money: 0.0,
    BucketType.investment: 0.0,
    BucketType.charity: 0.0,
  };

  // Each entry: {'type': String, 'bucketType': String?, 'amount': double, ...}
  final List<Map<String, dynamic>> transactions = [];

  // ── Test helpers ──────────────────────────────────────────────────────────

  double getBalance(BucketType type) => _balances[type]!;

  void setBalance(BucketType type, double balance) {
    _balances[type] = balance;
  }

  void reset() {
    _balances.updateAll((_, __) => 0.0);
    transactions.clear();
  }

  // ── BucketRepository interface ────────────────────────────────────────────

  @override
  Stream<List<Bucket>> getBucketsStream({
    required String childId,
    required String familyId,
  }) {
    final now = DateTime.now();
    return Stream.value(_balances.entries.map((e) {
      return Bucket(
        id: e.key.name,
        childId: childId,
        familyId: familyId,
        type: e.key,
        balance: e.value,
        lastUpdatedAt: now,
      );
    }).toList());
  }

  @override
  Future<void> setMoneyBalance({
    required String childId,
    required String familyId,
    required double newBalance,
    required String performedByUid,
    String? note,
    double? baseValue,
  }) async {
    if (newBalance < 0) throw ArgumentError('Balance cannot be negative');
    final prev = _balances[BucketType.money]!;
    _balances[BucketType.money] = newBalance;
    transactions.add({
      'type': 'moneySet',
      'bucketType': 'money',
      'amount': newBalance - prev,
      'performedByUid': performedByUid,
    });
  }

  @override
  Future<void> multiplyInvestment({
    required String childId,
    required String familyId,
    required double multiplier,
    required String performedByUid,
    String? note,
    double? baseValue,
  }) async {
    if (multiplier <= 0) {
      throw ArgumentError('Investment multiplier must be greater than 0');
    }
    final prev = _balances[BucketType.investment]!;
    final newBalance = prev * multiplier;
    _balances[BucketType.investment] = newBalance;
    transactions.add({
      'type': 'investmentMultiplied',
      'bucketType': 'investment',
      'multiplier': multiplier,
      'amount': newBalance - prev,
      'performedByUid': performedByUid,
    });
  }

  @override
  Future<void> donateCharity({
    required String childId,
    required String familyId,
    required String performedByUid,
    String? note,
    double? baseValue,
  }) async {
    final prev = _balances[BucketType.charity]!;
    _balances[BucketType.charity] = 0.0;
    transactions.add({
      'type': 'charityDonated',
      'bucketType': 'charity',
      'amount': prev,
      'performedByUid': performedByUid,
    });
  }

  @override
  Future<void> addMoney({
    required String childId,
    required String familyId,
    required double amount,
    required String performedByUid,
    String? note,
    double? baseValue,
  }) async {
    if (amount <= 0) throw ArgumentError('Amount must be positive');
    _balances[BucketType.money] = _balances[BucketType.money]! + amount;
    transactions.add({
      'type': 'moneyAdded',
      'bucketType': 'money',
      'amount': amount,
      'performedByUid': performedByUid,
    });
  }

  @override
  Future<void> removeMoney({
    required String childId,
    required String familyId,
    required double amount,
    required String performedByUid,
    String? note,
    double? baseValue,
  }) async {
    if (amount <= 0) throw ArgumentError('Amount must be positive');
    if (_balances[BucketType.money]! < amount) {
      throw ArgumentError('Insufficient balance');
    }
    _balances[BucketType.money] = _balances[BucketType.money]! - amount;
    transactions.add({
      'type': 'moneyRemoved',
      'bucketType': 'money',
      'amount': amount,
      'performedByUid': performedByUid,
    });
  }

  @override
  Future<void> distributeFunds({
    required String familyId,
    required String childId,
    required double moneyAmount,
    required double investmentAmount,
    required double charityAmount,
    required String performedByUid,
    String? note,
    double? baseValueMoney,
    double? baseValueInvestment,
    double? baseValueCharity,
  }) async {
    if (moneyAmount < 0 || investmentAmount < 0 || charityAmount < 0) {
      throw ArgumentError('All amounts must be >= 0');
    }
    if (moneyAmount + investmentAmount + charityAmount <= 0) {
      throw ArgumentError('Total distributed amount must be greater than 0');
    }
    _balances[BucketType.money] = _balances[BucketType.money]! + moneyAmount;
    _balances[BucketType.investment] =
        _balances[BucketType.investment]! + investmentAmount;
    _balances[BucketType.charity] =
        _balances[BucketType.charity]! + charityAmount;
  }

  // ── New methods (Sprint 5E) ───────────────────────────────────────────────

  @override
  Future<double> donateBucket(String familyId, String childId) async {
    final amount = _balances[BucketType.charity]!;
    _balances[BucketType.charity] = 0.0;
    transactions.add({
      'type': 'donate',
      'bucketType': 'charity',
      'amount': amount,
    });
    return amount;
  }

  @override
  Future<void> transferBetweenBuckets(
    String familyId,
    String childId,
    BucketType from,
    BucketType to,
    double amount,
  ) async {
    if (amount <= 0) throw ArgumentError('Transfer amount must be > 0');
    if (from == to) throw ArgumentError('Cannot transfer to the same bucket');
    if (_balances[from]! < amount) throw ArgumentError('Insufficient funds');
    _balances[from] = _balances[from]! - amount;
    _balances[to] = _balances[to]! + amount;
    // Two transfer records: debit on [from], credit on [to]
    transactions.add({'type': 'transfer', 'bucketType': from.name, 'amount': -amount});
    transactions.add({'type': 'transfer', 'bucketType': to.name, 'amount': amount});
  }

  @override
  Future<void> withdrawFromBucket(
    String familyId,
    String childId,
    double amount,
  ) async {
    if (amount <= 0) throw ArgumentError('Withdrawal amount must be > 0');
    if (_balances[BucketType.money]! < amount) {
      throw ArgumentError('Insufficient funds');
    }
    _balances[BucketType.money] = _balances[BucketType.money]! - amount;
    transactions.add({
      'type': 'spend',
      'bucketType': 'money',
      'amount': amount,
    });
  }

  @override
  Future<void> multiplyBucket(
    String familyId,
    String childId,
    BucketType bucketType,
    double multiplier,
  ) async {
    if (multiplier <= 0) {
      throw ArgumentError('Multiplier must be greater than 0');
    }
    final prev = _balances[bucketType]!;
    final newBalance = prev * multiplier;
    _balances[bucketType] = newBalance;
    transactions.add({
      'type': 'investmentMultiplied',
      'bucketType': bucketType.name,
      'multiplier': multiplier,
      'amount': newBalance - prev,
    });
  }
}
