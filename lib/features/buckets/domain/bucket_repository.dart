import 'bucket.dart';

abstract class BucketRepository {
  /// Stream all buckets for a specific child
  Stream<List<Bucket>> getBucketsStream({
    required String childId,
    required String familyId,
  });

  /// Set money bucket balance to a specific amount
  /// Creates a transaction of type moneySet
  Future<void> setMoneyBalance({
    required String childId,
    required String familyId,
    required double newBalance,
    required String performedByUid,
    String? note,
  });

  /// Multiply investment bucket by a multiplier
  /// Creates a transaction of type investmentMultiplied
  /// Throws ArgumentError if multiplier <= 0
  Future<void> multiplyInvestment({
    required String childId,
    required String familyId,
    required double multiplier,
    required String performedByUid,
    String? note,
  });

  /// Donate charity bucket (sets balance to 0)
  /// Creates a transaction of type charityDonated
  Future<void> donateCharity({
    required String childId,
    required String familyId,
    required String performedByUid,
    String? note,
  });

  /// Add money to money bucket
  Future<void> addMoney({
    required String childId,
    required String familyId,
    required double amount,
    required String performedByUid,
    String? note,
  });

  /// Remove money from money bucket
  Future<void> removeMoney({
    required String childId,
    required String familyId,
    required double amount,
    required String performedByUid,
    String? note,
  });

  /// Distribute/split an allowance across all 3 buckets atomically.
  /// Each amount must be >= 0 and total must be > 0.
  /// Creates one transaction log entry per bucket with type 'distributed'.
  Future<void> distributeFunds({
    required String familyId,
    required String childId,
    required double moneyAmount,
    required double investmentAmount,
    required double charityAmount,
    required String performedByUid,
    String? note,
  });
}
