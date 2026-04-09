import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'currency_provider.dart';

class CurrencyFormatter {
  final AppCurrency currency;
  CurrencyFormatter(this.currency);

  /// Format a double amount as a currency string.
  /// e.g. formatAmount(1234.5) → "₪1,234.50" or "$1,234.50"
  String formatAmount(double amount) {
    final symbol = currency.symbol;
    final formatted = amount.abs().toStringAsFixed(2).replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
        );
    final sign = amount < 0 ? '-' : '';
    return '$sign$symbol$formatted';
  }
}

/// Convenience provider — consume this anywhere in the widget tree
final currencyFormatterProvider = Provider<CurrencyFormatter>((ref) {
  final currency = ref.watch(currencyProvider);
  return CurrencyFormatter(currency);
});
