import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const kTooltipMoney = 'money_bucket';
const kTooltipInvestment = 'investment_bucket';
const kTooltipCharity = 'charity_bucket';

final tooltipProvider =
    NotifierProvider<TooltipNotifier, Set<String>>(TooltipNotifier.new);

class TooltipNotifier extends Notifier<Set<String>> {
  static const _prefsKey = 'tooltips_dismissed';

  @override
  Set<String> build() {
    _load();
    return const {};
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_prefsKey) ?? [];
    state = raw.toSet();
  }

  Future<void> dismiss(String key) async {
    state = {...state, key};
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_prefsKey, state.toList());
  }

  bool isDismissed(String key) => state.contains(key);

  Future<void> resetAll() async {
    state = const {};
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKey);
  }
}
