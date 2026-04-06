import 'package:flutter_test/flutter_test.dart';
import 'package:kids_finance/features/buckets/data/firebase_bucket_repository.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';

void main() {
  group('Bucket Repository Critical Bug Tests', () {
    late FirebaseBucketRepository repository;
    late FakeFirebaseFirestore fakeFirestore;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      repository = FirebaseBucketRepository(firestore: fakeFirestore);

      // Setup test data
      fakeFirestore
          .collection('families')
          .doc('family-1')
          .collection('children')
          .doc('child-1')
          .collection('buckets')
          .doc('investment')
          .set({
        'childId': 'child-1',
        'familyId': 'family-1',
        'type': 'investment',
        'balance': 100.0,
        'lastUpdatedAt': DateTime.now().toIso8601String(),
      });
    });

    test('BUG-003: multiplyInvestment rejects zero multiplier', () async {
      // Test multiplying investment by 0
      expect(
        () => repository.multiplyInvestment(
          childId: 'child-1',
          familyId: 'family-1',
          multiplier: 0.0,
          performedByUid: 'parent-1',
        ),
        throwsA(isA<ArgumentError>()),
        reason: 'Multiplier of 0 should throw ArgumentError',
      );
    });

    test('BUG-003: multiplyInvestment rejects negative multiplier', () async {
      // Test multiplying investment by negative number
      expect(
        () => repository.multiplyInvestment(
          childId: 'child-1',
          familyId: 'family-1',
          multiplier: -1.5,
          performedByUid: 'parent-1',
        ),
        throwsA(isA<ArgumentError>()),
        reason: 'Negative multiplier should throw ArgumentError',
      );
    });

    test('BUG-014: multiplying by 0.1 reduces investment significantly',
        () async {
      // This test documents the risk of accidental destructive operations
      // Multiplying by 0.1 when user meant to type 10 could lose 90% of investment

      await repository.multiplyInvestment(
        childId: 'child-1',
        familyId: 'family-1',
        multiplier: 0.1,
        performedByUid: 'parent-1',
      );

      final bucketDoc = await fakeFirestore
          .collection('families')
          .doc('family-1')
          .collection('children')
          .doc('child-1')
          .collection('buckets')
          .doc('investment')
          .get();

      final newBalance = (bucketDoc.data()?['balance'] as num?)?.toDouble();

      expect(
        newBalance,
        10.0,
        reason:
            'Balance should be reduced to 10.0 (from 100.0) - DESTRUCTIVE operation',
      );

      // This test passes, but highlights the need for confirmation dialog
      // when multiplier < 1.0 (see BUG-014 suggested fix)
    });

    test('BUG-011: addMoney rejects negative amount', () async {
      // Setup money bucket
      await fakeFirestore
          .collection('families')
          .doc('family-1')
          .collection('children')
          .doc('child-1')
          .collection('buckets')
          .doc('money')
          .set({
        'childId': 'child-1',
        'familyId': 'family-1',
        'type': 'money',
        'balance': 50.0,
        'lastUpdatedAt': DateTime.now().toIso8601String(),
      });

      expect(
        () => repository.addMoney(
          childId: 'child-1',
          familyId: 'family-1',
          amount: -10.0,
          performedByUid: 'parent-1',
        ),
        throwsA(isA<ArgumentError>()),
        reason: 'Negative amount should throw ArgumentError',
      );
    });

    test('BUG-013: removeMoney allows removing exact balance', () async {
      // Setup money bucket with $50
      await fakeFirestore
          .collection('families')
          .doc('family-1')
          .collection('children')
          .doc('child-1')
          .collection('buckets')
          .doc('money')
          .set({
        'childId': 'child-1',
        'familyId': 'family-1',
        'type': 'money',
        'balance': 50.0,
        'lastUpdatedAt': DateTime.now().toIso8601String(),
      });

      // Should allow removing exactly $50 (setting balance to 0)
      await repository.removeMoney(
        childId: 'child-1',
        familyId: 'family-1',
        amount: 50.0,
        performedByUid: 'parent-1',
      );

      final bucketDoc = await fakeFirestore
          .collection('families')
          .doc('family-1')
          .collection('children')
          .doc('child-1')
          .collection('buckets')
          .doc('money')
          .get();

      final newBalance = (bucketDoc.data()?['balance'] as num?)?.toDouble();

      expect(newBalance, 0.0, reason: 'Balance should be 0 after removing all');
    });

    test('BUG-013: removeMoney rejects amount greater than balance', () async {
      // Setup money bucket with $50
      await fakeFirestore
          .collection('families')
          .doc('family-1')
          .collection('children')
          .doc('child-1')
          .collection('buckets')
          .doc('money')
          .set({
        'childId': 'child-1',
        'familyId': 'family-1',
        'type': 'money',
        'balance': 50.0,
        'lastUpdatedAt': DateTime.now().toIso8601String(),
      });

      // Try to remove $50.01 when balance is only $50
      expect(
        () => repository.removeMoney(
          childId: 'child-1',
          familyId: 'family-1',
          amount: 50.01,
          performedByUid: 'parent-1',
        ),
        throwsA(isA<ArgumentError>()),
        reason: 'Should reject removing more than current balance',
      );
    });
  });
}
