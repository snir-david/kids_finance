import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../domain/transaction.dart';
import '../domain/transaction_repository.dart';
import '../data/firebase_transaction_repository.dart';

part 'transaction_providers.g.dart';

/// Repository provider
@riverpod
TransactionRepository transactionRepository(TransactionRepositoryRef ref) {
  return FirebaseTransactionRepository(firestore: FirebaseFirestore.instance);
}

/// Stream provider for transaction history of a child
@riverpod
Stream<List<Transaction>> transactionHistory(TransactionHistoryRef ref, {
  required String childId,
  required String familyId,
}) {
  final repository = ref.watch(transactionRepositoryProvider);
  return repository.getTransactionsStream(
    childId: childId,
    familyId: familyId,
  );
}

/// Stream provider for recent transactions (last 10)
@riverpod
Stream<List<Transaction>> recentTransactions(RecentTransactionsRef ref, {
  required String childId,
  required String familyId,
}) {
  final repository = ref.watch(transactionRepositoryProvider);
  return repository.getTransactionsStream(
    childId: childId,
    familyId: familyId,
    limit: 10,
  );
}

/// Provider to get transactions by type
@riverpod
Stream<List<Transaction>> transactionsByType(TransactionsByTypeRef ref, {
  required String childId,
  required String familyId,
  required TransactionType type,
}) {
  final allTransactionsAsync = ref.watch(transactionHistoryProvider(
    childId: childId,
    familyId: familyId,
  ));

  return allTransactionsAsync.when(
    data: (transactions) {
      return Stream.value(
        transactions.where((txn) => txn.type == type).toList(),
      );
    },
    loading: () => Stream.value([]),
    error: (error, stack) => Stream.error(error, stack),
  );
}
