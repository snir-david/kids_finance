import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../transactions/domain/transaction.dart' as app_tx;

/// Stream of all transactions for a family, ordered newest-first.
/// Optionally filtered by [childId] (pass null for all children).
/// Client-side type filtering is done in the screen.
final familyFeedProvider = StreamProvider.family<
    List<app_tx.Transaction>,
    ({String familyId, String? childId})>((ref, params) {
  var query = FirebaseFirestore.instance
      .collection('families')
      .doc(params.familyId)
      .collection('transactions')
      .orderBy('performedAt', descending: true)
      .limit(150);

  if (params.childId != null) {
    // composite index on childId + performedAt already exists (used by existing history screen)
    query = FirebaseFirestore.instance
        .collection('families')
        .doc(params.familyId)
        .collection('transactions')
        .where('childId', isEqualTo: params.childId)
        .orderBy('performedAt', descending: true)
        .limit(150);
  }

  return query.snapshots().map((snap) => snap.docs
      .map((doc) => app_tx.Transaction.fromJson({'id': doc.id, ...doc.data()}))
      .toList());
});
