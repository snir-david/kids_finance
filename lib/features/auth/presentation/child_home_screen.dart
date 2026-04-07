import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/offline/widgets/offline_status_banner.dart';
import '../../../core/theme/app_theme.dart';
import '../../buckets/domain/bucket.dart';
import '../../buckets/domain/bucket_repository.dart';
import '../../buckets/presentation/widgets/celebration_overlay.dart';
import '../../buckets/providers/buckets_providers.dart';
import '../../children/providers/children_providers.dart';
import '../../transactions/domain/transaction.dart' as app_transaction;
import '../../transactions/providers/transaction_providers.dart';
import '../providers/auth_providers.dart';
import '../providers/session_provider.dart';

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
    // Session expiry check — redirect to PIN if the 24-hour session has lapsed.
    final sessionState = ref.watch(childSessionValidProvider);
    if (sessionState == SessionState.expired) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          ref.read(activeChildProvider.notifier).setState(null);
          context.go('/child-pin');
        }
      });
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

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
    final repo = ref.read(bucketRepositoryProvider);

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

        return Column(
          children: [
            const OfflineStatusBanner(),
            Expanded(
              child: SingleChildScrollView(
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
                      onTap: () => _showMoneySheet(
                        context, repo, familyId, childId, moneyBucket.balance,
                      ),
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
                            onTap: () => _showInvestmentSheet(
                              context, repo, familyId, childId, investmentBucket.balance,
                            ),
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
                            onTap: () => _showCharitySheet(
                              context, repo, familyId, childId, charityBucket.balance,
                            ),
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
              ),
            ),
          ],
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

  void _showCharitySheet(
    BuildContext context,
    BucketRepository repo,
    String familyId,
    String childId,
    double balance,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _CharitySheet(
        familyId: familyId,
        childId: childId,
        charityBalance: balance,
        repo: repo,
      ),
    );
  }

  void _showInvestmentSheet(
    BuildContext context,
    BucketRepository repo,
    String familyId,
    String childId,
    double balance,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _InvestmentSheet(
        familyId: familyId,
        childId: childId,
        investmentBalance: balance,
        repo: repo,
      ),
    );
  }

  void _showMoneySheet(
    BuildContext context,
    BucketRepository repo,
    String familyId,
    String childId,
    double balance,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _MoneySheet(
        familyId: familyId,
        childId: childId,
        moneyBalance: balance,
        repo: repo,
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
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
            if (onTap != null) ...[
              const SizedBox(height: 4),
              Icon(
                Icons.touch_app,
                size: isLarge ? 20 : 16,
                color: color.withValues(alpha: 0.5),
              ),
            ],
          ],
        ),
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
      app_transaction.TransactionType.distributed =>
        '🎁 Allowance split: \$${tx.amount.toStringAsFixed(2)} to ${tx.bucketType.name}',
      app_transaction.TransactionType.donate =>
        '❤️ Donated \$${tx.amount.toStringAsFixed(2)} to charity!',
      app_transaction.TransactionType.transfer =>
        tx.amount < 0
          ? '🔄 Transferred \$${tx.amount.abs().toStringAsFixed(2)} from ${tx.bucketType.name}'
          : '🔄 Received \$${tx.amount.toStringAsFixed(2)} in ${tx.bucketType.name}',
      app_transaction.TransactionType.spend =>
        '🛍️ Spent \$${tx.amount.toStringAsFixed(2)} from Money',
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

// ─── Charity Bottom Sheet ─────────────────────────────────────────────────────

class _CharitySheet extends StatefulWidget {
  const _CharitySheet({
    required this.familyId,
    required this.childId,
    required this.charityBalance,
    required this.repo,
  });

  final String familyId;
  final String childId;
  final double charityBalance;
  final BucketRepository repo;

  @override
  State<_CharitySheet> createState() => _CharitySheetState();
}

class _CharitySheetState extends State<_CharitySheet> {
  bool _isLoading = false;

  Future<void> _onDonate() async {
    if (widget.charityBalance <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No funds to donate! 😅'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await widget.repo.donateBucket(widget.familyId, widget.childId);
      if (!mounted) return;

      // Insert celebration overlay before closing the sheet so it stays visible
      final overlayState = Overlay.of(context);
      late OverlayEntry entry;
      entry = OverlayEntry(
        builder: (_) => CelebrationOverlay(
          type: CelebrationType.charity,
          onComplete: () => entry.remove(),
        ),
      );
      overlayState.insert(entry);
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        left: 24,
        right: 24,
        top: 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _SheetHandle(),
          const SizedBox(height: 20),
          const Text(
            '❤️ Charity',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            '\$${widget.charityBalance.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w900,
              color: AppTheme.charityColor,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tap below to donate your full balance to charity 🌍',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.charityColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: _isLoading ? null : _onDonate,
              child: _isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'Donate All 🎁',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Investment Bottom Sheet ──────────────────────────────────────────────────

class _InvestmentSheet extends StatefulWidget {
  const _InvestmentSheet({
    required this.familyId,
    required this.childId,
    required this.investmentBalance,
    required this.repo,
  });

  final String familyId;
  final String childId;
  final double investmentBalance;
  final BucketRepository repo;

  @override
  State<_InvestmentSheet> createState() => _InvestmentSheetState();
}

class _InvestmentSheetState extends State<_InvestmentSheet> {
  late final TextEditingController _drawController;
  final TextEditingController _multiplierController = TextEditingController();
  bool _isDrawLoading = false;
  bool _isMultiplyLoading = false;
  String? _multiplierError;

  @override
  void initState() {
    super.initState();
    _drawController = TextEditingController(
      text: widget.investmentBalance.toStringAsFixed(2),
    );
  }

  @override
  void dispose() {
    _drawController.dispose();
    _multiplierController.dispose();
    super.dispose();
  }

  Future<void> _onDraw() async {
    final amount = double.tryParse(_drawController.text.trim());
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter a valid amount'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if (amount > widget.investmentBalance) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Amount exceeds your savings balance!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    setState(() => _isDrawLoading = true);
    try {
      await widget.repo.transferBetweenBuckets(
        widget.familyId,
        widget.childId,
        BucketType.investment,
        BucketType.money,
        amount,
      );
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() => _isDrawLoading = false);
    }
  }

  Future<void> _onMultiply() async {
    final multiplier = double.tryParse(_multiplierController.text.trim());
    if (multiplier == null || multiplier <= 0) {
      setState(() => _multiplierError = 'Multiplier must be greater than 0');
      return;
    }
    setState(() {
      _multiplierError = null;
      _isMultiplyLoading = true;
    });
    try {
      await widget.repo.multiplyBucket(
        widget.familyId,
        widget.childId,
        BucketType.investment,
        multiplier,
      );
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() => _isMultiplyLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        left: 24,
        right: 24,
        top: 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: _SheetHandle()),
            const SizedBox(height: 20),
            const Center(
              child: Text(
                '📈 Savings',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                '\$${widget.investmentBalance.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.investmentsColor,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ── Draw to My Money ──────────────────────────────
            const Divider(),
            const Text(
              'Draw to My Money 💰',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _drawController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Amount',
                prefixText: '\$',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.investmentsColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _isDrawLoading ? null : _onDraw,
                child: _isDrawLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('Draw 💸', style: TextStyle(fontSize: 16)),
              ),
            ),

            const SizedBox(height: 20),

            // ── Multiply by Parent ────────────────────────────
            const Divider(),
            const Text(
              'Multiply by parent ✨',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _multiplierController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Multiplier (e.g. 1.5)',
                errorText: _multiplierError,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _isMultiplyLoading ? null : _onMultiply,
                child: _isMultiplyLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('Multiply 🚀', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Money Bottom Sheet ───────────────────────────────────────────────────────

class _MoneySheet extends StatefulWidget {
  const _MoneySheet({
    required this.familyId,
    required this.childId,
    required this.moneyBalance,
    required this.repo,
  });

  final String familyId;
  final String childId;
  final double moneyBalance;
  final BucketRepository repo;

  @override
  State<_MoneySheet> createState() => _MoneySheetState();
}

class _MoneySheetState extends State<_MoneySheet> {
  final TextEditingController _investController = TextEditingController();
  final TextEditingController _charityController = TextEditingController();
  final TextEditingController _withdrawController = TextEditingController();
  bool _isInvestLoading = false;
  bool _isCharityLoading = false;
  bool _isWithdrawLoading = false;

  @override
  void dispose() {
    _investController.dispose();
    _charityController.dispose();
    _withdrawController.dispose();
    super.dispose();
  }

  Future<void> _onSendToInvestment() async {
    final amount = double.tryParse(_investController.text.trim());
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter a valid amount'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    setState(() => _isInvestLoading = true);
    try {
      await widget.repo.transferBetweenBuckets(
        widget.familyId,
        widget.childId,
        BucketType.money,
        BucketType.investment,
        amount,
      );
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() => _isInvestLoading = false);
    }
  }

  Future<void> _onSendToCharity() async {
    final amount = double.tryParse(_charityController.text.trim());
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter a valid amount'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    setState(() => _isCharityLoading = true);
    try {
      await widget.repo.transferBetweenBuckets(
        widget.familyId,
        widget.childId,
        BucketType.money,
        BucketType.charity,
        amount,
      );
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() => _isCharityLoading = false);
    }
  }

  Future<void> _onWithdraw() async {
    final amount = double.tryParse(_withdrawController.text.trim());
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter a valid amount'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    setState(() => _isWithdrawLoading = true);
    try {
      await widget.repo.withdrawFromBucket(
        widget.familyId,
        widget.childId,
        amount,
      );
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() => _isWithdrawLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        left: 24,
        right: 24,
        top: 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: _SheetHandle()),
            const SizedBox(height: 20),
            const Center(
              child: Text(
                '💰 My Money',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                '\$${widget.moneyBalance.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.moneyColor,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ── Section A: Send to Savings ────────────────────
            const Divider(),
            const Text(
              'Send to Savings 📈',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _investController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Amount',
                prefixText: '\$',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.investmentsColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _isInvestLoading ? null : _onSendToInvestment,
                child: _isInvestLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Send to Savings 📈',
                        style: TextStyle(fontSize: 16),
                      ),
              ),
            ),

            const SizedBox(height: 20),

            // ── Section B: Send to Charity ────────────────────
            const Divider(),
            const Text(
              'Send to Charity ❤️',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _charityController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Amount',
                prefixText: '\$',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.charityColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _isCharityLoading ? null : _onSendToCharity,
                child: _isCharityLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Send to Charity 🎁',
                        style: TextStyle(fontSize: 16),
                      ),
              ),
            ),

            const SizedBox(height: 20),

            // ── Section C: Withdraw ───────────────────────────
            const Divider(),
            const Text(
              'Withdraw 💳',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 2),
            const Text(
              'Simulate a purchase',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _withdrawController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Amount',
                prefixText: '\$',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _isWithdrawLoading ? null : _onWithdraw,
                child: _isWithdrawLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Withdraw 💳',
                        style: TextStyle(fontSize: 16),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Shared sheet drag-handle widget ─────────────────────────────────────────

class _SheetHandle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}
