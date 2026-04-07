import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;
  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  bool get isHebrew => locale.languageCode == 'he';

  // ─── App ───────────────────────────────────────────────────────────────────
  String get appTitle => isHebrew ? 'כסף לילדים' : 'Kids Finance';

  // ─── Navigation labels ─────────────────────────────────────────────────────
  String get home => isHebrew ? 'בית' : 'Home';
  String get settings => isHebrew ? 'הגדרות' : 'Settings';
  String get transactions => isHebrew ? 'עסקאות' : 'Transactions';
  String get buckets => isHebrew ? 'קופסאות' : 'Buckets';
  String get children => isHebrew ? 'ילדים' : 'Children';

  // ─── Bucket names ──────────────────────────────────────────────────────────
  String get myMoney => isHebrew ? 'הכסף שלי' : 'My Money';
  String get investment => isHebrew ? 'השקעות' : 'Investment';
  String get charity => isHebrew ? 'צדקה' : 'Charity';

  // ─── Button labels ─────────────────────────────────────────────────────────
  String get add => isHebrew ? 'הוסף' : 'Add';
  String get remove => isHebrew ? 'הסר' : 'Remove';
  String get edit => isHebrew ? 'ערוך' : 'Edit';
  String get save => isHebrew ? 'שמור' : 'Save';
  String get cancel => isHebrew ? 'ביטול' : 'Cancel';
  String get confirm => isHebrew ? 'אשר' : 'Confirm';
  String get back => isHebrew ? 'חזור' : 'Back';
  String get distribute => isHebrew ? 'חלק' : 'Distribute';
  String get donate => isHebrew ? 'תרום' : 'Donate';
  String get withdraw => isHebrew ? 'משוך' : 'Withdraw';
  String get transfer => isHebrew ? 'העבר' : 'Transfer';
  String get multiply => isHebrew ? 'הכפל' : 'Multiply';
  String get signOut => isHebrew ? 'התנתק' : 'Sign Out';
  String get signIn => isHebrew ? 'התחבר' : 'Sign In';

  // ─── Screen titles ─────────────────────────────────────────────────────────
  String get myChildren => isHebrew ? 'הילדים שלי' : 'My Children';
  String get addChild => isHebrew ? 'הוסף ילד' : 'Add Child';
  String get childSettings => isHebrew ? 'הגדרות ילד' : 'Child Settings';
  String get parentDashboard => isHebrew ? 'לוח בקרה הורים' : 'Parent Dashboard';
  String get familyDashboard => isHebrew ? 'לוח משפחתי' : 'Family Dashboard';
  String get transactionHistory => isHebrew ? 'היסטוריית עסקאות' : 'Transaction History';

  // ─── Auth ──────────────────────────────────────────────────────────────────
  String get login => isHebrew ? 'כניסה' : 'Login';
  String get parentLogin => isHebrew ? 'כניסת הורה' : 'Parent Login';
  String get childLogin => isHebrew ? 'כניסת ילד' : 'Child Login';
  String get enterPin => isHebrew ? 'הכנס קוד' : 'Enter PIN';
  String get pin => isHebrew ? 'קוד' : 'PIN';
  String get wrongPin => isHebrew ? 'קוד שגוי' : 'Wrong PIN';
  String get forgotPassword => isHebrew ? 'שכחתי סיסמה' : 'Forgot Password';
  String get email => isHebrew ? 'דוא"ל' : 'Email';
  String get password => isHebrew ? 'סיסמה' : 'Password';
  String get createAccount => isHebrew ? 'צור חשבון' : 'Create Account';
  String get familyName => isHebrew ? 'שם המשפחה' : 'Family Name';
  String get childName => isHebrew ? 'שם הילד' : 'Child Name';

  // ─── Settings ──────────────────────────────────────────────────────────────
  String get darkMode => isHebrew ? 'מצב כהה' : 'Dark Mode';
  String get language => isHebrew ? 'שפה' : 'Language';
  String get theme => isHebrew ? 'ערכת נושא' : 'Theme';
  String get themeSystem => isHebrew ? 'מערכת' : 'System';
  String get themeLight => isHebrew ? 'בהיר' : 'Light';
  String get themeDark => isHebrew ? 'כהה' : 'Dark';
  String get english => isHebrew ? 'אנגלית' : 'English';
  String get hebrew => isHebrew ? 'עברית' : 'Hebrew (עברית)';

  // ─── Error messages ────────────────────────────────────────────────────────
  String get errorLoading => isHebrew ? 'שגיאה בטעינה' : 'Error loading';
  String get somethingWentWrong => isHebrew ? 'משהו השתבש' : 'Something went wrong';
  String get errorLoadingChildren => isHebrew ? 'שגיאה בטעינת ילדים' : 'Error loading children';
  String get noFamilyFound => isHebrew ? 'לא נמצאה משפחה' : 'No family found';
  String get tryAgain => isHebrew ? 'נסה שוב' : 'Try Again';

  // ─── Empty states ──────────────────────────────────────────────────────────
  String get noChildrenYet => isHebrew ? 'אין ילדים עדיין' : 'No children yet';
  String get noTransactions => isHebrew ? 'אין עסקאות' : 'No transactions';
  String get addFirstChild => isHebrew ? 'הוסף את הילד הראשון' : 'Add your first child';

  // ─── Dialogs ───────────────────────────────────────────────────────────────
  String get areYouSure => isHebrew ? 'האם אתה בטוח?' : 'Are you sure?';
  String get signOutConfirm =>
      isHebrew ? 'האם אתה בטוח שברצונך להתנתק?' : 'Are you sure you want to sign out?';
  String get deleteChildConfirm =>
      isHebrew ? 'פעולה זו תמחק את הילד לצמיתות.' : 'This will permanently delete the child.';
  String get inviteParent => isHebrew ? 'הזמן הורה נוסף' : 'Invite Another Parent';
  String get handToChild => isHebrew ? 'העבר לילד' : 'Hand to Child';

  // ─── Misc ──────────────────────────────────────────────────────────────────
  String get loading => isHebrew ? 'טוען...' : 'Loading...';
  String get balance => isHebrew ? 'יתרה' : 'Balance';
  String get amount => isHebrew ? 'סכום' : 'Amount';
  String get date => isHebrew ? 'תאריך' : 'Date';
  String get note => isHebrew ? 'הערה' : 'Note';
  String get multiplier => isHebrew ? 'מכפיל' : 'Multiplier';
  String get enterAmount => isHebrew ? 'הכנס סכום' : 'Enter amount';
  String get enterNote => isHebrew ? 'הכנס הערה' : 'Enter note';
  String get offlineChanges =>
      isHebrew
          ? '⚠ יש לך שינויים לא מסונכרנים שיאבדו בפחות משעה. התחבר לסנכרן.'
          : '⚠ You have offline changes that will be lost in less than 1 hour. Connect to sync.';
}

class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['en', 'he'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async => AppLocalizations(locale);

  @override
  bool shouldReload(AppLocalizationsDelegate old) => false;
}
