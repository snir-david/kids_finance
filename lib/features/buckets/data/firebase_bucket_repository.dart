import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/bucket.dart';
import '../domain/bucket_repository.dart';
import '../../transactions/domain/transaction.dart';

class FirebaseBucketRepository implements BucketRepository {
  final FirebaseFirestore _firestore;

  FirebaseBucketRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Stream<List<Bucket>> getBucketsStream({
    required String childId,
    required String familyId,
  }) {
    return _firestore
        .collection('families')
        .doc(familyId)
        .collection('children')
        .doc(childId)
        .collection('buckets')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Bucket.fromJson({
          'id': doc.id,
          ...doc.data(),
        });
      }).toList();
    });
  }

  @override
  Future<void> setMoneyBalance({
    required String childId,
    required String familyId,
    required double newBalance,
    required String performedByUid,
    String? note,
  }) async {
    if (newBalance < 0) {
      throw ArgumentError('Balance cannot be negative');
    }

    final bucketRef = _firestore
        .collection('families')
        .doc(familyId)
        .collection('children')
        .doc(childId)
        .collection('buckets')
        .doc('money');

    final transactionRef =
        _firestore.collection('families').doc(familyId).collection('transactions').doc();

    await _firestore.runTransaction((transaction) async {
      // Get current balance
      final bucketSnapshot = await transaction.get(bucketRef);
      final currentBalance = (bucketSnapshot.data()?['balance'] as num?)?.toDouble() ?? 0.0;

      final now = DateTime.now();

      // Create transaction log
      final txn = Transaction(
        id: transactionRef.id,
        familyId: familyId,
        childId: childId,
        bucketType: BucketType.money,
        type: TransactionType.moneySet,
        amount: newBalance - currentBalance,
        multiplier: null,
        previousBalance: currentBalance,
        newBalance: newBalance,
        note: note,
        performedByUid: performedByUid,
        performedAt: now,
      );

      // Update bucket
      transaction.update(bucketRef, {
        'balance': newBalance,
        'lastUpdatedAt': now.toIso8601String(),
      });

      // Log transaction
      transaction.set(transactionRef, txn.toJson()..remove('id'));
    });
  }

  @override
  Future<void> multiplyInvestment({
    required String childId,
    required String familyId,
    required double multiplier,
    required String performedByUid,
    String? note,
  }) async {
    if (multiplier <= 0) {
      throw ArgumentError('Investment multiplier must be greater than 0');
    }

    final bucketRef = _firestore
        .collection('families')
        .doc(familyId)
        .collection('children')
        .doc(childId)
        .collection('buckets')
        .doc('investment');

    final transactionRef =
        _firestore.collection('families').doc(familyId).collection('transactions').doc();

    await _firestore.runTransaction((transaction) async {
      // Get current balance
      final bucketSnapshot = await transaction.get(bucketRef);
      final currentBalance = (bucketSnapshot.data()?['balance'] as num?)?.toDouble() ?? 0.0;

      final newBalance = currentBalance * multiplier;
      final amount = newBalance - currentBalance;
      final now = DateTime.now();

      // Create transaction log
      final txn = Transaction(
        id: transactionRef.id,
        familyId: familyId,
        childId: childId,
        bucketType: BucketType.investment,
        type: TransactionType.investmentMultiplied,
        amount: amount,
        multiplier: multiplier,
        previousBalance: currentBalance,
        newBalance: newBalance,
        note: note,
        performedByUid: performedByUid,
        performedAt: now,
      );

      // Update bucket
      transaction.update(bucketRef, {
        'balance': newBalance,
        'lastUpdatedAt': now.toIso8601String(),
      });

      // Log transaction
      transaction.set(transactionRef, txn.toJson()..remove('id'));
    });
  }

  @override
  Future<void> donateCharity({
    required String childId,
    required String familyId,
    required String performedByUid,
    String? note,
  }) async {
    final bucketRef = _firestore
        .collection('families')
        .doc(familyId)
        .collection('children')
        .doc(childId)
        .collection('buckets')
        .doc('charity');

    final transactionRef =
        _firestore.collection('families').doc(familyId).collection('transactions').doc();

    await _firestore.runTransaction((transaction) async {
      // Get current balance
      final bucketSnapshot = await transaction.get(bucketRef);
      final currentBalance = (bucketSnapshot.data()?['balance'] as num?)?.toDouble() ?? 0.0;

      final now = DateTime.now();

      // Create transaction log
      final txn = Transaction(
        id: transactionRef.id,
        familyId: familyId,
        childId: childId,
        bucketType: BucketType.charity,
        type: TransactionType.charityDonated,
        amount: currentBalance,
        multiplier: null,
        previousBalance: currentBalance,
        newBalance: 0.0,
        note: note,
        performedByUid: performedByUid,
        performedAt: now,
      );

      // Update bucket (set to 0)
      transaction.update(bucketRef, {
        'balance': 0.0,
        'lastUpdatedAt': now.toIso8601String(),
      });

      // Log transaction
      transaction.set(transactionRef, txn.toJson()..remove('id'));
    });
  }

  @override
  Future<void> addMoney({
    required String childId,
    required String familyId,
    required double amount,
    required String performedByUid,
    String? note,
  }) async {
    if (amount <= 0) {
      throw ArgumentError('Amount must be positive');
    }

    final bucketRef = _firestore
        .collection('families')
        .doc(familyId)
        .collection('children')
        .doc(childId)
        .collection('buckets')
        .doc('money');

    final transactionRef =
        _firestore.collection('families').doc(familyId).collection('transactions').doc();

    await _firestore.runTransaction((transaction) async {
      // Get current balance
      final bucketSnapshot = await transaction.get(bucketRef);
      final currentBalance = (bucketSnapshot.data()?['balance'] as num?)?.toDouble() ?? 0.0;

      final newBalance = currentBalance + amount;
      final now = DateTime.now();

      // Create transaction log
      final txn = Transaction(
        id: transactionRef.id,
        familyId: familyId,
        childId: childId,
        bucketType: BucketType.money,
        type: TransactionType.moneyAdded,
        amount: amount,
        multiplier: null,
        previousBalance: currentBalance,
        newBalance: newBalance,
        note: note,
        performedByUid: performedByUid,
        performedAt: now,
      );

      // Update bucket
      transaction.update(bucketRef, {
        'balance': newBalance,
        'lastUpdatedAt': now.toIso8601String(),
      });

      // Log transaction
      transaction.set(transactionRef, txn.toJson()..remove('id'));
    });
  }

  @override
  Future<void> removeMoney({
    required String childId,
    required String familyId,
    required double amount,
    required String performedByUid,
    String? note,
  }) async {
    if (amount <= 0) {
      throw ArgumentError('Amount must be positive');
    }

    final bucketRef = _firestore
        .collection('families')
        .doc(familyId)
        .collection('children')
        .doc(childId)
        .collection('buckets')
        .doc('money');

    final transactionRef =
        _firestore.collection('families').doc(familyId).collection('transactions').doc();

    await _firestore.runTransaction((transaction) async {
      // Get current balance
      final bucketSnapshot = await transaction.get(bucketRef);
      final currentBalance = (bucketSnapshot.data()?['balance'] as num?)?.toDouble() ?? 0.0;

      if (currentBalance < amount) {
        throw ArgumentError('Insufficient balance');
      }

      final newBalance = currentBalance - amount;
      final now = DateTime.now();

      // Create transaction log
      final txn = Transaction(
        id: transactionRef.id,
        familyId: familyId,
        childId: childId,
        bucketType: BucketType.money,
        type: TransactionType.moneyRemoved,
        amount: amount,
        multiplier: null,
        previousBalance: currentBalance,
        newBalance: newBalance,
        note: note,
        performedByUid: performedByUid,
        performedAt: now,
      );

      // Update bucket
      transaction.update(bucketRef, {
        'balance': newBalance,
        'lastUpdatedAt': now.toIso8601String(),
      });

      // Log transaction
      transaction.set(transactionRef, txn.toJson()..remove('id'));
    });
  }
}
