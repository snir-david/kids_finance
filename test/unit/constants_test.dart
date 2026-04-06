import 'package:flutter_test/flutter_test.dart';
import 'package:kids_finance/core/constants/app_constants.dart';

void main() {
  group('AppConstants', () {
    test('PIN_LENGTH is 4', () {
      expect(AppConstants.pinLength, 4);
    });
    
    test('PIN_MAX_ATTEMPTS is 5', () {
      expect(AppConstants.pinMaxAttempts, 5);
    });
    
    test('PIN_LOCKOUT_MINUTES is 15', () {
      expect(AppConstants.pinLockoutMinutes, 15);
    });
    
    test('CHILD_SESSION_DAYS is 30', () {
      expect(AppConstants.childSessionDays, 30);
    });
    
    test('INVESTMENT_MIN_MULTIPLIER is greater than 0', () {
      expect(AppConstants.investmentMinMultiplier, greaterThan(0));
      expect(AppConstants.investmentMinMultiplier, 0.01);
    });
    
    test('TRANSACTION_ARCHIVE_YEARS is 1', () {
      expect(AppConstants.transactionArchiveYears, 1);
    });
    
    test('bucket type constants are defined', () {
      expect(AppConstants.bucketMoney, 'money');
      expect(AppConstants.bucketInvestments, 'investments');
      expect(AppConstants.bucketCharity, 'charity');
    });
    
    test('user role constants are defined', () {
      expect(AppConstants.roleParent, 'parent');
      expect(AppConstants.roleChild, 'child');
    });
  });
}
