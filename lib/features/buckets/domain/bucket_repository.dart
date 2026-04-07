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
    double? baseValue,
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
    double? baseValue,
  });

  /// Donate charity bucket (sets balance to 0)
  /// Creates a transaction of type charityDonated
  Future<void> donateCharity({
    required String childId,
    required String familyId,
    required String performedByUid,
    String? note,
    double? baseValue,
  });

  /// Add money to money bucket
  Future<void> addMoney({
    required String childId,
    required String familyId,
    required double amount,
    required String performedByUid,
    String? note,
    double? baseValue,
  });

  /// Remove money from money bucket
  Future<void> removeMoney({
    required String childId,
    required String familyId,
    required double amount,
    required String performedByUid,
    String? note,
    double? baseValue,
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
    double? baseValueMoney,
    double? baseValueInvestment,
    double? baseValueCharity,
  });

  /// Donates the entire charity bucket balance.
  /// Records a transaction of type [donate] on the charity bucket.
  /// Sets charity balance to 0 and returns the donated amount.
  Future<double> donateBucket(String familyId, String childId);

  /// Moves [amount] from one bucket to another atomically.
  /// Validates amount > 0 and that [from] bucket has sufficient balance.
  /// Records two [transfer] transactions: one debit on [from], one credit on [to].
  /// Throws [ArgumentError] if amount <= 0 or insufficient balance.
  Future<void> transferBetweenBuckets(
    String familyId,
    String childId,
    BucketType from,
    BucketType to,
    double amount,
  );

  /// Subtracts [amount] from the Money bucket (purchase simulation).
  /// Validates amount > 0 and sufficient balance.
  /// Records a transaction of type [spend] on the money bucket.
  /// Throws [ArgumentError] if amount <= 0 or insufficient balance.
  Future<void> withdrawFromBucket(String familyId, String childId, double amount);

  /// Multiplies the given [bucketType]'s balance by [multiplier].
  /// Infers performedByUid from current Firebase Auth user.
  /// Throws [ArgumentError] if multiplier <= 0.
  Future<void> multiplyBucket(
    String familyId,
    String childId,
    BucketType bucketType,
    double multiplier,
  );
}
