import 'transaction.dart';

abstract class TransactionRepository {
  /// Stream all transactions for a specific child
  Stream<List<Transaction>> getTransactionsStream({
    required String childId,
    required String familyId,
    int? limit,
  });

  /// Log a transaction (internal use by bucket operations)
  Future<void> logTransaction(Transaction transaction);

  /// Archive transactions older than 1 year
  /// Should prompt user first before calling this
  Future<void> archiveOldTransactions({
    required String familyId,
    required DateTime cutoffDate,
  });
}
