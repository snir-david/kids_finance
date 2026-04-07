// Tests for BucketRepository.donateBucket().
//
// Uses FakeBucketRepository (no code generation required).
// The new donateBucket method:
//   - Drains the entire charity balance
//   - Returns the donated amount
//   - Records a transaction with type=donate, bucketType=charity
//   - Leaves balance at exactly 0

import 'package:flutter_test/flutter_test.dart';
import 'package:kids_finance/features/buckets/domain/bucket.dart';

import 'fake_bucket_repository.dart';

void main() {
  const familyId = 'family-1';
  const childId = 'child-1';

  late FakeBucketRepository repo;

  setUp(() {
    repo = FakeBucketRepository();
  });

  group('donateBucket — happy paths', () {
    test('returns donated amount when charity balance > 0', () async {
      repo.setBalance(BucketType.charity, 75.0);

      final donated = await repo.donateBucket(familyId, childId);

      expect(donated, equals(75.0),
          reason: 'Should return the full pre-donation balance');
    });

    test('charity balance is 0 after donation', () async {
      repo.setBalance(BucketType.charity, 75.0);

      await repo.donateBucket(familyId, childId);

      expect(repo.getBalance(BucketType.charity), equals(0.0),
          reason: 'Charity bucket must be reset to zero');
    });

    test('other buckets are unaffected by donation', () async {
      repo.setBalance(BucketType.money, 100.0);
      repo.setBalance(BucketType.investment, 200.0);
      repo.setBalance(BucketType.charity, 50.0);

      await repo.donateBucket(familyId, childId);

      expect(repo.getBalance(BucketType.money), equals(100.0));
      expect(repo.getBalance(BucketType.investment), equals(200.0));
    });
  });

  group('donateBucket — transaction record', () {
    test('records one transaction with type=donate and bucketType=charity', () async {
      repo.setBalance(BucketType.charity, 40.0);

      await repo.donateBucket(familyId, childId);

      expect(repo.transactions, hasLength(1));
      final txn = repo.transactions.first;
      expect(txn['type'], equals('donate'));
      expect(txn['bucketType'], equals('charity'));
    });

    test('transaction amount equals the donated balance', () async {
      repo.setBalance(BucketType.charity, 40.0);

      await repo.donateBucket(familyId, childId);

      final txn = repo.transactions.first;
      expect((txn['amount'] as num).toDouble(), equals(40.0));
    });
  });

  group('donateBucket — zero balance edge case', () {
    test('donating when charity = 0 returns 0 (no error)', () async {
      // Charity starts at 0 (default)
      final donated = await repo.donateBucket(familyId, childId);

      expect(donated, equals(0.0),
          reason: 'Donating zero is valid — nothing to donate');
      expect(repo.getBalance(BucketType.charity), equals(0.0));
    });

    test('donating zero records a transaction (idempotent call is safe)', () async {
      await repo.donateBucket(familyId, childId);

      // Transaction is still logged even for a zero-amount donate
      expect(repo.transactions, hasLength(1));
      expect(repo.transactions.first['amount'], equals(0.0));
    });
  });

  group('donateBucket — exact boundary', () {
    test('donate exactly 0.01 (minimum meaningful amount)', () async {
      repo.setBalance(BucketType.charity, 0.01);

      final donated = await repo.donateBucket(familyId, childId);

      expect(donated, equals(0.01));
      expect(repo.getBalance(BucketType.charity), equals(0.0));
    });

    test('donate large balance (1 000 000) returns correct amount', () async {
      repo.setBalance(BucketType.charity, 1000000.0);

      final donated = await repo.donateBucket(familyId, childId);

      expect(donated, equals(1000000.0));
      expect(repo.getBalance(BucketType.charity), equals(0.0));
    });
  });
}
