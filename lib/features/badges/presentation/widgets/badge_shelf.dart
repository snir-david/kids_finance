import 'package:flutter/material.dart' hide Badge;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../data/models/badge_model.dart';
import '../providers/badges_provider.dart';
import 'badge_chip.dart';

/// Ordered list of all badge types shown on the shelf.
const _kAllBadgeTypes = [
  BadgeType.firstDeposit,
  BadgeType.generousHeart,
  BadgeType.youngInvestor,
  BadgeType.goalGetter,
  BadgeType.saver,
  BadgeType.streak,
];

/// Horizontally scrolling shelf showing all 6 badge types.
///
/// Earned badges appear in full color; unearned ones are locked.
/// Shows a section header "My Badges" and an empty-state hint when none earned.
class BadgeShelf extends ConsumerWidget {
  const BadgeShelf({
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Row(
          children: [
            const Text('🏅', style: TextStyle(fontSize: 24)),
            const SizedBox(width: 8),
            Text(
              l10n.myBadges,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        badgesAsync.when(
          data: (earnedBadges) {
            final hasAny = earnedBadges.isNotEmpty;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 110,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    itemCount: _kAllBadgeTypes.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      final type = _kAllBadgeTypes[index];
                      // Find the earned badge for this type, if any.
                      final badge = earnedBadges.cast<Badge?>().firstWhere(
                            (b) => b?.type == type,
                            orElse: () => null,
                          );
                      return BadgeChip(
                        type: type,
                        familyId: familyId,
                        childId: childId,
                        badge: badge,
                      );
                    },
                  ),
                ),
                if (!hasAny) ...[
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      l10n.completeActionsToUnlock,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ],
            );
          },
          loading: () => const SizedBox(
            height: 110,
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (_, __) => const SizedBox.shrink(),
        ),
      ],
    );
  }
}
