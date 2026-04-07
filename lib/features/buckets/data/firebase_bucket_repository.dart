import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/bucket.dart';
import '../domain/bucket_repository.dart';
import '../../transactions/domain/transaction.dart' as app_transaction;
import '../../badges/data/services/badge_evaluation_service.dart';
import '../../../core/offline/connectivity_service.dart';
import '../../../core/offline/offline_queue.dart';
import '../../../core/offline/pending_operation.dart';

class FirebaseBucketRepository implements BucketRepository {
  final FirebaseFirestore _firestore;
  final ConnectivityService _connectivity;
  final OfflineQueue _queue;
  final BadgeEvaluationService? _badgeService;

  FirebaseBucketRepository({
    FirebaseFirestore? firestore,
    required ConnectivityService connectivity,
    required OfflineQueue queue,
    BadgeEvaluationService? badgeService,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _connectivity = connectivity,
        _queue = queue,
        _badgeService = badgeService;

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
    double? baseValue,
  }) async {
    if (newBalance < 0) {
      throw ArgumentError('Balance cannot be negative');
    }

    if (!await _connectivity.isOnline) {
      await _queue.enqueue(PendingOperation(
        id: _queue.generateId(),
        type: 'setMoney',
        payload: {
          'childId': childId,
          'familyId': familyId,
          'newBalance': newBalance,
          'performedByUid': performedByUid,
          'note': note,
          if (baseValue != null) 'baseValue': baseValue,
        },
        createdAt: DateTime.now(),
        retryCount: 0,
      ));
      return;
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
      final txn = app_transaction.Transaction(
        id: transactionRef.id,
        familyId: familyId,
        childId: childId,
        bucketType: BucketType.money,
        type: app_transaction.TransactionType.moneySet,
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
        'lastUpdatedAt': Timestamp.fromDate(now),
      });

      // Log transaction
      transaction.set(transactionRef, txn.toJson()..remove('id'));
    });

    unawaited(_badgeService?.evaluateAfterDeposit(familyId, childId, newBalance));
    unawaited(_badgeService?.evaluateStreak(familyId, childId));
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

    if (!await _connectivity.isOnline) {
      await _queue.enqueue(PendingOperation(
        id: _queue.generateId(),
        type: 'multiply',
        payload: {
          'childId': childId,
          'familyId': familyId,
          'multiplier': multiplier,
          'performedByUid': performedByUid,
          'note': note,
          if (baseValue != null) 'baseValue': baseValue,
        },
        createdAt: DateTime.now(),
        retryCount: 0,
      ));
      return;
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
      final txn = app_transaction.Transaction(
        id: transactionRef.id,
        familyId: familyId,
        childId: childId,
        bucketType: BucketType.investment,
        type: app_transaction.TransactionType.investmentMultiplied,
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
        'lastUpdatedAt': Timestamp.fromDate(now),
      });

      // Log transaction
      transaction.set(transactionRef, txn.toJson()..remove('id'));
    });

    unawaited(_badgeService?.evaluateAfterInvestmentMultiply(familyId, childId));
  }

  @override
  Future<void> donateCharity({
    required String childId,
    required String familyId,
    required String performedByUid,
    String? note,
    double? baseValue,
  }) async {
    if (!await _connectivity.isOnline) {
      await _queue.enqueue(PendingOperation(
        id: _queue.generateId(),
        type: 'donate',
        payload: {
          'childId': childId,
          'familyId': familyId,
          'performedByUid': performedByUid,
          'note': note,
          if (baseValue != null) 'baseValue': baseValue,
        },
        createdAt: DateTime.now(),
        retryCount: 0,
      ));
      return;
    }

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
      final txn = app_transaction.Transaction(
        id: transactionRef.id,
        familyId: familyId,
        childId: childId,
        bucketType: BucketType.charity,
        type: app_transaction.TransactionType.charityDonated,
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
        'lastUpdatedAt': Timestamp.fromDate(now),
      });

      // Log transaction
      transaction.set(transactionRef, txn.toJson()..remove('id'));
    });

    unawaited(_badgeService?.evaluateAfterDonation(familyId, childId));
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
    if (amount <= 0) {
      throw ArgumentError('Amount must be positive');
    }

    if (!await _connectivity.isOnline) {
      await _queue.enqueue(PendingOperation(
        id: _queue.generateId(),
        type: 'addMoney',
        payload: {
          'childId': childId,
          'familyId': familyId,
          'amount': amount,
          'performedByUid': performedByUid,
          'note': note,
        },
        createdAt: DateTime.now(),
        retryCount: 0,
      ));
      return;
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

    double addedNewBalance = 0.0;

    await _firestore.runTransaction((transaction) async {
      // Get current balance
      final bucketSnapshot = await transaction.get(bucketRef);
      final currentBalance = (bucketSnapshot.data()?['balance'] as num?)?.toDouble() ?? 0.0;

      final newBalance = currentBalance + amount;
      addedNewBalance = newBalance;
      final now = DateTime.now();

      // Create transaction log
      final txn = app_transaction.Transaction(
        id: transactionRef.id,
        familyId: familyId,
        childId: childId,
        bucketType: BucketType.money,
        type: app_transaction.TransactionType.moneyAdded,
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
        'lastUpdatedAt': Timestamp.fromDate(now),
      });

      // Log transaction
      transaction.set(transactionRef, txn.toJson()..remove('id'));
    });

    unawaited(_badgeService?.evaluateAfterDeposit(familyId, childId, addedNewBalance));
    unawaited(_badgeService?.evaluateStreak(familyId, childId));
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
    if (amount <= 0) {
      throw ArgumentError('Amount must be positive');
    }

    if (!await _connectivity.isOnline) {
      await _queue.enqueue(PendingOperation(
        id: _queue.generateId(),
        type: 'removeMoney',
        payload: {
          'childId': childId,
          'familyId': familyId,
          'amount': amount,
          'performedByUid': performedByUid,
          'note': note,
        },
        createdAt: DateTime.now(),
        retryCount: 0,
      ));
      return;
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
      final txn = app_transaction.Transaction(
        id: transactionRef.id,
        familyId: familyId,
        childId: childId,
        bucketType: BucketType.money,
        type: app_transaction.TransactionType.moneyRemoved,
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
        'lastUpdatedAt': Timestamp.fromDate(now),
      });

      // Log transaction
      transaction.set(transactionRef, txn.toJson()..remove('id'));
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

    if (!await _connectivity.isOnline) {
      await _queue.enqueue(PendingOperation(
        id: _queue.generateId(),
        type: 'distribute',
        payload: {
          'childId': childId,
          'familyId': familyId,
          'moneyAmount': moneyAmount,
          'investmentAmount': investmentAmount,
          'charityAmount': charityAmount,
          'performedByUid': performedByUid,
          'note': note,
          if (baseValueMoney != null) 'baseValueMoney': baseValueMoney,
          if (baseValueInvestment != null) 'baseValueInvestment': baseValueInvestment,
          if (baseValueCharity != null) 'baseValueCharity': baseValueCharity,
        },
        createdAt: DateTime.now(),
        retryCount: 0,
      ));
      return;
    }

    final childPath = _firestore
        .collection('families')
        .doc(familyId)
        .collection('children')
        .doc(childId);

    final moneyRef = childPath.collection('buckets').doc('money');
    final investmentRef = childPath.collection('buckets').doc('investment');
    final charityRef = childPath.collection('buckets').doc('charity');

    final txnsCollection =
        _firestore.collection('families').doc(familyId).collection('transactions');
    final moneyTxnRef = txnsCollection.doc();
    final investmentTxnRef = txnsCollection.doc();
    final charityTxnRef = txnsCollection.doc();

    double distributeMoneyNew = 0.0;

    await _firestore.runTransaction((tx) async {
      final moneySnap = await tx.get(moneyRef);
      final investmentSnap = await tx.get(investmentRef);
      final charitySnap = await tx.get(charityRef);

      final moneyPrev = (moneySnap.data()?['balance'] as num?)?.toDouble() ?? 0.0;
      final investmentPrev = (investmentSnap.data()?['balance'] as num?)?.toDouble() ?? 0.0;
      final charityPrev = (charitySnap.data()?['balance'] as num?)?.toDouble() ?? 0.0;

      final now = DateTime.now();
      final timestamp = Timestamp.fromDate(now);

      // Money bucket
      if (moneyAmount > 0) {
        final moneyNew = moneyPrev + moneyAmount;
        distributeMoneyNew = moneyNew;
        tx.update(moneyRef, {'balance': moneyNew, 'lastUpdatedAt': timestamp});
        tx.set(
          moneyTxnRef,
          app_transaction.Transaction(
            id: moneyTxnRef.id,
            familyId: familyId,
            childId: childId,
            bucketType: BucketType.money,
            type: app_transaction.TransactionType.distributed,
            amount: moneyAmount,
            multiplier: null,
            previousBalance: moneyPrev,
            newBalance: moneyNew,
            note: note,
            performedByUid: performedByUid,
            performedAt: now,
          ).toJson()
            ..remove('id'),
        );
      }

      // Investment bucket
      if (investmentAmount > 0) {
        final investmentNew = investmentPrev + investmentAmount;
        tx.update(investmentRef, {'balance': investmentNew, 'lastUpdatedAt': timestamp});
        tx.set(
          investmentTxnRef,
          app_transaction.Transaction(
            id: investmentTxnRef.id,
            familyId: familyId,
            childId: childId,
            bucketType: BucketType.investment,
            type: app_transaction.TransactionType.distributed,
            amount: investmentAmount,
            multiplier: null,
            previousBalance: investmentPrev,
            newBalance: investmentNew,
            note: note,
            performedByUid: performedByUid,
            performedAt: now,
          ).toJson()
            ..remove('id'),
        );
      }

      // Charity bucket
      if (charityAmount > 0) {
        final charityNew = charityPrev + charityAmount;
        tx.update(charityRef, {'balance': charityNew, 'lastUpdatedAt': timestamp});
        tx.set(
          charityTxnRef,
          app_transaction.Transaction(
            id: charityTxnRef.id,
            familyId: familyId,
            childId: childId,
            bucketType: BucketType.charity,
            type: app_transaction.TransactionType.distributed,
            amount: charityAmount,
            multiplier: null,
            previousBalance: charityPrev,
            newBalance: charityNew,
            note: note,
            performedByUid: performedByUid,
            performedAt: now,
          ).toJson()
            ..remove('id'),
        );
      }
    });

    if (distributeMoneyNew > 0) {
      unawaited(_badgeService?.evaluateAfterDeposit(familyId, childId, distributeMoneyNew));
      unawaited(_badgeService?.evaluateStreak(familyId, childId));
    }
  }

  @override
  Future<double> donateBucket(String familyId, String childId) async {
    if (!await _connectivity.isOnline) {
      await _queue.enqueue(PendingOperation(
        id: _queue.generateId(),
        type: 'donateBucket',
        payload: {'childId': childId, 'familyId': familyId},
        createdAt: DateTime.now(),
        retryCount: 0,
      ));
      return 0.0;
    }

    final bucketRef = _firestore
        .collection('families')
        .doc(familyId)
        .collection('children')
        .doc(childId)
        .collection('buckets')
        .doc('charity');

    final transactionRef =
        _firestore.collection('families').doc(familyId).collection('transactions').doc();

    double donatedAmount = 0.0;

    await _firestore.runTransaction((tx) async {
      final bucketSnapshot = await tx.get(bucketRef);
      final currentBalance = (bucketSnapshot.data()?['balance'] as num?)?.toDouble() ?? 0.0;
      donatedAmount = currentBalance;
      final now = DateTime.now();

      final txn = app_transaction.Transaction(
        id: transactionRef.id,
        familyId: familyId,
        childId: childId,
        bucketType: BucketType.charity,
        type: app_transaction.TransactionType.donate,
        amount: currentBalance,
        multiplier: null,
        previousBalance: currentBalance,
        newBalance: 0.0,
        note: null,
        performedByUid: 'system',
        performedAt: now,
      );

      tx.update(bucketRef, {
        'balance': 0.0,
        'lastUpdatedAt': Timestamp.fromDate(now),
      });
      tx.set(transactionRef, txn.toJson()..remove('id'));
    });

    unawaited(_badgeService?.evaluateAfterDonation(familyId, childId));

    return donatedAmount;
  }

  @override
  Future<void> transferBetweenBuckets(
    String familyId,
    String childId,
    BucketType from,
    BucketType to,
    double amount,
  ) async {
    if (amount <= 0) {
      throw ArgumentError('Transfer amount must be greater than 0');
    }

    if (!await _connectivity.isOnline) {
      await _queue.enqueue(PendingOperation(
        id: _queue.generateId(),
        type: 'transfer',
        payload: {
          'childId': childId,
          'familyId': familyId,
          'from': from.name,
          'to': to.name,
          'amount': amount,
        },
        createdAt: DateTime.now(),
        retryCount: 0,
      ));
      return;
    }

    final childPath = _firestore
        .collection('families')
        .doc(familyId)
        .collection('children')
        .doc(childId);

    final fromRef = childPath.collection('buckets').doc(from.name);
    final toRef = childPath.collection('buckets').doc(to.name);

    final txnsCollection =
        _firestore.collection('families').doc(familyId).collection('transactions');
    final fromTxnRef = txnsCollection.doc();
    final toTxnRef = txnsCollection.doc();

    await _firestore.runTransaction((tx) async {
      final fromSnap = await tx.get(fromRef);
      final toSnap = await tx.get(toRef);

      final fromBalance = (fromSnap.data()?['balance'] as num?)?.toDouble() ?? 0.0;
      final toBalance = (toSnap.data()?['balance'] as num?)?.toDouble() ?? 0.0;

      if (fromBalance < amount) {
        throw ArgumentError('Insufficient balance in ${from.name} bucket');
      }

      final fromNew = fromBalance - amount;
      final toNew = toBalance + amount;
      final now = DateTime.now();
      final timestamp = Timestamp.fromDate(now);

      tx.update(fromRef, {'balance': fromNew, 'lastUpdatedAt': timestamp});
      tx.update(toRef, {'balance': toNew, 'lastUpdatedAt': timestamp});

      tx.set(
        fromTxnRef,
        app_transaction.Transaction(
          id: fromTxnRef.id,
          familyId: familyId,
          childId: childId,
          bucketType: from,
          type: app_transaction.TransactionType.transfer,
          amount: -amount,
          multiplier: null,
          previousBalance: fromBalance,
          newBalance: fromNew,
          note: 'Transfer to ${to.name}',
          performedByUid: 'system',
          performedAt: now,
        ).toJson()
          ..remove('id'),
      );

      tx.set(
        toTxnRef,
        app_transaction.Transaction(
          id: toTxnRef.id,
          familyId: familyId,
          childId: childId,
          bucketType: to,
          type: app_transaction.TransactionType.transfer,
          amount: amount,
          multiplier: null,
          previousBalance: toBalance,
          newBalance: toNew,
          note: 'Transfer from ${from.name}',
          performedByUid: 'system',
          performedAt: now,
        ).toJson()
          ..remove('id'),
      );
    });
  }

  @override
  Future<void> withdrawFromBucket(String familyId, String childId, double amount) async {
    if (amount <= 0) {
      throw ArgumentError('Withdrawal amount must be greater than 0');
    }

    if (!await _connectivity.isOnline) {
      await _queue.enqueue(PendingOperation(
        id: _queue.generateId(),
        type: 'withdraw',
        payload: {
          'childId': childId,
          'familyId': familyId,
          'amount': amount,
        },
        createdAt: DateTime.now(),
        retryCount: 0,
      ));
      return;
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

    await _firestore.runTransaction((tx) async {
      final bucketSnapshot = await tx.get(bucketRef);
      final currentBalance = (bucketSnapshot.data()?['balance'] as num?)?.toDouble() ?? 0.0;

      if (currentBalance < amount) {
        throw ArgumentError('Insufficient balance in money bucket');
      }

      final newBalance = currentBalance - amount;
      final now = DateTime.now();

      final txn = app_transaction.Transaction(
        id: transactionRef.id,
        familyId: familyId,
        childId: childId,
        bucketType: BucketType.money,
        type: app_transaction.TransactionType.spend,
        amount: amount,
        multiplier: null,
        previousBalance: currentBalance,
        newBalance: newBalance,
        note: null,
        performedByUid: 'system',
        performedAt: now,
      );

      tx.update(bucketRef, {
        'balance': newBalance,
        'lastUpdatedAt': Timestamp.fromDate(now),
      });
      tx.set(transactionRef, txn.toJson()..remove('id'));
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

    if (!await _connectivity.isOnline) {
      await _queue.enqueue(PendingOperation(
        id: _queue.generateId(),
        type: 'multiplyBucket',
        payload: {
          'childId': childId,
          'familyId': familyId,
          'bucketType': bucketType.name,
          'multiplier': multiplier,
        },
        createdAt: DateTime.now(),
        retryCount: 0,
      ));
      return;
    }

    final bucketRef = _firestore
        .collection('families')
        .doc(familyId)
        .collection('children')
        .doc(childId)
        .collection('buckets')
        .doc(bucketType.name);

    final transactionRef =
        _firestore.collection('families').doc(familyId).collection('transactions').doc();

    await _firestore.runTransaction((tx) async {
      final bucketSnapshot = await tx.get(bucketRef);
      final currentBalance =
          (bucketSnapshot.data()?['balance'] as num?)?.toDouble() ?? 0.0;

      final newBalance = currentBalance * multiplier;
      final amount = newBalance - currentBalance;
      final now = DateTime.now();

      final txn = app_transaction.Transaction(
        id: transactionRef.id,
        familyId: familyId,
        childId: childId,
        bucketType: bucketType,
        type: app_transaction.TransactionType.investmentMultiplied,
        amount: amount,
        multiplier: multiplier,
        previousBalance: currentBalance,
        newBalance: newBalance,
        note: null,
        performedByUid: 'system',
        performedAt: now,
      );

      tx.update(bucketRef, {
        'balance': newBalance,
        'lastUpdatedAt': Timestamp.fromDate(now),
      });
      tx.set(transactionRef, txn.toJson()..remove('id'));
    });
  }
}
