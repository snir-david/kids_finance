// Tests for BucketRepository.transferBetweenBuckets().
//
// Uses FakeBucketRepository (no code generation required).
// The method:
//   - Moves [amount] atomically from one bucket to another
//   - Validates amount > 0
//   - Validates source bucket has sufficient balance
//   - Rejects same-bucket transfers
//   - Records two transfer transactions: debit on [from], credit on [to]

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

  group('transferBetweenBuckets — valid transfers', () {
    test('investment → money: investment decreases, money increases', () async {
      repo.setBalance(BucketType.investment, 150.0);
      repo.setBalance(BucketType.money, 50.0);

      await repo.transferBetweenBuckets(
          familyId, childId, BucketType.investment, BucketType.money, 100.0);

      expect(repo.getBalance(BucketType.investment), equals(50.0),
          reason: '150 - 100 = 50');
      expect(repo.getBalance(BucketType.money), equals(150.0),
          reason: '50 + 100 = 150');
    });

    test('money → investment: correct bucket adjustments', () async {
      repo.setBalance(BucketType.money, 200.0);
      repo.setBalance(BucketType.investment, 0.0);

      await repo.transferBetweenBuckets(
          familyId, childId, BucketType.money, BucketType.investment, 80.0);

      expect(repo.getBalance(BucketType.money), equals(120.0),
          reason: '200 - 80 = 120');
      expect(repo.getBalance(BucketType.investment), equals(80.0),
          reason: '0 + 80 = 80');
    });

    test('money → charity: correct bucket adjustments', () async {
      repo.setBalance(BucketType.money, 100.0);
      repo.setBalance(BucketType.charity, 10.0);

      await repo.transferBetweenBuckets(
          familyId, childId, BucketType.money, BucketType.charity, 30.0);

      expect(repo.getBalance(BucketType.money), equals(70.0));
      expect(repo.getBalance(BucketType.charity), equals(40.0));
    });

    test('charity → money: correct bucket adjustments', () async {
      repo.setBalance(BucketType.charity, 60.0);
      repo.setBalance(BucketType.money, 20.0);

      await repo.transferBetweenBuckets(
          familyId, childId, BucketType.charity, BucketType.money, 60.0);

      expect(repo.getBalance(BucketType.charity), equals(0.0));
      expect(repo.getBalance(BucketType.money), equals(80.0));
    });

    test('amount exactly equal to source balance succeeds (boundary)', () async {
      repo.setBalance(BucketType.investment, 50.0);

      await repo.transferBetweenBuckets(
          familyId, childId, BucketType.investment, BucketType.money, 50.0);

      expect(repo.getBalance(BucketType.investment), equals(0.0),
          reason: 'Exact balance transfer should succeed');
      expect(repo.getBalance(BucketType.money), equals(50.0));
    });

    test('third bucket is unaffected during a two-bucket transfer', () async {
      repo.setBalance(BucketType.money, 100.0);
      repo.setBalance(BucketType.investment, 50.0);
      repo.setBalance(BucketType.charity, 25.0);

      await repo.transferBetweenBuckets(
          familyId, childId, BucketType.money, BucketType.investment, 30.0);

      expect(repo.getBalance(BucketType.charity), equals(25.0),
          reason: 'Charity should be unaffected');
    });
  });

  group('transferBetweenBuckets — transaction records', () {
    test('records exactly two transactions: debit on [from] and credit on [to]',
        () async {
      repo.setBalance(BucketType.investment, 100.0);

      await repo.transferBetweenBuckets(
          familyId, childId, BucketType.investment, BucketType.money, 40.0);

      expect(repo.transactions, hasLength(2),
          reason: 'Two records: one debit, one credit');
    });

    test('debit transaction has negative amount on [from] bucket', () async {
      repo.setBalance(BucketType.investment, 100.0);

      await repo.transferBetweenBuckets(
          familyId, childId, BucketType.investment, BucketType.money, 40.0);

      final debit = repo.transactions.firstWhere(
          (t) => t['bucketType'] == 'investment');
      expect((debit['amount'] as num).toDouble(), equals(-40.0));
    });

    test('credit transaction has positive amount on [to] bucket', () async {
      repo.setBalance(BucketType.investment, 100.0);

      await repo.transferBetweenBuckets(
          familyId, childId, BucketType.investment, BucketType.money, 40.0);

      final credit = repo.transactions.firstWhere(
          (t) => t['bucketType'] == 'money');
      expect((credit['amount'] as num).toDouble(), equals(40.0));
    });
  });

  group('transferBetweenBuckets — validation errors', () {
    test('amount > source balance → throws ArgumentError (insufficient funds)',
        () async {
      repo.setBalance(BucketType.investment, 30.0);

      await expectLater(
        () => repo.transferBetweenBuckets(
            familyId, childId, BucketType.investment, BucketType.money, 100.0),
        throwsA(isA<ArgumentError>()),
        reason: 'Cannot transfer more than available balance',
      );
    });

    test('balance is unchanged after failed transfer (insufficient funds)',
        () async {
      repo.setBalance(BucketType.investment, 30.0);
      repo.setBalance(BucketType.money, 50.0);

      try {
        await repo.transferBetweenBuckets(
            familyId, childId, BucketType.investment, BucketType.money, 100.0);
      } catch (_) {}

      expect(repo.getBalance(BucketType.investment), equals(30.0),
          reason: 'Source balance must be unchanged on failure');
      expect(repo.getBalance(BucketType.money), equals(50.0),
          reason: 'Destination balance must be unchanged on failure');
    });

    test('amount = 0 → throws ArgumentError', () async {
      repo.setBalance(BucketType.investment, 100.0);

      await expectLater(
        () => repo.transferBetweenBuckets(
            familyId, childId, BucketType.investment, BucketType.money, 0.0),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('negative amount → throws ArgumentError', () async {
      repo.setBalance(BucketType.investment, 100.0);

      await expectLater(
        () => repo.transferBetweenBuckets(
            familyId, childId, BucketType.investment, BucketType.money, -10.0),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('transfer from same bucket to same bucket → throws ArgumentError',
        () async {
      repo.setBalance(BucketType.money, 100.0);

      await expectLater(
        () => repo.transferBetweenBuckets(
            familyId, childId, BucketType.money, BucketType.money, 50.0),
        throwsA(isA<ArgumentError>()),
        reason: 'Source and destination cannot be the same bucket',
      );
    });

    test('no transactions recorded when transfer fails', () async {
      repo.setBalance(BucketType.investment, 30.0);

      try {
        await repo.transferBetweenBuckets(
            familyId, childId, BucketType.investment, BucketType.money, 100.0);
      } catch (_) {}

      expect(repo.transactions, isEmpty,
          reason: 'Failed transfer must not log any transaction');
    });
  });
}
