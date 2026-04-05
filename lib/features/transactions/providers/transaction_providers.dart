/// Riverpod providers for transaction-related functionality.
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/transaction.dart' as app_transaction;
import '../domain/transaction_repository.dart';
import '../data/firebase_transaction_repository.dart';

/// Repository provider
final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  return FirebaseTransactionRepository(firestore: FirebaseFirestore.instance);
});

/// Stream provider for transaction history of a child
final transactionHistoryProvider = StreamProvider.family<
    List<app_transaction.Transaction>,
    ({String childId, String familyId})>((ref, params) {
  final repository = ref.watch(transactionRepositoryProvider);
  return repository.getTransactionsStream(
    childId: params.childId,
    familyId: params.familyId,
  );
});

/// Stream provider for recent transactions (last 10)
final recentTransactionsProvider = StreamProvider.family<
    List<app_transaction.Transaction>,
    ({String childId, String familyId})>((ref, params) {
  final repository = ref.watch(transactionRepositoryProvider);
  return repository.getTransactionsStream(
    childId: params.childId,
    familyId: params.familyId,
    limit: 10,
  );
});

/// Provider to get transactions by type
final transactionsByTypeProvider = StreamProvider.family<
    List<app_transaction.Transaction>,
    ({
      String childId,
      String familyId,
      app_transaction.TransactionType type
    })>((ref, params) {
  final allTransactionsAsync = ref.watch(transactionHistoryProvider((
    childId: params.childId,
    familyId: params.familyId,
  )));

  return allTransactionsAsync.when(
    data: (transactions) {
      return Stream.value(
        transactions.where((txn) => txn.type == params.type).toList(),
      );
    },
    loading: () => Stream.value([]),
    error: (error, stack) => Stream.error(error, stack),
  );
});
