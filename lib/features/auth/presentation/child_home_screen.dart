import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../buckets/domain/bucket.dart';
import '../../buckets/providers/buckets_providers.dart';
import '../../children/providers/children_providers.dart';
import '../../transactions/domain/transaction.dart' as app_transaction;
import '../../transactions/providers/transaction_providers.dart';
import '../providers/auth_providers.dart';

Bucket _createEmptyBucket(BucketType type, String childId, String familyId) {
  return Bucket(
    id: '',
    childId: childId,
    familyId: familyId,
    type: type,
    balance: 0,
    lastUpdatedAt: DateTime.now(),
  );
}

class ChildHomeScreen extends ConsumerWidget {
  const ChildHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final childId = ref.watch(activeChildProvider);
    
    if (childId == null) {
      return const Scaffold(
        body: Center(child: Text('No child logged in')),
      );
    }

    final familyIdAsync = ref.watch(currentFamilyIdProvider);

    return familyIdAsync.when(
      data: (familyId) {
        if (familyId == null) {
          return const Scaffold(
            body: Center(child: Text('No family found')),
          );
        }

        final childAsync = ref.watch(childProvider((
          childId: childId,
          familyId: familyId,
        )));

        return childAsync.when(
          data: (child) {
            if (child == null) {
              return const Scaffold(
                body: Center(child: Text('Child not found')),
              );
            }

            return Scaffold(
              backgroundColor: AppTheme.backgroundColor,
              appBar: AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                title: Text(
                  'Hi ${child.displayName}! 👋',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.people_outline),
                    tooltip: 'Switch Child',
                    onPressed: () {
                      ref.read(activeChildProvider.notifier).setState(null);
                      ref.read(selectedChildProvider.notifier).setState(null);
                      context.go('/child-picker');
                    },
                  ),
                ],
              ),
              body: _buildDashboard(context, ref, familyId, child.id, child.displayName),
            );
          },
          loading: () => const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          ),
          error: (error, stack) => Scaffold(
            body: Center(child: Text('Error: $error')),
          ),
        );
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        body: Center(child: Text('Error: $error')),
      ),
    );
  }

  Widget _buildDashboard(
    BuildContext context,
    WidgetRef ref,
    String familyId,
    String childId,
    String childName,
  ) {
    final bucketsAsync = ref.watch(childBucketsProvider((
      childId: childId,
      familyId: familyId,
    )));
    final transactionsAsync = ref.watch(recentTransactionsProvider((
      childId: childId,
      familyId: familyId,
    )));

    return bucketsAsync.when(
      data: (buckets) {
        final moneyBucket = buckets.firstWhere(
          (b) => b.type == BucketType.money,
          orElse: () => _createEmptyBucket(BucketType.money, childId, familyId),
        );
        final investmentBucket = buckets.firstWhere(
          (b) => b.type == BucketType.investment,
          orElse: () => _createEmptyBucket(BucketType.investment, childId, familyId),
        );
        final charityBucket = buckets.firstWhere(
          (b) => b.type == BucketType.charity,
          orElse: () => _createEmptyBucket(BucketType.charity, childId, familyId),
        );

        final total = moneyBucket.balance + investmentBucket.balance + charityBucket.balance;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Total wealth card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primaryColor,
                      AppTheme.primaryColor.withValues(alpha: 0.7),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryColor.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Text(
                      'Total Money',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '\$${total.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 40,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Big Money bucket card
              _buildKidBucketCard(
                context,
                emoji: '💰',
                name: 'Money',
                balance: moneyBucket.balance,
                color: AppTheme.moneyColor,
                isLarge: true,
              ),
              
              const SizedBox(height: 16),
              
              // Investment and Charity side by side
              Row(
                children: [
                  Expanded(
                    child: _buildKidBucketCard(
                      context,
                      emoji: '📈',
                      name: 'Savings',
                      balance: investmentBucket.balance,
                      color: AppTheme.investmentsColor,
                      isLarge: false,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildKidBucketCard(
                      context,
                      emoji: '❤️',
                      name: 'Charity',
                      balance: charityBucket.balance,
                      color: AppTheme.charityColor,
                      isLarge: false,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Recent transactions
              transactionsAsync.when(
                data: (transactions) => _buildRecentTransactions(
                  context,
                  transactions.take(3).toList(),
                ),
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error loading buckets: $error'),
          ],
        ),
      ),
    );
  }

  Widget _buildKidBucketCard(
    BuildContext context, {
    required String emoji,
    required String name,
    required double balance,
    required Color color,
    required bool isLarge,
  }) {
    return Container(
      padding: EdgeInsets.all(isLarge ? 24 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 2),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            emoji,
            style: TextStyle(fontSize: isLarge ? 56 : 40),
          ),
          SizedBox(height: isLarge ? 12 : 8),
          Text(
            name,
            style: TextStyle(
              fontSize: isLarge ? 24 : 18,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: isLarge ? 8 : 4),
          Text(
            '\$${balance.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: isLarge ? 32 : 24,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentTransactions(
    BuildContext context,
    List<app_transaction.Transaction> transactions,
  ) {
    if (transactions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              '📋',
              style: TextStyle(fontSize: 24),
            ),
            const SizedBox(width: 8),
            Text(
              'Recent Activity',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: transactions.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final transaction = transactions[index];
              return ListTile(
                dense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                title: Text(
                  _transactionDescription(transaction),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                subtitle: Text(
                  _formatDate(transaction.performedAt),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  String _transactionDescription(app_transaction.Transaction tx) {
    return switch (tx.type) {
      app_transaction.TransactionType.moneySet =>
        '💰 Money set to \$${tx.newBalance.toStringAsFixed(2)}',
      app_transaction.TransactionType.moneyAdded =>
        '💰 Added \$${tx.amount.toStringAsFixed(2)} to Money',
      app_transaction.TransactionType.moneyRemoved =>
        '💰 Removed \$${tx.amount.toStringAsFixed(2)} from Money',
      app_transaction.TransactionType.investmentMultiplied =>
        '📈 Savings ×${tx.multiplier?.toStringAsFixed(1) ?? '1'} = \$${tx.newBalance.toStringAsFixed(2)}',
      app_transaction.TransactionType.charityDonated =>
        '❤️ Donated \$${tx.previousBalance.toStringAsFixed(2)} to charity!',
    };
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return 'Just now';
        }
        return '${difference.inMinutes}m ago';
      }
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${date.month}/${date.day}/${date.year}';
    }
  }
}
