import 'package:flutter_test/flutter_test.dart';
import 'package:kids_finance/features/transactions/domain/transaction.dart';
import 'package:kids_finance/features/buckets/domain/bucket.dart';

void main() {
  group('TransactionType', () {
    test('has exactly 5 values', () {
      expect(TransactionType.values.length, 5);
    });
    
    test('contains all expected types', () {
      expect(TransactionType.values, contains(TransactionType.moneySet));
      expect(TransactionType.values, contains(TransactionType.investmentMultiplied));
      expect(TransactionType.values, contains(TransactionType.charityDonated));
      expect(TransactionType.values, contains(TransactionType.moneyAdded));
      expect(TransactionType.values, contains(TransactionType.moneyRemoved));
    });
    
    test('toJson returns string name', () {
      expect(TransactionType.moneySet.toJson(), 'moneySet');
      expect(TransactionType.investmentMultiplied.toJson(), 'investmentMultiplied');
      expect(TransactionType.charityDonated.toJson(), 'charityDonated');
      expect(TransactionType.moneyAdded.toJson(), 'moneyAdded');
      expect(TransactionType.moneyRemoved.toJson(), 'moneyRemoved');
    });
    
    test('fromJson parses correctly', () {
      expect(TransactionType.fromJson('moneySet'), TransactionType.moneySet);
      expect(TransactionType.fromJson('investmentMultiplied'), TransactionType.investmentMultiplied);
      expect(TransactionType.fromJson('charityDonated'), TransactionType.charityDonated);
      expect(TransactionType.fromJson('moneyAdded'), TransactionType.moneyAdded);
      expect(TransactionType.fromJson('moneyRemoved'), TransactionType.moneyRemoved);
    });
    
    test('fromJson returns moneyAdded for invalid value', () {
      expect(TransactionType.fromJson('invalid'), TransactionType.moneyAdded);
    });
  });
  
  group('Transaction', () {
    late Transaction transaction;
    
    setUp(() {
      transaction = Transaction(
        id: 'txn1',
        familyId: 'fam1',
        childId: 'child1',
        bucketType: BucketType.money,
        type: TransactionType.moneyAdded,
        amount: 50.0,
        multiplier: null,
        previousBalance: 100.0,
        newBalance: 150.0,
        note: 'Weekly allowance',
        performedByUid: 'parent1',
        performedAt: DateTime(2024, 1, 1),
      );
    });
    
    test('creates with required fields', () {
      expect(transaction.id, 'txn1');
      expect(transaction.familyId, 'fam1');
      expect(transaction.childId, 'child1');
      expect(transaction.bucketType, BucketType.money);
      expect(transaction.type, TransactionType.moneyAdded);
      expect(transaction.amount, 50.0);
      expect(transaction.previousBalance, 100.0);
      expect(transaction.newBalance, 150.0);
    });
    
    test('multiplier is nullable', () {
      expect(transaction.multiplier, isNull);
      
      final withMultiplier = transaction.copyWith(multiplier: 1.5);
      expect(withMultiplier.multiplier, 1.5);
    });
    
    test('note is nullable', () {
      final withoutNote = Transaction(
        id: 'txn2',
        familyId: 'fam1',
        childId: 'child1',
        bucketType: BucketType.charity,
        type: TransactionType.charityDonated,
        amount: 10.0,
        multiplier: null,
        previousBalance: 50.0,
        newBalance: 40.0,
        note: null,
        performedByUid: 'parent1',
        performedAt: DateTime(2024, 1, 1),
      );
      expect(withoutNote.note, isNull);
    });
    
    test('copyWith replaces fields', () {
      final updated = transaction.copyWith(amount: 75.0);
      expect(updated.amount, 75.0);
      expect(updated.id, transaction.id); // unchanged
    });
    
    test('investment transaction with multiplier', () {
      final investment = Transaction(
        id: 'txn3',
        familyId: 'fam1',
        childId: 'child1',
        bucketType: BucketType.investment,
        type: TransactionType.investmentMultiplied,
        amount: 0.0,
        multiplier: 1.05,
        previousBalance: 100.0,
        newBalance: 105.0,
        note: 'Monthly gain',
        performedByUid: 'system',
        performedAt: DateTime(2024, 1, 1),
      );
      
      expect(investment.type, TransactionType.investmentMultiplied);
      expect(investment.multiplier, 1.05);
      expect(investment.bucketType, BucketType.investment);
    });
    
    test('equality works', () {
      final same = Transaction(
        id: 'txn1',
        familyId: 'fam1',
        childId: 'child1',
        bucketType: BucketType.money,
        type: TransactionType.moneyAdded,
        amount: 50.0,
        multiplier: null,
        previousBalance: 100.0,
        newBalance: 150.0,
        note: 'Weekly allowance',
        performedByUid: 'parent1',
        performedAt: DateTime(2024, 1, 1),
      );
      expect(transaction, equals(same));
    });
    
    test('inequality works with different amount', () {
      final different = transaction.copyWith(amount: 60.0);
      expect(transaction, isNot(equals(different)));
    });
    
    test('props includes all fields', () {
      expect(transaction.props, [
        'txn1',
        'fam1',
        'child1',
        BucketType.money,
        TransactionType.moneyAdded,
        50.0,
        null, // multiplier
        100.0,
        150.0,
        'Weekly allowance',
        'parent1',
        DateTime(2024, 1, 1),
      ]);
    });
  });
}
