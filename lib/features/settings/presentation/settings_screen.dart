import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/currency/currency_provider.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/l10n/locale_provider.dart';
import '../../../core/theme/theme_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final currentTheme = ref.watch(themeModeProvider);
    final currentLocale = ref.watch(localeProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settings),
      ),
      body: ListView(
        children: [
          // ─── Language section ──────────────────────────────────────────────
          _SectionHeader(title: l10n.language),
          _ChoiceTile(
            title: l10n.english,
            selected: currentLocale.languageCode == 'en',
            onTap: () => ref.read(localeProvider.notifier).setLocale(const Locale('en')),
          ),
          _ChoiceTile(
            title: 'עברית (Hebrew)',
            selected: currentLocale.languageCode == 'he',
            onTap: () => ref.read(localeProvider.notifier).setLocale(const Locale('he')),
          ),
          const Divider(),
          // ─── Theme section ─────────────────────────────────────────────────
          _SectionHeader(title: l10n.theme),
          _ChoiceTile(
            title: l10n.themeSystem,
            selected: currentTheme == ThemeMode.system,
            onTap: () => ref.read(themeModeProvider.notifier).setMode(ThemeMode.system),
          ),
          _ChoiceTile(
            title: l10n.themeLight,
            selected: currentTheme == ThemeMode.light,
            onTap: () => ref.read(themeModeProvider.notifier).setMode(ThemeMode.light),
          ),
          _ChoiceTile(
            title: l10n.themeDark,
            selected: currentTheme == ThemeMode.dark,
            onTap: () => ref.read(themeModeProvider.notifier).setMode(ThemeMode.dark),
          ),
          const Divider(),
          // ─── Currency section ──────────────────────────────────────────────
          _SectionHeader(title: l10n.currency),
          ...AppCurrency.values.map((c) => _ChoiceTile(
            title: c.displayName,
            selected: ref.watch(currencyProvider) == c,
            onTap: () => ref.read(currencyProvider.notifier).setCurrency(c),
          )),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _ChoiceTile extends StatelessWidget {
  const _ChoiceTile({
    required this.title,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(title),
      trailing: selected ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary) : null,
      onTap: onTap,
    );
  }
}
