// Tests for BucketRepository.withdrawFromBucket().
//
// Uses FakeBucketRepository (no code generation required).
// The method:
//   - Subtracts [amount] from the Money bucket (purchase simulation)
//   - Validates amount > 0
//   - Validates Money bucket has sufficient balance
//   - Records a transaction with type=spend, bucketType=money

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

  group('withdrawFromBucket — happy paths', () {
    test('money balance decreases by withdrawn amount', () async {
      repo.setBalance(BucketType.money, 100.0);

      await repo.withdrawFromBucket(familyId, childId, 35.0);

      expect(repo.getBalance(BucketType.money), equals(65.0),
          reason: '100 - 35 = 65');
    });

    test('investment and charity balances are unaffected', () async {
      repo.setBalance(BucketType.money, 100.0);
      repo.setBalance(BucketType.investment, 200.0);
      repo.setBalance(BucketType.charity, 50.0);

      await repo.withdrawFromBucket(familyId, childId, 35.0);

      expect(repo.getBalance(BucketType.investment), equals(200.0));
      expect(repo.getBalance(BucketType.charity), equals(50.0));
    });

    test('withdrawing exact balance leaves money at 0 (boundary)', () async {
      repo.setBalance(BucketType.money, 50.0);

      await repo.withdrawFromBucket(familyId, childId, 50.0);

      expect(repo.getBalance(BucketType.money), equals(0.0),
          reason: 'Spending exactly what you have is valid');
    });

    test('withdraw minimum meaningful amount (0.01)', () async {
      repo.setBalance(BucketType.money, 1.0);

      await repo.withdrawFromBucket(familyId, childId, 0.01);

      expect(repo.getBalance(BucketType.money), closeTo(0.99, 1e-9));
    });
  });

  group('withdrawFromBucket — transaction record', () {
    test('records one transaction with type=spend and bucketType=money', () async {
      repo.setBalance(BucketType.money, 100.0);

      await repo.withdrawFromBucket(familyId, childId, 20.0);

      expect(repo.transactions, hasLength(1));
      final txn = repo.transactions.first;
      expect(txn['type'], equals('spend'));
      expect(txn['bucketType'], equals('money'));
    });

    test('transaction amount equals the withdrawn amount', () async {
      repo.setBalance(BucketType.money, 100.0);

      await repo.withdrawFromBucket(familyId, childId, 20.0);

      final txn = repo.transactions.first;
      expect((txn['amount'] as num).toDouble(), equals(20.0));
    });
  });

  group('withdrawFromBucket — validation errors', () {
    test('amount > balance → throws ArgumentError (insufficient funds)',
        () async {
      repo.setBalance(BucketType.money, 30.0);

      await expectLater(
        () => repo.withdrawFromBucket(familyId, childId, 50.0),
        throwsA(isA<ArgumentError>()),
        reason: 'Cannot spend more than the Money balance',
      );
    });

    test('money balance is unchanged after failed withdrawal', () async {
      repo.setBalance(BucketType.money, 30.0);

      try {
        await repo.withdrawFromBucket(familyId, childId, 50.0);
      } catch (_) {}

      expect(repo.getBalance(BucketType.money), equals(30.0),
          reason: 'Balance must remain unchanged when withdrawal fails');
    });

    test('amount = 0 → throws ArgumentError', () async {
      repo.setBalance(BucketType.money, 100.0);

      await expectLater(
        () => repo.withdrawFromBucket(familyId, childId, 0.0),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('negative amount → throws ArgumentError', () async {
      repo.setBalance(BucketType.money, 100.0);

      await expectLater(
        () => repo.withdrawFromBucket(familyId, childId, -15.0),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('no transaction recorded when withdrawal fails', () async {
      repo.setBalance(BucketType.money, 30.0);

      try {
        await repo.withdrawFromBucket(familyId, childId, 50.0);
      } catch (_) {}

      expect(repo.transactions, isEmpty,
          reason: 'Failed withdrawal must not log a transaction');
    });

    test('withdraw from empty (0-balance) money bucket → throws ArgumentError',
        () async {
      // Money starts at 0 by default
      await expectLater(
        () => repo.withdrawFromBucket(familyId, childId, 1.0),
        throwsA(isA<ArgumentError>()),
      );
    });
  });
}
