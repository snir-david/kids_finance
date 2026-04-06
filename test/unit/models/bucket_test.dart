import 'package:flutter_test/flutter_test.dart';
import 'package:kids_finance/features/buckets/domain/bucket.dart';

void main() {
  group('BucketType', () {
    test('has exactly 3 values', () {
      expect(BucketType.values.length, 3);
    });
    
    test('contains money, investment, and charity', () {
      expect(BucketType.values, contains(BucketType.money));
      expect(BucketType.values, contains(BucketType.investment));
      expect(BucketType.values, contains(BucketType.charity));
    });
    
    test('toJson returns string name', () {
      expect(BucketType.money.toJson(), 'money');
      expect(BucketType.investment.toJson(), 'investment');
      expect(BucketType.charity.toJson(), 'charity');
    });
    
    test('fromJson parses correctly', () {
      expect(BucketType.fromJson('money'), BucketType.money);
      expect(BucketType.fromJson('investment'), BucketType.investment);
      expect(BucketType.fromJson('charity'), BucketType.charity);
    });
    
    test('fromJson returns money for invalid value', () {
      expect(BucketType.fromJson('invalid'), BucketType.money);
    });
  });
  
  group('Bucket', () {
    late Bucket bucket;
    
    setUp(() {
      bucket = Bucket(
        id: 'bucket1',
        childId: 'child1',
        familyId: 'fam1',
        type: BucketType.money,
        balance: 100.0,
        lastUpdatedAt: DateTime(2024, 1, 1),
      );
    });
    
    test('creates with required fields', () {
      expect(bucket.id, 'bucket1');
      expect(bucket.childId, 'child1');
      expect(bucket.familyId, 'fam1');
      expect(bucket.type, BucketType.money);
      expect(bucket.balance, 100.0);
    });
    
    test('balance can be non-negative', () {
      expect(bucket.balance, greaterThanOrEqualTo(0));
      
      final zeroBucket = bucket.copyWith(balance: 0.0);
      expect(zeroBucket.balance, 0.0);
    });
    
    test('copyWith replaces fields', () {
      final updated = bucket.copyWith(balance: 150.5);
      expect(updated.balance, 150.5);
      expect(updated.id, bucket.id); // unchanged
      expect(updated.type, bucket.type); // unchanged
    });
    
    test('copyWith can change type', () {
      final investmentBucket = bucket.copyWith(type: BucketType.investment);
      expect(investmentBucket.type, BucketType.investment);
      expect(investmentBucket.balance, bucket.balance); // unchanged
    });
    
    test('equality works', () {
      final same = Bucket(
        id: 'bucket1',
        childId: 'child1',
        familyId: 'fam1',
        type: BucketType.money,
        balance: 100.0,
        lastUpdatedAt: DateTime(2024, 1, 1),
      );
      expect(bucket, equals(same));
    });
    
    test('inequality works with different balance', () {
      final different = bucket.copyWith(balance: 200.0);
      expect(bucket, isNot(equals(different)));
    });
    
    test('props includes all fields', () {
      expect(bucket.props, [
        'bucket1',
        'child1',
        'fam1',
        BucketType.money,
        100.0,
        DateTime(2024, 1, 1),
      ]);
    });
  });
}
