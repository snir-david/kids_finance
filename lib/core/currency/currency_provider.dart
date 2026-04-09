import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppCurrency {
  ils, // ₪ Israeli Shekel
  usd, // $ US Dollar
  eur, // € Euro
  gbp, // £ British Pound
}

extension AppCurrencyExtension on AppCurrency {
  String get symbol {
    switch (this) {
      case AppCurrency.ils: return '₪';
      case AppCurrency.usd: return '\$';
      case AppCurrency.eur: return '€';
      case AppCurrency.gbp: return '£';
    }
  }

  String get displayName {
    switch (this) {
      case AppCurrency.ils: return 'ILS (₪)';
      case AppCurrency.usd: return 'USD (\$)';
      case AppCurrency.eur: return 'EUR (€)';
      case AppCurrency.gbp: return 'GBP (£)';
    }
  }
}

class CurrencyNotifier extends Notifier<AppCurrency> {
  static const _key = 'app_currency';

  @override
  AppCurrency build() {
    _load();
    return AppCurrency.ils;
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_key);
    if (saved != null) {
      state = AppCurrency.values.firstWhere(
        (c) => c.name == saved,
        orElse: () => AppCurrency.ils,
      );
    }
  }

  Future<void> setCurrency(AppCurrency currency) async {
    state = currency;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, currency.name);
  }
}

final currencyProvider = NotifierProvider<CurrencyNotifier, AppCurrency>(CurrencyNotifier.new);
