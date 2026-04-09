import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/currency/currency_formatter.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../children/domain/child.dart';
import '../../../children/providers/children_providers.dart';
import '../../../transactions/domain/transaction.dart' as app_tx;
import '../providers/family_feed_provider.dart';
import '../widgets/transaction_feed_item.dart';

/// Filter groups — which transaction types belong to each chip label.
const _kDepositTypes = {
  app_tx.TransactionType.moneyAdded,
  app_tx.TransactionType.moneySet,
};
const _kWithdrawTypes = {
  app_tx.TransactionType.moneyRemoved,
  app_tx.TransactionType.spend,
};
const _kDonationTypes = {
  app_tx.TransactionType.charityDonated,
  app_tx.TransactionType.donate,
};
const _kMultiplyTypes = {app_tx.TransactionType.investmentMultiplied};
const _kAllowanceTypes = {app_tx.TransactionType.distributed};

class ActivityFeedScreen extends ConsumerStatefulWidget {
  const ActivityFeedScreen({super.key, required this.familyId});
  final String familyId;

  @override
  ConsumerState<ActivityFeedScreen> createState() => _ActivityFeedScreenState();
}

class _ActivityFeedScreenState extends ConsumerState<ActivityFeedScreen> {
  String? _selectedChildId; // null = all children
  String? _selectedTypeKey; // null = all types

  static const _typeKeys = ['deposit', 'withdraw', 'donation', 'multiply', 'allowance'];

  Set<app_tx.TransactionType>? _typesForKey(String? key) => switch (key) {
        'deposit' => _kDepositTypes,
        'withdraw' => _kWithdrawTypes,
        'donation' => _kDonationTypes,
        'multiply' => _kMultiplyTypes,
        'allowance' => _kAllowanceTypes,
        _ => null,
      };

  String _typeLabel(AppLocalizations l10n, String key) => switch (key) {
        'deposit' => l10n.typeDeposit,
        'withdraw' => l10n.typeWithdraw,
        'donation' => l10n.typeDonation,
        'multiply' => l10n.typeMultiply,
        'allowance' => l10n.typeAllowance,
        _ => key,
      };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final formatter = ref.watch(currencyFormatterProvider);
    final childrenAsync = ref.watch(childrenProvider(widget.familyId));
    final feedAsync = ref.watch(
      familyFeedProvider((familyId: widget.familyId, childId: _selectedChildId)),
    );

    final children = childrenAsync.value ?? [];
    final Map<String, Child> childMap = {for (final c in children) c.id: c};

    return Scaffold(
      appBar: AppBar(title: Text(l10n.familyActivity)),
      body: Column(
        children: [
          // ── Child filter chips ──────────────────────────────────────────────
          _FilterBar(
            scrollable: true,
            children: [
              _Chip(
                label: l10n.allChildren,
                selected: _selectedChildId == null,
                onTap: () => setState(() => _selectedChildId = null),
              ),
              ...children.map((c) => _Chip(
                    label: '${c.avatarEmoji} ${c.displayName}',
                    selected: _selectedChildId == c.id,
                    onTap: () => setState(() => _selectedChildId = c.id),
                  )),
            ],
          ),
          const Divider(height: 1),
          // ── Type filter chips ───────────────────────────────────────────────
          _FilterBar(
            scrollable: true,
            children: [
              _Chip(
                label: l10n.allTypes,
                selected: _selectedTypeKey == null,
                onTap: () => setState(() => _selectedTypeKey = null),
              ),
              ..._typeKeys.map((k) => _Chip(
                    label: _typeLabel(l10n, k),
                    selected: _selectedTypeKey == k,
                    onTap: () => setState(() => _selectedTypeKey = k),
                  )),
            ],
          ),
          const Divider(height: 1),
          // ── Feed ────────────────────────────────────────────────────────────
          Expanded(
            child: feedAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('$e')),
              data: (txns) {
                final allowed = _typesForKey(_selectedTypeKey);
                final filtered = allowed == null
                    ? txns
                    : txns.where((t) => allowed.contains(t.type)).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('📭', style: TextStyle(fontSize: 48)),
                        const SizedBox(height: 12),
                        Text(l10n.noActivity,
                            style: Theme.of(context).textTheme.titleMedium),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1, indent: 72),
                  itemBuilder: (context, i) => TransactionFeedItem(
                    transaction: filtered[i],
                    child: childMap[filtered[i].childId],
                    formatter: formatter,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({required this.children, this.scrollable = false});
  final List<Widget> children;
  final bool scrollable;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        children: children
            .expand((w) => [w, const SizedBox(width: 8)])
            .toList(),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: selected
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.outline,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : null,
          ),
        ),
      ),
    );
  }
}
