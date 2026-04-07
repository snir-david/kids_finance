import 'package:flutter/material.dart' hide Badge;
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/offline/widgets/offline_status_banner.dart';
import '../../../core/theme/app_theme.dart';
import '../../buckets/domain/bucket.dart';
import '../../buckets/domain/bucket_repository.dart';
import '../../buckets/presentation/widgets/bucket_action_sheets.dart';
import '../../buckets/presentation/widgets/celebration_overlay.dart';
import '../../buckets/providers/buckets_providers.dart';
import '../../children/providers/children_providers.dart';
import '../../badges/data/models/badge_model.dart';
import '../../badges/data/repositories/badge_repository_provider.dart';
import '../../badges/presentation/providers/badges_provider.dart';
import '../../badges/presentation/widgets/badge_chip.dart';
import '../../badges/presentation/widgets/badge_shelf.dart';
import '../../goals/data/models/goal_model.dart';
import '../../goals/data/repositories/goal_repository_provider.dart';
import '../../goals/presentation/providers/goals_provider.dart';
import '../../goals/presentation/widgets/add_goal_dialog.dart';
import '../../goals/presentation/widgets/goal_card.dart';
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

class ChildHomeScreen extends ConsumerStatefulWidget {
  const ChildHomeScreen({super.key});

  @override
  ConsumerState<ChildHomeScreen> createState() => _ChildHomeScreenState();
}

class _ChildHomeScreenState extends ConsumerState<ChildHomeScreen> {
  /// Tracks which completed goals have already triggered a celebration,
  /// to avoid showing the overlay more than once per goal.
  final _celebratedGoalIds = <String>{};

  /// Tracks which newly-earned badges have already shown a celebration,
  /// to avoid re-triggering on rebuild.
  final _celebratedBadgeIds = <String>{};

  @override
  Widget build(BuildContext context) {
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

            return PopScope(
              canPop: false,
              onPopInvokedWithResult: (didPop, result) {
                if (!didPop) {
                  ref.read(activeChildProvider.notifier).setState(null);
                  ref.read(selectedChildProvider.notifier).setState(null);
                  context.go('/parent-home');
                }
              },
              child: Scaffold(
                backgroundColor: AppTheme.backgroundColor,
                appBar: AppBar(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  title: Text(
                    AppLocalizations.of(context).hiName(child.displayName),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.exit_to_app),
                      tooltip: AppLocalizations.of(context).backToParent,
                      onPressed: () {
                        ref.read(activeChildProvider.notifier).setState(null);
                        ref.read(selectedChildProvider.notifier).setState(null);
                        context.go('/parent-home');
                      },
                    ),
                  ],
                ),
                body: _buildDashboard(context, familyId, child.id, child.displayName),
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

    // Watch badges so we can trigger celebration for newly earned ones.
    final badgesAsync = ref.watch(badgesProvider((
      childId: childId,
      familyId: familyId,
    )));
    badgesAsync.whenData((badges) {
      _checkAndCelebrateBadges(context, badges, familyId, childId);
    });

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
                          Text(
                            AppLocalizations.of(context).totalMoney,
                            style: const TextStyle(
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
                      name: AppLocalizations.of(context).money,
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
                            name: AppLocalizations.of(context).savings,
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
                            name: AppLocalizations.of(context).charity,
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

                    const SizedBox(height: 24),

                    // Savings Goals section
                    _buildGoalsSection(context, familyId, childId, moneyBucket.balance),

                    const SizedBox(height: 24),

                    // Achievement Badges shelf
                    BadgeShelf(familyId: familyId, childId: childId),

                    const SizedBox(height: 24),
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
      builder: (_) => CharityActionSheet(
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
      builder: (_) => InvestmentActionSheet(
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
      builder: (_) => MoneyActionSheet(
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
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
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
                color: Theme.of(context).colorScheme.onSurface,
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
              AppLocalizations.of(context).recentActivity,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
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

  // ─── Savings Goals ────────────────────────────────────────────────────────

  Widget _buildGoalsSection(
    BuildContext context,
    String familyId,
    String childId,
    double moneyBalance,
  ) {
    final l10n = AppLocalizations.of(context);
    final goalsAsync = ref.watch(
      goalsProvider((familyId: familyId, childId: childId)),
    );
    final goalRepo = ref.read(goalRepositoryProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header with "+" button
        Row(
          children: [
            const Text('🎯', style: TextStyle(fontSize: 24)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                l10n.savingsGoals,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              tooltip: l10n.addGoal,
              onPressed: () => _showAddGoalDialog(
                context,
                familyId,
                childId,
                goalRepo,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        goalsAsync.when(
          data: (goals) {
            final activeGoals =
                goals.where((g) => g.isActive).toList();
            _checkAndCelebrate(context, activeGoals);
            if (activeGoals.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    l10n.noGoalsYet,
                    style:
                        Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }
            return Column(
              children: activeGoals
                  .map(
                    (goal) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: GoalCard(
                        goal: goal,
                        currentBalance: moneyBalance,
                        onTap: () {/* future: edit / delete */},
                      ),
                    ),
                  )
                  .toList(),
            );
          },
          loading: () =>
              const Center(child: CircularProgressIndicator()),
          error: (_, __) => const SizedBox.shrink(),
        ),
      ],
    );
  }

  void _showAddGoalDialog(
    BuildContext context,
    String familyId,
    String childId,
    dynamic goalRepo,
  ) {
    showDialog<void>(
      context: context,
      builder: (_) => AddGoalDialog(
        onSave: (name, targetAmount) async {
          await goalRepo.createGoal(
            familyId,
            childId,
            name,
            targetAmount,
          );
        },
      ),
    );
  }

  /// Schedules a celebration overlay for each newly-completed goal.
  /// Mutates [_celebratedGoalIds] to prevent duplicate shows.
  void _checkAndCelebrate(BuildContext context, List<Goal> goals) {
    for (final goal in goals) {
      if (goal.isCompleted && !_celebratedGoalIds.contains(goal.id)) {
        _celebratedGoalIds.add(goal.id);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _showGoalCelebration(context);
        });
      }
    }
  }

  void _showGoalCelebration(BuildContext context) {
    final overlayState = Overlay.of(context);
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => CelebrationOverlay(
        type: CelebrationType.investment,
        onComplete: () {
          if (entry.mounted) entry.remove();
        },
      ),
    );
    overlayState.insert(entry);
    // Auto-dismiss after 2 seconds regardless of animation duration.
    Future.delayed(const Duration(seconds: 2), () {
      if (entry.mounted) entry.remove();
    });
  }

  // ─── Badge Celebrations ───────────────────────────────────────────────────

  void _checkAndCelebrateBadges(
    BuildContext context,
    List<Badge> badges,
    String familyId,
    String childId,
  ) {
    for (final badge in badges) {
      if (!badge.seen && !_celebratedBadgeIds.contains(badge.id)) {
        _celebratedBadgeIds.add(badge.id);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _showBadgeCelebration(context, badge, familyId, childId);
          }
        });
      }
    }
  }

  void _showBadgeCelebration(
    BuildContext context,
    Badge badge,
    String familyId,
    String childId,
  ) {
    showGeneralDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.75),
      barrierDismissible: false,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (ctx, _, __) => _BadgeCelebrationDialog(
        badge: badge,
        familyId: familyId,
        childId: childId,
      ),
    );
  }
}

// ─── Badge Celebration Dialog ─────────────────────────────────────────────────

class _BadgeCelebrationDialog extends ConsumerStatefulWidget {
  const _BadgeCelebrationDialog({
    required this.badge,
    required this.familyId,
    required this.childId,
  });

  final Badge badge;
  final String familyId;
  final String childId;

  @override
  ConsumerState<_BadgeCelebrationDialog> createState() =>
      _BadgeCelebrationDialogState();
}

class _BadgeCelebrationDialogState
    extends ConsumerState<_BadgeCelebrationDialog> {
  bool _dismissed = false;

  @override
  void initState() {
    super.initState();
    // Auto-dismiss after 3 seconds.
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && !_dismissed) _dismiss();
    });
  }

  void _dismiss() {
    if (_dismissed) return;
    _dismissed = true;
    ref
        .read(badgeRepositoryProvider)
        .markSeen(widget.familyId, widget.childId, widget.badge.id);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final badgeName = badgeLocalizedName(l10n, widget.badge.type);
    final badgeDesc = badgeLocalizedDescription(l10n, widget.badge.type);

    return Material(
      color: Colors.transparent,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 🎉 header
                Text(
                  '🎉',
                  style: const TextStyle(fontSize: 40),
                ),
                const SizedBox(height: 8),

                // Title
                Text(
                  l10n.badgeUnlocked,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: colorScheme.primary,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),

                // Large animated badge emoji
                Text(
                  widget.badge.emoji,
                  style: const TextStyle(fontSize: 80),
                )
                    .animate()
                    .scale(
                      begin: const Offset(0.1, 0.1),
                      end: const Offset(1.0, 1.0),
                      duration: const Duration(milliseconds: 600),
                      curve: Curves.elasticOut,
                    )
                    .fadeIn(duration: const Duration(milliseconds: 200)),

                const SizedBox(height: 16),

                // Badge name
                Text(
                  badgeName,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),

                // Description
                Text(
                  badgeDesc,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                // Awesome! button
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _dismiss,
                    child: const Text('⭐  Awesome!'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
