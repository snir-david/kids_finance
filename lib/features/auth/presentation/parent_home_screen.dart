import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/currency/currency_formatter.dart';
import '../../../core/currency/currency_provider.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/offline/sync_providers.dart';
import '../../../core/offline/widgets/conflict_resolution_dialog.dart';
import '../../../core/offline/widgets/offline_status_banner.dart';
import '../../../core/theme/app_theme.dart';
import '../../badges/presentation/providers/badges_provider.dart';
import '../../buckets/domain/bucket.dart';
import '../../buckets/presentation/widgets/bucket_action_sheets.dart';
import '../../buckets/presentation/widgets/celebration_overlay.dart';
import '../../buckets/providers/buckets_providers.dart';
import '../../children/domain/child.dart';
import '../../children/providers/children_providers.dart';
import '../../family/providers/family_providers.dart';
import '../../goals/presentation/providers/goals_provider.dart';
import '../../schedules/data/repositories/schedule_repository_provider.dart';
import '../../schedules/data/models/schedule_model.dart';
import '../../schedules/data/repositories/multiply_rule_repository_provider.dart';
import '../../schedules/data/models/multiply_rule_model.dart';
import '../../schedules/presentation/providers/schedules_provider.dart';
import '../../schedules/presentation/providers/multiply_rules_provider.dart';
import '../../schedules/presentation/widgets/add_schedule_dialog.dart';
import '../../schedules/presentation/widgets/add_multiply_rule_dialog.dart';
import '../providers/auth_providers.dart';

/// Notifier for selected child ID in parent dashboard
class SelectedChildIdNotifier extends Notifier<String?> {
  SelectedChildIdNotifier([this._initial]);
  final String? _initial;

  @override
  String? build() => _initial;

  void setState(String? value) => state = value;
}

final selectedChildIdProvider =
    NotifierProvider<SelectedChildIdNotifier, String?>(SelectedChildIdNotifier.new);

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

// ─── Available emoji options for new children ────────────────────────────────
const _kAvatarEmojis = [
  '🦁', '🐯', '🐻', '🐼', '🐸', '🦊', '🐶', '🐱',
  '🐮', '🐷', '🦄', '🐙', '🦋', '🐠', '🦕',
];

class ParentHomeScreen extends ConsumerStatefulWidget {
  const ParentHomeScreen({super.key});

  @override
  ConsumerState<ParentHomeScreen> createState() => _ParentHomeScreenState();
}

class _ParentHomeScreenState extends ConsumerState<ParentHomeScreen> with WidgetsBindingObserver {
  bool _hasShownExpiryWarning = false;
  ProviderSubscription? _conflictSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _conflictSubscription = showConflictDialogIfNeeded(context, ref);
      _processOverdueAllowances();
      _processOverdueMultiplyRules();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _conflictSubscription?.close();
    super.dispose();
  }

  /// Distributes any overdue allowances directly via Firestore — works without
  /// Firebase Blaze plan. Called once when the parent home screen opens.
  Future<void> _processOverdueAllowances() async {
    try {
      final familyId = ref.read(currentFamilyIdProvider).value;
      if (familyId == null || familyId.isEmpty) return;

      final processed = await ref
          .read(scheduleRepositoryProvider)
          .processOverdueAllowances(familyId);

      if (processed > 0 && mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.allowancesPaid(processed)),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (_) {}
  }

  Future<void> _processOverdueMultiplyRules() async {
    try {
      final familyId = ref.read(currentFamilyIdProvider).value;
      if (familyId == null || familyId.isEmpty) return;
      await ref.read(multiplyRuleRepositoryProvider).processOverdueRules(familyId);
    } catch (_) {}
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !_hasShownExpiryWarning) {
      final expiringOps = ref.read(offlineQueueProvider).getExpiring();
      if (expiringOps.isNotEmpty && mounted) {
        _hasShownExpiryWarning = true;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context).offlineChanges,
            ),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final familyIdAsync = ref.watch(currentFamilyIdProvider);
    final authState = ref.watch(firebaseAuthStateProvider);
    final user = authState.value;

    return familyIdAsync.when(
      data: (familyId) {
        if (familyId == null) {
          return Scaffold(
            body: Center(child: Text(l10n.noFamilyFound)),
          );
        }

        final familyAsync = ref.watch(familyProvider(familyId));
        final childrenAsync = ref.watch(childrenProvider(familyId));

        return Scaffold(
          appBar: AppBar(
            title: familyAsync.when(
              data: (family) => Text(family?.name ?? l10n.familyDashboard),
              loading: () => Text(l10n.loading),
              error: (_, __) => Text(l10n.parentDashboard),
            ),
            actions: [
              if (user != null)
                Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: CircleAvatar(
                    backgroundColor: AppTheme.primaryColor,
                    child: Text(
                      user.email?[0].toUpperCase() ?? 'P',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              IconButton(
                icon: const Icon(Icons.timeline),
                tooltip: l10n.familyActivity,
                onPressed: () => context.push('/family-feed', extra: familyId),
              ),
              IconButton(
                icon: const Icon(Icons.settings),
                tooltip: l10n.settings,
                onPressed: () => context.push('/settings'),
              ),
              IconButton(
                icon: const Icon(Icons.child_care),
                tooltip: l10n.handToChild,
                onPressed: () => context.push('/child-picker'),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                onSelected: (value) async {
                  if (value == 'family_settings') {
                    _showFamilySettingsDialog(context, ref, familyId);
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'family_settings',
                    child: ListTile(
                      leading: const Icon(Icons.group_add),
                      title: Text(l10n.inviteParent),
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.logout),
                tooltip: l10n.signOut,
                onPressed: () => _signOut(context),
              ),
            ],
          ),
          body: childrenAsync.when(
            data: (children) => _buildDashboard(context, familyId, children),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('${l10n.errorLoadingChildren}: $error'),
                ],
              ),
            ),
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

  Future<void> _signOut(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.signOut),
        content: Text(l10n.signOutConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.signOut),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await ref.read(authServiceProvider).signOut();
    }
  }

  Widget _buildDashboard(BuildContext context, String familyId, List<Child> children) {
    final l10n = AppLocalizations.of(context);
    if (children.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.family_restroom, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              l10n.noChildrenYet,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(l10n.addToGetStarted),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _showAddChildDialog(context, familyId),
              icon: const Icon(Icons.add),
              label: Text(l10n.addChild),
            ),
          ],
        ),
      );
    }

    final selectedChildId = ref.watch(selectedChildIdProvider);
    final effectiveChildId = selectedChildId ?? children.first.id;

    // Auto-select first child if none selected
    if (selectedChildId == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
        ref.read(selectedChildIdProvider.notifier).setState(children.first.id);
        }
      });
    }

    final selectedChild = children.firstWhere(
      (c) => c.id == effectiveChildId,
      orElse: () => children.first,
    );

    return Column(
      children: [
        const OfflineStatusBanner(),
        _buildChildSelector(context, familyId, children, selectedChildId),
        const Divider(height: 1),
        Expanded(
          child: _buildChildBuckets(context, familyId, selectedChild),
        ),
      ],
    );
  }

  Widget _buildChildSelector(
    BuildContext context,
    String familyId,
    List<Child> children,
    String? selectedChildId,
  ) {
    final l10n = AppLocalizations.of(context);
    return Container(
      height: 116,
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        // +1 for the "Add" button at the end
        itemCount: children.length + 1,
        itemBuilder: (context, index) {
          if (index == children.length) {
            return Padding(
              padding: const EdgeInsets.only(right: 12),
              child: GestureDetector(
                onTap: () => _showAddChildDialog(context, familyId),
                child: Container(
                  width: 80,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outline,
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_circle_outline,
                          size: 32, color: Theme.of(context).colorScheme.onSurfaceVariant),
                      const SizedBox(height: 4),
                      Text(
                        l10n.add,
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          final child = children[index];
          final isSelected = child.id == selectedChildId;

          // Watch unseen badge count for this child.
          final unseenCount = ref.watch(
            unseenBadgeCountProvider((
              familyId: familyId,
              childId: child.id,
            )),
          );

          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () {
                ref.read(selectedChildIdProvider.notifier).setState(child.id);
              },
              child: Container(
                width: 80,
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppTheme.primaryColor.withValues(alpha: 0.1)
                      : Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? AppTheme.primaryColor
                        : Theme.of(context).colorScheme.outline,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      child.avatarEmoji,
                      style: const TextStyle(fontSize: 32),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      child.displayName,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w400,
                        color: isSelected
                            ? AppTheme.primaryColor
                            : Theme.of(context).colorScheme.onSurface,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    // Unseen badge indicator
                    if (unseenCount > 0) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '🏅 $unseenCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildChildBuckets(BuildContext context, String familyId, Child child) {
    final l10n = AppLocalizations.of(context);
    final bucketsAsync = ref.watch(childBucketsProvider((
      childId: child.id,
      familyId: familyId,
    )));

    return bucketsAsync.when(
      data: (buckets) {
        Bucket bucket(BucketType t) => buckets.firstWhere(
              (b) => b.type == t,
              orElse: () => _createEmptyBucket(t, child.id, familyId),
            );

        final moneyBucket = bucket(BucketType.money);
        final investmentBucket = bucket(BucketType.investment);
        final charityBucket = bucket(BucketType.charity);

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.childBuckets(child.displayName),
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => context.push(
                      '/transaction-history',
                      extra: (
                        childId: child.id,
                        familyId: familyId,
                        childName: child.displayName,
                      ),
                    ),
                    icon: const Icon(Icons.history, size: 18),
                    label: Text(l10n.history),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Action bar at the top
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => _showDistributeFundsDialog(
                        context,
                        familyId,
                        child,
                      ),
                      icon: const Icon(Icons.add, size: 18),
                      label: Text(l10n.add),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => _showBucketActionDialog(
                        context,
                        familyId,
                        child,
                        buckets,
                        mode: _BucketActionMode.remove,
                      ),
                      icon: const Icon(Icons.remove, size: 18),
                      label: Text(l10n.remove),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.orange,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => _showEditChildDialog(
                        context,
                        familyId,
                        child,
                      ),
                      icon: const Icon(Icons.edit, size: 18),
                      label: Text(l10n.edit),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Three buckets below - tappable to open action sheets
              _BucketCard(
                emoji: '💰',
                name: l10n.myMoney,
                balance: moneyBucket.balance,
                color: AppTheme.moneyColor,
                onTap: () => showModalBottomSheet<void>(
                  context: context,
                  isScrollControlled: true,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  builder: (_) => MoneyActionSheet(
                    familyId: familyId,
                    childId: child.id,
                    moneyBalance: moneyBucket.balance,
                    repo: ref.read(bucketRepositoryProvider),
                    onComplete: () => ref.invalidate(childBucketsProvider(
                        (childId: child.id, familyId: familyId))),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _BucketCard(
                emoji: '📈',
                name: l10n.investment,
                balance: investmentBucket.balance,
                color: AppTheme.investmentsColor,
                onTap: () => showModalBottomSheet<void>(
                  context: context,
                  isScrollControlled: true,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  builder: (_) => InvestmentActionSheet(
                    familyId: familyId,
                    childId: child.id,
                    investmentBalance: investmentBucket.balance,
                    repo: ref.read(bucketRepositoryProvider),
                    onComplete: () => ref.invalidate(childBucketsProvider(
                        (childId: child.id, familyId: familyId))),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _BucketCard(
                emoji: '❤️',
                name: l10n.charity,
                balance: charityBucket.balance,
                color: AppTheme.charityColor,
                onTap: () => showModalBottomSheet<void>(
                  context: context,
                  isScrollControlled: true,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  builder: (_) => CharityActionSheet(
                    familyId: familyId,
                    childId: child.id,
                    charityBalance: charityBucket.balance,
                    repo: ref.read(bucketRepositoryProvider),
                    onComplete: () => ref.invalidate(childBucketsProvider(
                        (childId: child.id, familyId: familyId))),
                  ),
                ),
              ),

              // Compact savings goals summary (parent read-only view)
              _buildGoalsSummary(context, familyId, child, moneyBucket.balance),

              // Allowance schedule section
              _buildAllowanceSection(context, familyId, child),
              _buildMultiplyRulesSection(context, familyId, child),
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
            Text('${l10n.errorLoading}: $error'),
          ],
        ),
      ),
    );
  }

  // ─── Savings Goals Summary (parent read-only) ─────────────────────────────

  Widget _buildGoalsSummary(
    BuildContext context,
    String familyId,
    Child child,
    double moneyBalance,
  ) {
    final l10n = AppLocalizations.of(context);
    final goalsAsync = ref.watch(
      goalsProvider((familyId: familyId, childId: child.id)),
    );

    return goalsAsync.when(
      data: (goals) {
        final activeGoals = goals
            .where((g) => g.isActive && !g.isCompleted)
            .toList();
        if (activeGoals.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            Row(
              children: [
                const Text('🎯', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 6),
                Text(
                  l10n.savingsGoals,
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: activeGoals.map((goal) {
                  final progress = goal.progressPercent(moneyBalance);
                  return Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: Colors.green.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('🎯',
                            style: TextStyle(fontSize: 14)),
                        const SizedBox(width: 6),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              goal.name,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(
                              width: 80,
                              child: LinearProgressIndicator(
                                value: progress,
                                valueColor:
                                    const AlwaysStoppedAnimation<Color>(
                                        Colors.green),
                                backgroundColor:
                                    Colors.green.withValues(alpha: 0.2),
                                minHeight: 4,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            Text(
                              '${(progress * 100).toStringAsFixed(0)}%',
                              style: TextStyle(
                                fontSize: 10,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  // ─── Allowance Schedule Section ───────────────────────────────────────────

  Widget _buildAllowanceSection(
      BuildContext context, String familyId, Child child) {
    final l10n = AppLocalizations.of(context);
    final schedulesAsync = ref.watch(
      schedulesProvider((familyId: familyId, childId: child.id)),
    );

    return schedulesAsync.when(
      data: (schedules) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Row(
            children: [
              const Text('💰', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  l10n.allowanceSchedule,
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline, size: 20),
                tooltip: l10n.addSchedule,
                onPressed: () => _showAddScheduleDialog(context, familyId, child.id),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (schedules.isEmpty)
            GestureDetector(
              onTap: () => _showAddScheduleDialog(context, familyId, child.id),
              child: Text(
                l10n.noScheduleSet,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            )
          else
            Column(
              children: schedules.map((s) {
                final formatter = ref.read(currencyFormatterProvider);
                final amountStr = formatter.formatAmount(s.amount);
                final freqLabel = l10n.frequencyLabel(s.frequency.name);
                final dayLabel = s.frequency == ScheduleFrequency.monthly
                    ? '${l10n.dayOfMonth}: ${s.dayOfWeek}'
                    : l10n.weekdayName(s.dayOfWeek);
                final nextStr =
                    '${l10n.nextRun}: ${s.nextRunAt.day}/${s.nextRunAt.month}/${s.nextRunAt.year}';

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: Colors.blue.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$amountStr • $freqLabel • $dayLabel',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              nextStr,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      // Pause/Resume toggle
                      Switch(
                        value: s.isActive,
                        onChanged: (val) async {
                          await ref
                              .read(scheduleRepositoryProvider)
                              .toggleSchedule(familyId, s.id, val);
                        },
                      ),
                      // Delete
                      IconButton(
                        icon: const Icon(Icons.delete_outline,
                            size: 18, color: Colors.red),
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              content: Text(l10n.confirmDelete),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(ctx).pop(false),
                                  child: Text(l10n.cancel),
                                ),
                                FilledButton(
                                  onPressed: () =>
                                      Navigator.of(ctx).pop(true),
                                  child: Text(l10n.delete),
                                ),
                              ],
                            ),
                          );
                          if (confirm == true && context.mounted) {
                            await ref
                                .read(scheduleRepositoryProvider)
                                .deleteSchedule(familyId, s.id);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text(l10n.scheduleDeleted)),
                              );
                            }
                          }
                        },
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  // ─── Dialogs ───────────────────────────────────────────────────────────────

  void _showAddScheduleDialog(
      BuildContext context, String familyId, String childId) async {
    final l10n = AppLocalizations.of(context);
    final added = await showDialog<bool>(
      context: context,
      builder: (ctx) =>
          AddScheduleDialog(familyId: familyId, childId: childId),
    );
    if (added == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.scheduleAdded)),
      );
    }
  }

  Widget _buildMultiplyRulesSection(
      BuildContext context, String familyId, Child child) {
    final l10n = AppLocalizations.of(context);
    final rulesAsync = ref.watch(
      multiplyRulesProvider((familyId: familyId, childId: child.id)),
    );

    return rulesAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (rules) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Row(
            children: [
              Text(l10n.multiplyRules,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      )),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.add, size: 20),
                tooltip: l10n.addMultiplyRule,
                onPressed: () =>
                    _showAddMultiplyRuleDialog(context, familyId, child.id),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          if (rules.isEmpty)
            GestureDetector(
              onTap: () =>
                  _showAddMultiplyRuleDialog(context, familyId, child.id),
              child: Text(
                l10n.noMultiplyRules,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            )
          else
            ...rules.map((rule) => ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading:
                      const Icon(Icons.trending_up, color: Colors.blue, size: 20),
                  title: Text(
                    '+${rule.multiplierPercent.toStringAsFixed(1)}% ${l10n.frequencyLabel(rule.frequency.name)}',
                    style: const TextStyle(fontSize: 13),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, size: 18),
                    onPressed: () async {
                      await ref
                          .read(multiplyRuleRepositoryProvider)
                          .deleteRule(familyId, rule.id);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(l10n.multiplyRuleDeleted)),
                        );
                      }
                    },
                  ),
                )),
        ],
      ),
    );
  }

  void _showAddMultiplyRuleDialog(
      BuildContext context, String familyId, String childId) async {
    final l10n = AppLocalizations.of(context);
    final added = await showDialog<bool>(
      context: context,
      builder: (ctx) =>
          AddMultiplyRuleDialog(familyId: familyId, childId: childId),
    );
    if (added == true && context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.multiplyRuleAdded)));
    }
  }

  void _showAddChildDialog(BuildContext context, String familyId) {
    showDialog(
      context: context,
      builder: (ctx) => _AddChildDialog(familyId: familyId, ref: ref),
    );
  }

  void _showBucketActionDialog(
    BuildContext context,
    String familyId,
    Child child,
    List<Bucket> buckets,
    {required _BucketActionMode mode}
  ) {
    final authState = ref.read(firebaseAuthStateProvider);
    final uid = authState.value?.uid ?? '';
    showDialog(
      context: context,
      builder: (ctx) => _BucketActionDialog(
        familyId: familyId,
        child: child,
        buckets: buckets,
        mode: mode,
        performedByUid: uid,
        ref: ref,
      ),
    );
  }

  void _showDistributeFundsDialog(
    BuildContext context,
    String familyId,
    Child child,
  ) {
    final authState = ref.read(firebaseAuthStateProvider);
    final uid = authState.value?.uid ?? '';
    showDialog(
      context: context,
      builder: (ctx) => _DistributeFundsDialog(
        familyId: familyId,
        child: child,
        performedByUid: uid,
        ref: ref,
        onDistributed: () {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(AppLocalizations.of(context).addedToBuckets(child.displayName)),
                backgroundColor: Colors.green,
              ),
            );
          }
        },
      ),
    );
  }

  void _showEditChildDialog(
    BuildContext context,
    String familyId,
    Child child,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => _EditChildDialog(
        familyId: familyId,
        child: child,
        ref: ref,
      ),
    );
  }

}

// ─── Sub-widgets ──────────────────────────────────────────────────────────────

class _BucketCard extends ConsumerWidget {
  const _BucketCard({
    required this.emoji,
    required this.name,
    required this.balance,
    required this.color,
    this.onTap,
  });

  final String emoji;
  final String name;
  final double balance;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formatter = ref.watch(currencyFormatterProvider);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Text(emoji, style: const TextStyle(fontSize: 24)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      formatter.formatAmount(balance),
                      style: TextStyle(
                          fontSize: 22, fontWeight: FontWeight.w700, color: color),
                    ),
                    if (onTap != null) ...[
                      const SizedBox(width: 6),
                      Icon(Icons.touch_app, size: 14, color: color.withValues(alpha: 0.5)),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ),
    );
  }
}

// ─── Bucket action mode ───────────────────────────────────────────────────────

enum _BucketActionMode { add, remove }

// ─── Firestore error → human-readable message ─────────────────────────────────
/// Returns a user-friendly error string for any Firestore / platform failure.
/// Never exposes raw exception internals to the user.
String _firestoreErrorMessage(Object e) {
  if (e is FirebaseException) {
    switch (e.code) {
      case 'permission-denied':
        return 'You don\'t have permission to do that. Please sign out and sign back in.';
      case 'not-found':
        return 'The record wasn\'t found. Please refresh and try again.';
      case 'unavailable':
      case 'deadline-exceeded':
        return 'Network error — check your connection and try again.';
      case 'already-exists':
        return 'This already exists. Please refresh and try again.';
      case 'resource-exhausted':
        return 'Too many requests. Please wait a moment and try again.';
      default:
        return 'Something went wrong (${e.code}). Please try again.';
    }
  }
  return 'Something went wrong. Please try again.';
}

// ─── Add Child Dialog ─────────────────────────────────────────────────────────

class _AddChildDialog extends StatefulWidget {
  const _AddChildDialog({required this.familyId, required this.ref});
  final String familyId;
  final WidgetRef ref;

  @override
  State<_AddChildDialog> createState() => _AddChildDialogState();
}

class _AddChildDialogState extends State<_AddChildDialog> {
  final _nameController = TextEditingController();
  String _selectedEmoji = _kAvatarEmojis.first;
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();

    if (name.isEmpty) {
      setState(() => _error = 'Please enter a name');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final repo = widget.ref.read(familyRepositoryProvider);
      await repo.addChild(
        familyId: widget.familyId,
        displayName: name,
        avatarEmoji: _selectedEmoji,
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      final msg = _firestoreErrorMessage(e);
      if (mounted) {
        setState(() => _error = msg);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.addChild),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Name
            TextField(
              controller: _nameController,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: l10n.childName,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // Emoji picker
            Text(l10n.avatar,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _kAvatarEmojis.map((e) {
                final isSelected = e == _selectedEmoji;
                return GestureDetector(
                  onTap: () => setState(() => _selectedEmoji = e),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected
                            ? AppTheme.primaryColor
                            : Theme.of(context).colorScheme.outline,
                        width: isSelected ? 2 : 1,
                      ),
                      color: isSelected
                          ? AppTheme.primaryColor.withValues(alpha: 0.08)
                          : null,
                    ),
                    alignment: Alignment.center,
                    child: Text(e, style: const TextStyle(fontSize: 22)),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!,
                  style: const TextStyle(color: Colors.red, fontSize: 13)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: _isLoading ? null : _submit,
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : Text(l10n.add),
        ),
      ],
    );
  }
}

// ─── Bucket Action Dialog (unified add/remove for all buckets) ───────────────

class _BucketActionDialog extends StatefulWidget {
  const _BucketActionDialog({
    required this.familyId,
    required this.child,
    required this.buckets,
    required this.mode,
    required this.performedByUid,
    required this.ref,
  });
  final String familyId;
  final Child child;
  final List<Bucket> buckets;
  final _BucketActionMode mode;
  final String performedByUid;
  final WidgetRef ref;

  @override
  State<_BucketActionDialog> createState() => _BucketActionDialogState();
}

class _BucketActionDialogState extends State<_BucketActionDialog> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  BucketType _selectedBucket = BucketType.money; // Default to Money
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Bucket get _currentBucket {
    return widget.buckets.firstWhere(
      (b) => b.type == _selectedBucket,
      orElse: () => _createEmptyBucket(
        _selectedBucket,
        widget.child.id,
        widget.familyId,
      ),
    );
  }

  Future<void> _submit() async {
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      setState(() => _error = 'Amount must be greater than 0');
      return;
    }

    final currentBucket = _currentBucket;
    
    if (widget.mode == _BucketActionMode.remove && amount > currentBucket.balance) {
      setState(() => _error = "Can't remove more than current balance");
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final repo = widget.ref.read(bucketRepositoryProvider);
      final note = _noteController.text.trim().isEmpty
          ? null
          : _noteController.text.trim();

      switch (_selectedBucket) {
        case BucketType.money:
          if (widget.mode == _BucketActionMode.add) {
            await repo.addMoney(
              childId: widget.child.id,
              familyId: widget.familyId,
              amount: amount,
              performedByUid: widget.performedByUid,
              note: note,
            );
          } else {
            await repo.removeMoney(
              childId: widget.child.id,
              familyId: widget.familyId,
              amount: amount,
              performedByUid: widget.performedByUid,
              note: note,
            );
          }
          break;

        case BucketType.investment:
          // Investment uses multiply, not direct add/remove
          // For Add: use multiplier based on current balance
          // For Remove: not supported - show error
          if (widget.mode == _BucketActionMode.add) {
            if (currentBucket.balance == 0) {
              setState(() => _error = 'Investment is empty. Add money first, then multiply it.');
              setState(() => _isLoading = false);
              return;
            }
            // Calculate multiplier: (current + amount) / current
            final multiplier = (currentBucket.balance + amount) / currentBucket.balance;
            await repo.multiplyInvestment(
              childId: widget.child.id,
              familyId: widget.familyId,
              multiplier: multiplier,
              performedByUid: widget.performedByUid,
              note: note ?? 'Added ${widget.ref.read(currencyFormatterProvider).formatAmount(amount)} via multiplier',
            );
          } else {
            setState(() => _error = 'Investment can only be multiplied, not removed directly');
            setState(() => _isLoading = false);
            return;
          }
          break;

        case BucketType.charity:
          // Charity: can add (via distribute or money transfer), but removing not supported
          if (widget.mode == _BucketActionMode.add) {
            // Use distributeFunds with charity amount only
            await repo.distributeFunds(
              familyId: widget.familyId,
              childId: widget.child.id,
              moneyAmount: 0,
              investmentAmount: 0,
              charityAmount: amount,
              performedByUid: widget.performedByUid,
              note: note,
            );
          } else {
            setState(() => _error = 'Charity can only be donated (which resets to zero), not removed partially');
            setState(() => _isLoading = false);
            return;
          }
          break;
      }

      if (mounted) {
        Navigator.pop(context);
        // Show celebration for add operations
        if (widget.mode == _BucketActionMode.add) {
          final celebrationType = switch (_selectedBucket) {
            BucketType.money => CelebrationType.money,
            BucketType.investment => CelebrationType.investment,
            BucketType.charity => CelebrationType.charity,
          };
          _showCelebration(context, celebrationType);
        }
      }
    } catch (e) {
      final msg = _firestoreErrorMessage(e);
      if (mounted) {
        setState(() => _error = msg);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentBucket = _currentBucket;
    final amount = double.tryParse(_amountController.text);
    final isAmountInvalid = amount == null || amount <= 0;
    final l10n = AppLocalizations.of(context);
    final title = widget.mode == _BucketActionMode.add ? l10n.addToBucket : l10n.removeFromBucket;
    final buttonLabel = widget.mode == _BucketActionMode.add ? l10n.add : l10n.remove;

    return AlertDialog(
      title: Text(title),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Bucket selector
            Text(
              l10n.whichBucket,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            const SizedBox(height: 8),
            SegmentedButton<BucketType>(
              segments: [
                ButtonSegment(
                  value: BucketType.money,
                  label: Text('💰 ${l10n.myMoney}'),
                ),
                ButtonSegment(
                  value: BucketType.investment,
                  label: Text('📈 ${l10n.investment}'),
                ),
                ButtonSegment(
                  value: BucketType.charity,
                  label: Text('❤️ ${l10n.charity}'),
                ),
              ],
              selected: {_selectedBucket},
              onSelectionChanged: (Set<BucketType> selected) {
                setState(() {
                  _selectedBucket = selected.first;
                  _error = null;
                });
              },
            ),
            const SizedBox(height: 16),

            // Current balance
            Text(
              l10n.currentBalance(widget.ref.read(currencyFormatterProvider).formatAmount(currentBucket.balance)),
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 16),

            // Amount input
            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              autofocus: true,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                prefixText: widget.mode == _BucketActionMode.add
                    ? '+${widget.ref.read(currencyProvider).symbol}'
                    : '-${widget.ref.read(currencyProvider).symbol}',
                hintText: '0.00',
                labelText: l10n.amount,
                border: const OutlineInputBorder(),
                helperText: isAmountInvalid ? 'Amount must be greater than 0' : null,
                helperStyle: TextStyle(color: isAmountInvalid ? Colors.red : null),
              ),
            ),
            const SizedBox(height: 12),

            // Note field
            TextField(
              controller: _noteController,
              decoration: InputDecoration(
                labelText: l10n.noteOptional,
                border: const OutlineInputBorder(),
              ),
            ),

            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: const TextStyle(color: Colors.red, fontSize: 13),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: (_isLoading || isAmountInvalid) ? null : _submit,
          style: FilledButton.styleFrom(
            backgroundColor: widget.mode == _BucketActionMode.add
                ? AppTheme.primaryColor
                : Colors.orange,
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(buttonLabel),
        ),
      ],
    );
  }
}

// ─── Distribute Funds Dialog ──────────────────────────────────────────────────

class _DistributeFundsDialog extends StatefulWidget {
  const _DistributeFundsDialog({
    required this.familyId,
    required this.child,
    required this.performedByUid,
    required this.ref,
    this.onDistributed,
  });
  final String familyId;
  final Child child;
  final String performedByUid;
  final WidgetRef ref;
  final VoidCallback? onDistributed;

  @override
  State<_DistributeFundsDialog> createState() => _DistributeFundsDialogState();
}

class _DistributeFundsDialogState extends State<_DistributeFundsDialog> {
  static const double _moneyPercent = 0.70;
  static const double _investPercent = 0.20;
  static const double _charityPercent = 0.10;

  final _totalController = TextEditingController();
  final _moneyController = TextEditingController();
  final _investmentController = TextEditingController();
  final _charityController = TextEditingController();
  final _noteController = TextEditingController();
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _totalController.dispose();
    _moneyController.dispose();
    _investmentController.dispose();
    _charityController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  double get _totalAmount => double.tryParse(_totalController.text) ?? 0.0;
  double get _moneyAmount => double.tryParse(_moneyController.text) ?? 0.0;
  double get _investmentAmount => double.tryParse(_investmentController.text) ?? 0.0;
  double get _charityAmount => double.tryParse(_charityController.text) ?? 0.0;
  double get _allocatedTotal => _moneyAmount + _investmentAmount + _charityAmount;
  double get _remaining => _totalAmount - _allocatedTotal;

  bool get _moneyFilled => _moneyController.text.trim().isNotEmpty;
  bool get _investmentFilled => _investmentController.text.trim().isNotEmpty;
  bool get _charityFilled => _charityController.text.trim().isNotEmpty;
  int get _filledCount =>
      (_moneyFilled ? 1 : 0) + (_investmentFilled ? 1 : 0) + (_charityFilled ? 1 : 0);

  void _updateFields() => setState(() {});

  void _autoDistribute() {
    if (_totalAmount <= 0) return;
    final money = double.parse((_totalAmount * _moneyPercent).toStringAsFixed(2));
    final invest = double.parse((_totalAmount * _investPercent).toStringAsFixed(2));
    final charity = double.parse((_totalAmount * _charityPercent).toStringAsFixed(2));
    // Rounding remainder goes to money
    final remainder = double.parse((_totalAmount - money - invest - charity).toStringAsFixed(2));
    setState(() {
      _moneyController.text = (money + remainder).toStringAsFixed(2);
      _investmentController.text = invest.toStringAsFixed(2);
      _charityController.text = charity.toStringAsFixed(2);
    });
  }

  ({double money, double invest, double charity})? _resolvedAmounts() {
    if (_filledCount == 0) {
      // Auto-distribute
      final money = double.parse((_totalAmount * _moneyPercent).toStringAsFixed(2));
      final invest = double.parse((_totalAmount * _investPercent).toStringAsFixed(2));
      final charity = double.parse((_totalAmount * _charityPercent).toStringAsFixed(2));
      final remainder = double.parse((_totalAmount - money - invest - charity).toStringAsFixed(2));
      return (money: money + remainder, invest: invest, charity: charity);
    }

    final moneyAmt = _moneyFilled ? _moneyAmount : 0.0;
    final investAmt = _investmentFilled ? _investmentAmount : 0.0;
    final charityAmt = _charityFilled ? _charityAmount : 0.0;

    if ((_moneyFilled && moneyAmt <= 0) ||
        (_investmentFilled && investAmt <= 0) ||
        (_charityFilled && charityAmt <= 0)) {
      setState(() => _error = 'Each entered bucket amount must be greater than 0');
      return null;
    }

    // All 3 filled: sum must match total
    if (_filledCount == 3 && (moneyAmt + investAmt + charityAmt - _totalAmount).abs() > 0.005) {
      final diff = _totalAmount - (moneyAmt + investAmt + charityAmt);
      final fmt = widget.ref.read(currencyFormatterProvider);
      setState(() => _error =
          'Bucket totals must equal ${fmt.formatAmount(_totalAmount)} '
          '(${diff > 0 ? '${fmt.formatAmount(diff)} remaining' : '${fmt.formatAmount(-diff)} over'})');
      return null;
    }

    // Partial fill: must not exceed total
    if (moneyAmt + investAmt + charityAmt > _totalAmount + 0.005) {
      setState(() => _error =
          'Bucket totals exceed total by ${widget.ref.read(currencyFormatterProvider).formatAmount(moneyAmt + investAmt + charityAmt - _totalAmount)}');
      return null;
    }

    return (money: moneyAmt, invest: investAmt, charity: charityAmt);
  }

  Future<void> _submit() async {
    if (_totalAmount <= 0) {
      setState(() => _error = 'Total amount must be greater than 0');
      return;
    }

    final amounts = _resolvedAmounts();
    if (amounts == null) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final repo = widget.ref.read(bucketRepositoryProvider);
      final note = _noteController.text.trim().isEmpty ? null : _noteController.text.trim();

      await repo.distributeFunds(
        familyId: widget.familyId,
        childId: widget.child.id,
        moneyAmount: amounts.money,
        investmentAmount: amounts.invest,
        charityAmount: amounts.charity,
        performedByUid: widget.performedByUid,
        note: note,
      );

      if (mounted) {
        Navigator.pop(context);
        widget.onDistributed?.call();
        _showCelebration(context, CelebrationType.money);
      }
    } catch (e) {
      final msg = _firestoreErrorMessage(e);
      if (mounted) {
        setState(() => _error = msg);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: Colors.red.shade700),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasTotal = _totalAmount > 0;
    final l10n = AppLocalizations.of(context);
    final currencySymbol = widget.ref.read(currencyProvider).symbol;

    return AlertDialog(
      title: Text(l10n.addFundsFor(widget.child.displayName)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.totalAmount,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _totalController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              autofocus: true,
              onChanged: (_) => _updateFields(),
              decoration: InputDecoration(
                prefixText: currencySymbol,
                hintText: '0.00',
                labelText: l10n.totalAmount,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),

            Text(
              l10n.perBucketOptional,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: _moneyController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              onChanged: (_) => _updateFields(),
              decoration: InputDecoration(
                prefixText: currencySymbol,
                hintText: '0.00',
                labelText: '💰 ${l10n.myMoney}',
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: _investmentController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              onChanged: (_) => _updateFields(),
              decoration: InputDecoration(
                prefixText: currencySymbol,
                hintText: '0.00',
                labelText: '📈 ${l10n.investment}',
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: _charityController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              onChanged: (_) => _updateFields(),
              decoration: InputDecoration(
                prefixText: currencySymbol,
                hintText: '0.00',
                labelText: '❤️ ${l10n.charity}',
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),

            // Remaining indicator
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _remaining == 0
                    ? Colors.green.shade50
                    : _remaining > 0
                        ? Colors.orange.shade50
                        : Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _remaining == 0
                      ? Colors.green.shade300
                      : _remaining > 0
                          ? Colors.orange.shade300
                          : Colors.red.shade300,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.remaining,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    '${widget.ref.read(currencyFormatterProvider).formatAmount(_remaining.abs())}'
                    '${_remaining > 0 ? ' left' : _remaining < 0 ? ' over' : ' ✓'}',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: _remaining == 0
                          ? Colors.green.shade700
                          : _remaining > 0
                              ? Colors.orange.shade700
                              : Colors.red.shade700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _noteController,
              decoration: InputDecoration(
                labelText: l10n.noteOptional,
                border: const OutlineInputBorder(),
              ),
            ),

            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: const TextStyle(color: Colors.red, fontSize: 13),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        OutlinedButton(
          onPressed: (_isLoading || !hasTotal) ? null : _autoDistribute,
          child: Text(l10n.autoDistribute),
        ),
        FilledButton(
          onPressed: (_isLoading || !hasTotal) ? null : _submit,
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : Text(l10n.addFunds),
        ),
      ],
    );
  }
}

// ─── Edit Child Dialog ────────────────────────────────────────────────────────

class _EditChildDialog extends StatefulWidget {
  const _EditChildDialog({
    required this.familyId,
    required this.child,
    required this.ref,
  });
  final String familyId;
  final Child child;
  final WidgetRef ref;

  @override
  State<_EditChildDialog> createState() => _EditChildDialogState();
}

class _EditChildDialogState extends State<_EditChildDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _emojiController;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.child.displayName);
    _emojiController = TextEditingController(text: widget.child.avatarEmoji);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emojiController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    final emoji = _emojiController.text.trim();

    if (name.isEmpty) {
      setState(() => _error = 'Please enter a name');
      return;
    }

    if (emoji.isEmpty) {
      setState(() => _error = 'Please enter an emoji');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final repo = widget.ref.read(childRepositoryProvider);
      
      await repo.updateChild(
        childId: widget.child.id,
        familyId: widget.familyId,
        name: name != widget.child.displayName ? name : null,
        avatarEmoji: emoji != widget.child.avatarEmoji ? emoji : null,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).save),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      final msg = _firestoreErrorMessage(e);
      if (mounted) {
        setState(() => _error = msg);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _showArchiveConfirmation() async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${l10n.archiveChild}?'),
        content: Text(
          "${l10n.areYouSure} ${widget.child.displayName}'s data will be preserved but they'll be removed from your family.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: Text(l10n.archiveChild),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await _archiveChild();
    }
  }

  Future<void> _archiveChild() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final repo = widget.ref.read(childRepositoryProvider);
      await repo.archiveChild(
        familyId: widget.familyId,
        childId: widget.child.id,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).childHasBeenArchived(widget.child.displayName)),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      final msg = _firestoreErrorMessage(e);
      if (mounted) {
        setState(() => _error = msg);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.editChild),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: l10n.displayName,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _emojiController,
              decoration: InputDecoration(
                labelText: l10n.avatar,
                border: const OutlineInputBorder(),
                hintText: '🦁',
              ),
            ),
            const SizedBox(height: 16),

            const Divider(),
            const SizedBox(height: 8),

            // Archive button
            TextButton.icon(
              onPressed: _isLoading ? null : _showArchiveConfirmation,
              icon: const Icon(Icons.archive_outlined, color: Colors.red),
              label: Text(
                l10n.archiveChild,
                style: const TextStyle(color: Colors.red),
              ),
            ),

            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: const TextStyle(color: Colors.red, fontSize: 13),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: _isLoading ? null : _submit,
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(l10n.save),
        ),
      ],
    );
  }
}

// ─── Family Settings Dialog ────────────────────────────────────────────────────

void _showFamilySettingsDialog(BuildContext context, WidgetRef ref, String familyId) {
  final l10n = AppLocalizations.of(context);
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          const Icon(Icons.group_add, color: Colors.deepPurple),
          const SizedBox(width: 8),
          Text(l10n.inviteParent),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.shareFamilyCode,
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 8),
          const Text(
            'They must sign up first, then enter this code.',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.deepPurple.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.deepPurple.shade200),
            ),
            child: Column(
              children: [
                Text(
                  l10n.familyCode,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 4),
                SelectableText(
                  familyId,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: Text(l10n.back),
        ),
      ],
    ),
  );
}

// ─── Celebration Overlay Helper ────────────────────────────────────────────────

void _showCelebration(BuildContext context, CelebrationType type) {
  Navigator.of(context).push(
    PageRouteBuilder(
      opaque: false,
      barrierDismissible: true,
      barrierColor: Colors.transparent,
      pageBuilder: (ctx, _, __) => CelebrationOverlay(
        type: type,
        onComplete: () => Navigator.of(ctx).pop(),
      ),
    ),
  );
}

