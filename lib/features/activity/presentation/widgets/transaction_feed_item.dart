import 'package:flutter/material.dart';
import '../../../../core/currency/currency_formatter.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../buckets/domain/bucket.dart';
import '../../../children/domain/child.dart';
import '../../../transactions/domain/transaction.dart' as app_tx;

class TransactionFeedItem extends StatelessWidget {
  const TransactionFeedItem({
    super.key,
    required this.transaction,
    required this.child,
    required this.formatter,
  });

  final app_tx.Transaction transaction;
  final Child? child;
  final CurrencyFormatter formatter;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final color = _bucketColor(transaction.bucketType);
    final emoji = _bucketEmoji(transaction.bucketType);
    final amount = formatter.formatAmount(transaction.amount);
    final label = _label(l10n, amount);
    final relDate = _relativeDate(l10n, transaction.performedAt);

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: color.withAlpha(30),
        child: Text(
          child?.avatarEmoji ?? '👤',
          style: const TextStyle(fontSize: 20),
        ),
      ),
      title: Row(
        children: [
          Text(
            child?.displayName ?? '—',
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: color.withAlpha(25),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$emoji ${l10n.bucketName(transaction.bucketType.name)}',
              style: TextStyle(fontSize: 11, color: color),
            ),
          ),
        ],
      ),
      subtitle: Text(label, style: const TextStyle(fontSize: 12)),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            _amountDisplay(amount),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: _isCredit(transaction.type) ? Colors.green : Colors.red,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 2),
          Text(relDate, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        ],
      ),
    );
  }

  Color _bucketColor(BucketType type) => switch (type) {
        BucketType.money => AppTheme.moneyColor,
        BucketType.investment => AppTheme.investmentsColor,
        BucketType.charity => AppTheme.charityColor,
      };

  String _bucketEmoji(BucketType type) => switch (type) {
        BucketType.money => '💰',
        BucketType.investment => '📈',
        BucketType.charity => '❤️',
      };

  bool _isCredit(app_tx.TransactionType type) => switch (type) {
        app_tx.TransactionType.moneyAdded ||
        app_tx.TransactionType.moneySet ||
        app_tx.TransactionType.distributed ||
        app_tx.TransactionType.investmentMultiplied =>
          true,
        _ => false,
      };

  String _amountDisplay(String formatted) {
    final credit = _isCredit(transaction.type);
    return credit ? '+$formatted' : '-$formatted';
  }

  String _label(AppLocalizations l10n, String amount) =>
      switch (transaction.type) {
        app_tx.TransactionType.moneyAdded => l10n.txMoneyAdded(amount),
        app_tx.TransactionType.moneyRemoved => l10n.txMoneyRemoved(amount),
        app_tx.TransactionType.moneySet => l10n.txMoneySet(amount),
        app_tx.TransactionType.charityDonated => l10n.txCharityDonated(amount),
        app_tx.TransactionType.distributed =>
          l10n.txAllowanceSplit(amount, l10n.bucketName(transaction.bucketType.name)),
        app_tx.TransactionType.investmentMultiplied =>
          l10n.txInvestmentMultiplied(
            transaction.multiplier?.toStringAsFixed(1) ?? '?',
            amount,
          ),
        app_tx.TransactionType.transfer =>
          l10n.txTransferFrom(amount, l10n.bucketName(transaction.bucketType.name)),
        app_tx.TransactionType.spend => l10n.txSpend(amount),
        app_tx.TransactionType.donate => l10n.txCharityDonated(amount),
      };

  String _relativeDate(AppLocalizations l10n, DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return l10n.justNow;
    if (diff.inHours < 1) return l10n.minutesAgo(diff.inMinutes);
    if (diff.inDays < 1) return l10n.hoursAgo(diff.inHours);
    if (diff.inDays == 1) return l10n.yesterday;
    return l10n.daysAgo(diff.inDays);
  }
}
