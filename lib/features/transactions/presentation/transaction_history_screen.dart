import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../buckets/domain/bucket.dart';
import '../domain/transaction.dart' as app_transaction;
import '../providers/transaction_providers.dart';

class TransactionHistoryScreen extends ConsumerWidget {
  const TransactionHistoryScreen({
    super.key,
    required this.childId,
    required this.familyId,
    required this.childName,
  });

  final String childId;
  final String familyId;
  final String childName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsAsync = ref.watch(transactionHistoryProvider((
      childId: childId,
      familyId: familyId,
    )));

    return Scaffold(
      appBar: AppBar(
        title: Text("$childName's History"),
        centerTitle: true,
      ),
      body: transactionsAsync.when(
        data: (transactions) {
          if (transactions.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('📋', style: TextStyle(fontSize: 64)),
                  SizedBox(height: 16),
                  Text(
                    'No transactions yet',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Actions will appear here',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: transactions.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) =>
                _TransactionTile(transaction: transactions[index]),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  const _TransactionTile({required this.transaction});
  final app_transaction.Transaction transaction;

  @override
  Widget build(BuildContext context) {
    final info = _transactionInfo(transaction);
    final dateStr = DateFormat('MMM d, yyyy • h:mm a').format(transaction.performedAt);
    final balanceChange = transaction.newBalance - transaction.previousBalance;
    final isPositive = balanceChange >= 0;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: info.color.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: info.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: Text(info.emoji, style: const TextStyle(fontSize: 22)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    info.label,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    dateStr,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                    ),
                  ),
                  if (transaction.note != null && transaction.note!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        transaction.note!,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${isPositive ? '+' : ''}\$${balanceChange.abs().toStringAsFixed(2)}',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: isPositive ? AppTheme.moneyColor : Colors.red.shade400,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '→ \$${transaction.newBalance.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  _TxInfo _transactionInfo(app_transaction.Transaction t) {
    switch (t.type) {
      case app_transaction.TransactionType.moneySet:
        return _TxInfo(
          emoji: '💰',
          label: 'Money set',
          color: AppTheme.moneyColor,
        );
      case app_transaction.TransactionType.moneyAdded:
        return _TxInfo(
          emoji: '➕',
          label: 'Money added',
          color: AppTheme.moneyColor,
        );
      case app_transaction.TransactionType.moneyRemoved:
        return _TxInfo(
          emoji: '➖',
          label: 'Money removed',
          color: Colors.orange,
        );
      case app_transaction.TransactionType.investmentMultiplied:
        final mult = t.multiplier != null ? '×${t.multiplier!.toStringAsFixed(1)}' : '';
        return _TxInfo(
          emoji: '📈',
          label: 'Investment multiplied $mult',
          color: AppTheme.investmentsColor,
        );
      case app_transaction.TransactionType.charityDonated:
        return _TxInfo(
          emoji: '❤️',
          label: 'Donated to charity',
          color: AppTheme.charityColor,
        );
    }
  }
}

class _TxInfo {
  const _TxInfo({
    required this.emoji,
    required this.label,
    required this.color,
  });
  final String emoji;
  final String label;
  final Color color;
}

// Bucket type label helper
extension BucketTypeLabel on BucketType {
  String get displayName {
    switch (this) {
      case BucketType.money:
        return 'Money';
      case BucketType.investment:
        return 'Investment';
      case BucketType.charity:
        return 'Charity';
    }
  }
}
