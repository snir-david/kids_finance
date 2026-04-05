/// Application-wide constants
class AppConstants {
  AppConstants._();

  // PIN Security
  static const int pinLength = 4;
  static const int pinMaxAttempts = 5;
  static const int pinLockoutMinutes = 15;

  // Session Management
  static const int childSessionDays = 30;

  // Investment Rules
  static const double investmentMinMultiplier = 0.01; // Must be > 0

  // Transaction Archive
  static const int transactionArchiveYears = 1;

  // Bucket Types
  static const String bucketMoney = 'money';
  static const String bucketInvestments = 'investments';
  static const String bucketCharity = 'charity';

  // User Roles
  static const String roleParent = 'parent';
  static const String roleChild = 'child';
}
