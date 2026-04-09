import 'package:flutter/material.dart' hide Badge;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../data/models/badge_model.dart';
import '../providers/badges_provider.dart';
import '../widgets/badge_chip.dart';
import '../widgets/badge_detail_sheet.dart';

const _kAllBadgeTypes = [
  BadgeType.firstDeposit,
  BadgeType.generousHeart,
  BadgeType.youngInvestor,
  BadgeType.goalGetter,
  BadgeType.saver,
  BadgeType.streak,
];

/// Full-screen view of all 6 achievement badges for a child.
///
/// Earned badges are shown in full color; unearned ones are locked.
/// Tapping any badge opens the [BadgeDetailSheet].
class BadgesScreen extends ConsumerWidget {
  const BadgesScreen({
    super.key,
    required this.familyId,
    required this.childId,
  });

  final String familyId;
  final String childId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final badgesAsync = ref.watch(
      badgesProvider((familyId: familyId, childId: childId)),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.allBadgesTitle),
        centerTitle: true,
      ),
      body: badgesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (earnedBadges) {
          final earnedCount = earnedBadges.length;

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                  child: _BadgeSummaryBanner(
                    earned: earnedCount,
                    total: _kAllBadgeTypes.length,
                    l10n: l10n,
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverGrid.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 0.85,
                  children: _kAllBadgeTypes.map((type) {
                    final badge = earnedBadges.cast<Badge?>().firstWhere(
                          (b) => b?.type == type,
                          orElse: () => null,
                        );
                    return _BadgeCard(
                      type: type,
                      badge: badge,
                      familyId: familyId,
                      childId: childId,
                    );
                  }).toList(),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _BadgeSummaryBanner extends StatelessWidget {
  const _BadgeSummaryBanner({
    required this.earned,
    required this.total,
    required this.l10n,
  });

  final int earned;
  final int total;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final progress = total > 0 ? earned / total : 0.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🏅', style: TextStyle(fontSize: 28)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$earned / $total ${l10n.badgesEarned}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: colorScheme.onPrimaryContainer,
                          ),
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 8,
                        backgroundColor: colorScheme.outline.withValues(alpha: 0.2),
                        color: colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BadgeCard extends StatelessWidget {
  const _BadgeCard({
    required this.type,
    required this.familyId,
    required this.childId,
    this.badge,
  });

  final BadgeType type;
  final String familyId;
  final String childId;
  final Badge? badge;

  bool get _isEarned => badge != null;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final emoji = badgeEmoji(type);
    final name = badgeLocalizedName(l10n, type);
    final description = badgeLocalizedDescription(l10n, type);

    return GestureDetector(
      onTap: () => showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (_) => BadgeDetailSheet(
          type: type,
          familyId: familyId,
          childId: childId,
          badge: badge,
        ),
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          color: _isEarned
              ? colorScheme.surfaceContainerHighest
              : colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _isEarned
                ? colorScheme.primary.withValues(alpha: 0.35)
                : colorScheme.outline.withValues(alpha: 0.15),
            width: 1.5,
          ),
          boxShadow: _isEarned
              ? [
                  BoxShadow(
                    color: colorScheme.primary.withValues(alpha: 0.12),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Emoji with lock overlay when not earned
              Stack(
                alignment: Alignment.center,
                children: [
                  ColorFiltered(
                    colorFilter: _isEarned
                        ? const ColorFilter.matrix([
                            1, 0, 0, 0, 0,
                            0, 1, 0, 0, 0,
                            0, 0, 1, 0, 0,
                            0, 0, 0, 1, 0,
                          ])
                        : const ColorFilter.matrix([
                            0.2126, 0.7152, 0.0722, 0, 0,
                            0.2126, 0.7152, 0.0722, 0, 0,
                            0.2126, 0.7152, 0.0722, 0, 0,
                            0,      0,      0,      0.4, 0,
                          ]),
                    child: Text(emoji, style: const TextStyle(fontSize: 44)),
                  ),
                  if (!_isEarned)
                    const Positioned(
                      bottom: 0,
                      right: 0,
                      child: Text('🔒', style: TextStyle(fontSize: 18)),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                name,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: _isEarned
                          ? colorScheme.onSurface
                          : colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                    ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                _isEarned
                    ? '✅ ${_formatDate(badge!.earnedAt)}'
                    : description,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: _isEarned
                          ? colorScheme.primary
                          : colorScheme.onSurfaceVariant.withValues(alpha: 0.45),
                    ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
}
