// Integration tests for bucket operations (Sprint 5D).
//
// Prerequisites:
//   - All tests use FakeFirebaseFirestore + FakeOnlineConnectivity + InMemoryOfflineQueue.
//   - No Firebase emulator required.
//
// What is tested:
//   - addMoney, removeMoney, multiplyInvestment, donateCharity, distributeFunds
//   - Each test verifies the Firestore balance document is correctly updated.
//   - Transaction log entries are also checked where relevant.

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kids_finance/features/buckets/data/firebase_bucket_repository.dart';
import 'helpers.dart';

void main() {
  const familyId = 'family-test';
  const childId = 'child-test';
  const parentUid = 'parent-uid';

  late FakeFirebaseFirestore fakeFirestore;
  late FakeOnlineConnectivity connectivity;
  late InMemoryOfflineQueue queue;
  late FirebaseBucketRepository repository;

  setUp(() async {
    fakeFirestore = FakeFirebaseFirestore();
    connectivity = FakeOnlineConnectivity();
    queue = InMemoryOfflineQueue();

    repository = FirebaseBucketRepository(
      firestore: fakeFirestore,
      connectivity: connectivity,
      queue: queue,
    );

    // All bucket operations call transaction.update(), which requires the
    // document to already exist. Seed starting balances before each test.
    await seedBuckets(
      fakeFirestore,
      familyId: familyId,
      childId: childId,
      money: 100.0,
      investment: 200.0,
      charity: 50.0,
    );
  });

  group('Bucket Operations — Money bucket', () {
    test('addMoney: adds amount to existing balance', () async {
      await repository.addMoney(
        childId: childId,
        familyId: familyId,
        amount: 25.0,
        performedByUid: parentUid,
        note: 'weekly allowance',
      );

      final balance = await readBalance(fakeFirestore,
          familyId: familyId, childId: childId, bucketType: 'money');
      expect(balance, equals(125.0),
          reason: '100 + 25 = 125');
    });

    test('addMoney: rejects zero or negative amount (ArgumentError)', () async {
      await expectLater(
        () => repository.addMoney(
          childId: childId,
          familyId: familyId,
          amount: 0.0,
          performedByUid: parentUid,
        ),
        throwsA(isA<ArgumentError>()),
        reason: 'Zero amount should be rejected',
      );

      await expectLater(
        () => repository.addMoney(
          childId: childId,
          familyId: familyId,
          amount: -5.0,
          performedByUid: parentUid,
        ),
        throwsA(isA<ArgumentError>()),
        reason: 'Negative amount should be rejected',
      );
    });

    test('removeMoney (spend): deducts amount from Money balance', () async {
      await repository.removeMoney(
        childId: childId,
        familyId: familyId,
        amount: 30.0,
        performedByUid: parentUid,
        note: 'bought a book',
      );

      final balance = await readBalance(fakeFirestore,
          familyId: familyId, childId: childId, bucketType: 'money');
      expect(balance, equals(70.0), reason: '100 - 30 = 70');
    });

    test('removeMoney: rejects amount exceeding balance (ArgumentError)',
        () async {
      await expectLater(
        () => repository.removeMoney(
          childId: childId,
          familyId: familyId,
          amount: 200.0, // more than 100.0 balance
          performedByUid: parentUid,
        ),
        throwsA(isA<ArgumentError>()),
        reason: 'Cannot spend more than the balance',
      );
    });
  });

  group('Bucket Operations — Investment bucket', () {
    test('multiplyInvestment: multiplies balance by given factor', () async {
      await repository.multiplyInvestment(
        childId: childId,
        familyId: familyId,
        multiplier: 2.0,
        performedByUid: parentUid,
        note: 'great year!',
      );

      final balance = await readBalance(fakeFirestore,
          familyId: familyId, childId: childId, bucketType: 'investment');
      expect(balance, equals(400.0), reason: '200 × 2 = 400');
    });

    test('multiplyInvestment: rejects zero multiplier (ArgumentError)',
        () async {
      await expectLater(
        () => repository.multiplyInvestment(
          childId: childId,
          familyId: familyId,
          multiplier: 0.0,
          performedByUid: parentUid,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('multiplyInvestment: rejects negative multiplier (ArgumentError)',
        () async {
      await expectLater(
        () => repository.multiplyInvestment(
          childId: childId,
          familyId: familyId,
          multiplier: -1.5,
          performedByUid: parentUid,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });
  });

  group('Bucket Operations — Charity bucket', () {
    test('donateCharity: resets Charity balance to zero', () async {
      await repository.donateCharity(
        childId: childId,
        familyId: familyId,
        performedByUid: parentUid,
        note: 'donated to school',
      );

      final balance = await readBalance(fakeFirestore,
          familyId: familyId, childId: childId, bucketType: 'charity');
      expect(balance, equals(0.0),
          reason: 'Charity bucket should be reset to zero after donation');
    });
  });

  group('Bucket Operations — Distribute (allowance split)', () {
    setUp(() async {
      // Start with clean zero balances for distribution tests
      await seedBuckets(
        fakeFirestore,
        familyId: familyId,
        childId: childId,
        money: 0.0,
        investment: 0.0,
        charity: 0.0,
      );
    });

    test('distributeFunds: splits allowance across all 3 buckets', () async {
      await repository.distributeFunds(
        familyId: familyId,
        childId: childId,
        moneyAmount: 50.0,
        investmentAmount: 30.0,
        charityAmount: 20.0,
        performedByUid: parentUid,
        note: 'weekly allowance',
      );

      final money = await readBalance(fakeFirestore,
          familyId: familyId, childId: childId, bucketType: 'money');
      final investment = await readBalance(fakeFirestore,
          familyId: familyId, childId: childId, bucketType: 'investment');
      final charity = await readBalance(fakeFirestore,
          familyId: familyId, childId: childId, bucketType: 'charity');

      expect(money, equals(50.0));
      expect(investment, equals(30.0));
      expect(charity, equals(20.0));
    });

    test('distributeFunds: money-only split works (others stay at zero)',
        () async {
      await repository.distributeFunds(
        familyId: familyId,
        childId: childId,
        moneyAmount: 100.0,
        investmentAmount: 0.0,
        charityAmount: 0.0,
        performedByUid: parentUid,
      );

      final money = await readBalance(fakeFirestore,
          familyId: familyId, childId: childId, bucketType: 'money');
      expect(money, equals(100.0));
    });

    test('distributeFunds: all-zero split is rejected (ArgumentError)',
        () async {
      await expectLater(
        () => repository.distributeFunds(
          familyId: familyId,
          childId: childId,
          moneyAmount: 0.0,
          investmentAmount: 0.0,
          charityAmount: 0.0,
          performedByUid: parentUid,
        ),
        throwsA(isA<ArgumentError>()),
        reason: 'Total must be greater than zero',
      );
    });
  });

  group('Bucket Operations — Transaction log', () {
    test('addMoney creates a transaction log entry in Firestore', () async {
      await repository.addMoney(
        childId: childId,
        familyId: familyId,
        amount: 10.0,
        performedByUid: parentUid,
        note: 'bonus',
      );

      final txnSnapshot = await fakeFirestore
          .collection('families')
          .doc(familyId)
          .collection('transactions')
          .get();

      expect(txnSnapshot.docs, isNotEmpty,
          reason: 'A transaction log entry must be created');
      final txn = txnSnapshot.docs.first.data();
      expect(txn['childId'], equals(childId));
      expect(txn['type'], equals('moneyAdded'));
      expect((txn['amount'] as num).toDouble(), equals(10.0));
    });
  });
}
