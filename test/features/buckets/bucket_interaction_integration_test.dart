// Full-flow integration-style tests for the new bucket interaction features.
//
// These tests exercise complete user-facing scenarios end-to-end using
// FakeBucketRepository (in-memory, no Firestore emulator required).
//
// Upgrade path: once FirebaseBucketRepository implements donateBucket,
// transferBetweenBuckets, and withdrawFromBucket, replace FakeBucketRepository
// here with the real implementation backed by FakeFirebaseFirestore
// (same pattern as integration_test/bucket_operations_test.dart).

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

  group('Full charity flow', () {
    test('add to charity → donateBucket → charity balance is 0', () async {
      // 1. Parent distributes allowance with charity share
      await repo.distributeFunds(
        familyId: familyId,
        childId: childId,
        moneyAmount: 50.0,
        investmentAmount: 30.0,
        charityAmount: 20.0,
        performedByUid: 'parent-uid',
        note: 'weekly allowance',
      );

      expect(repo.getBalance(BucketType.charity), equals(20.0),
          reason: 'Charity seeded to 20 after distribution');

      // 2. Child taps Donate
      final donated = await repo.donateBucket(familyId, childId);

      expect(donated, equals(20.0),
          reason: 'Donated amount should match what was in charity');
      expect(repo.getBalance(BucketType.charity), equals(0.0),
          reason: 'Charity must be zero after donation');
    });

    test('donating twice in a row: second donation returns 0', () async {
      await repo.distributeFunds(
        familyId: familyId,
        childId: childId,
        moneyAmount: 0.0,
        investmentAmount: 0.0,
        charityAmount: 15.0,
        performedByUid: 'parent-uid',
      );

      await repo.donateBucket(familyId, childId);
      final secondDonation = await repo.donateBucket(familyId, childId);

      expect(secondDonation, equals(0.0));
      expect(repo.getBalance(BucketType.charity), equals(0.0));
    });
  });

  group('Full investment draw flow (Draw to Money)', () {
    test('add to investment → transfer to money → money increases', () async {
      // 1. Seed investment via distribution
      await repo.distributeFunds(
        familyId: familyId,
        childId: childId,
        moneyAmount: 10.0,
        investmentAmount: 100.0,
        charityAmount: 0.0,
        performedByUid: 'parent-uid',
      );

      expect(repo.getBalance(BucketType.investment), equals(100.0));

      // 2. Draw 40 from investment to money
      await repo.transferBetweenBuckets(
          familyId, childId, BucketType.investment, BucketType.money, 40.0);

      expect(repo.getBalance(BucketType.investment), equals(60.0),
          reason: '100 - 40 = 60');
      expect(repo.getBalance(BucketType.money), equals(50.0),
          reason: '10 + 40 = 50');
    });

    test('draw full investment to money: investment reaches 0', () async {
      repo.setBalance(BucketType.investment, 80.0);
      repo.setBalance(BucketType.money, 20.0);

      await repo.transferBetweenBuckets(
          familyId, childId, BucketType.investment, BucketType.money, 80.0);

      expect(repo.getBalance(BucketType.investment), equals(0.0));
      expect(repo.getBalance(BucketType.money), equals(100.0));
    });
  });

  group('Full withdrawal flow', () {
    test('add to money → withdraw → money decreases correctly', () async {
      // 1. Seed money
      await repo.addMoney(
        childId: childId,
        familyId: familyId,
        amount: 120.0,
        performedByUid: 'parent-uid',
      );

      expect(repo.getBalance(BucketType.money), equals(120.0));

      // 2. Child makes a purchase (withdraw)
      await repo.withdrawFromBucket(familyId, childId, 45.0);

      expect(repo.getBalance(BucketType.money), equals(75.0),
          reason: '120 - 45 = 75');
    });

    test('multiple withdrawals: balances accumulate correctly', () async {
      repo.setBalance(BucketType.money, 100.0);

      await repo.withdrawFromBucket(familyId, childId, 25.0);
      await repo.withdrawFromBucket(familyId, childId, 25.0);
      await repo.withdrawFromBucket(familyId, childId, 25.0);

      expect(repo.getBalance(BucketType.money), equals(25.0),
          reason: '100 - 25 - 25 - 25 = 25');
      expect(repo.transactions.length, equals(3));
    });
  });

  group('Full transfer chain: money → investment → draw back to money', () {
    test('balance is preserved across round-trip transfer', () async {
      repo.setBalance(BucketType.money, 200.0);

      // 1. Move 100 from money to investment
      await repo.transferBetweenBuckets(
          familyId, childId, BucketType.money, BucketType.investment, 100.0);

      expect(repo.getBalance(BucketType.money), equals(100.0));
      expect(repo.getBalance(BucketType.investment), equals(100.0));

      // 2. Draw 100 back from investment to money
      await repo.transferBetweenBuckets(
          familyId, childId, BucketType.investment, BucketType.money, 100.0);

      expect(repo.getBalance(BucketType.money), equals(200.0),
          reason: 'Round-trip should restore original money balance');
      expect(repo.getBalance(BucketType.investment), equals(0.0));
    });

    test('four transactions recorded for two-transfer chain', () async {
      repo.setBalance(BucketType.money, 100.0);

      await repo.transferBetweenBuckets(
          familyId, childId, BucketType.money, BucketType.investment, 50.0);
      await repo.transferBetweenBuckets(
          familyId, childId, BucketType.investment, BucketType.money, 50.0);

      expect(repo.transactions.length, equals(4),
          reason: '2 transfers × 2 records each = 4 transaction entries');
    });
  });

  group('Combined flow: distribute → transfer → donate', () {
    test('full multi-feature scenario preserves total balance', () async {
      // 1. Distribute 100 allowance: 50 money, 30 investment, 20 charity
      await repo.distributeFunds(
        familyId: familyId,
        childId: childId,
        moneyAmount: 50.0,
        investmentAmount: 30.0,
        charityAmount: 20.0,
        performedByUid: 'parent-uid',
      );

      // 2. Transfer 10 from money to investment
      await repo.transferBetweenBuckets(
          familyId, childId, BucketType.money, BucketType.investment, 10.0);

      // 3. Donate charity
      await repo.donateBucket(familyId, childId);

      final totalRemaining = repo.getBalance(BucketType.money) +
          repo.getBalance(BucketType.investment) +
          repo.getBalance(BucketType.charity);

      expect(repo.getBalance(BucketType.money), equals(40.0));
      expect(repo.getBalance(BucketType.investment), equals(40.0));
      expect(repo.getBalance(BucketType.charity), equals(0.0));
      expect(totalRemaining, equals(80.0),
          reason: '100 distributed - 20 donated = 80 remaining');
    });
  });
}
