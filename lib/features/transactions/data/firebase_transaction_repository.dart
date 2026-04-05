import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/transaction.dart';
import '../domain/transaction_repository.dart';

class FirebaseTransactionRepository implements TransactionRepository {
  final FirebaseFirestore _firestore;

  FirebaseTransactionRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Stream<List<Transaction>> getTransactionsStream({
    required String childId,
    required String familyId,
    int? limit,
  }) {
    var query = _firestore
        .collection('families')
        .doc(familyId)
        .collection('transactions')
        .where('childId', isEqualTo: childId)
        .orderBy('performedAt', descending: true);

    if (limit != null) {
      query = query.limit(limit);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return Transaction.fromJson({
          'id': doc.id,
          ...doc.data(),
        });
      }).toList();
    });
  }

  @override
  Future<void> logTransaction(Transaction transaction) async {
    final transactionRef = _firestore
        .collection('families')
        .doc(transaction.familyId)
        .collection('transactions')
        .doc(transaction.id);

    await transactionRef.set(transaction.toJson()..remove('id'));
  }

  @override
  Future<void> archiveOldTransactions({
    required String familyId,
    required DateTime cutoffDate,
  }) async {
    // Query transactions older than cutoffDate
    final oldTransactions = await _firestore
        .collection('families')
        .doc(familyId)
        .collection('transactions')
        .where('performedAt', isLessThan: cutoffDate.toIso8601String())
        .get();

    // Archive collection for historical records
    final archiveRef = _firestore
        .collection('families')
        .doc(familyId)
        .collection('archivedTransactions');

    final batch = _firestore.batch();
    
    for (final doc in oldTransactions.docs) {
      // Copy to archive
      batch.set(archiveRef.doc(doc.id), doc.data());
      
      // Delete from active transactions
      batch.delete(doc.reference);
    }

    await batch.commit();
  }
}
