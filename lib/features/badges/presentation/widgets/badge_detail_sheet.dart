import 'package:flutter/material.dart' hide Badge;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../data/models/badge_model.dart';
import '../../data/repositories/badge_repository_provider.dart';
import 'badge_chip.dart';

/// Bottom sheet showing badge details.
///
/// Displays the large emoji, badge name, description, and earn date (if earned).
/// Automatically calls [BadgeRepository.markSeen] when opened for unseen earned badges.
class BadgeDetailSheet extends ConsumerStatefulWidget {
  const BadgeDetailSheet({
    super.key,
    required this.type,
    required this.familyId,
    required this.childId,
    this.badge,
  });

  final BadgeType type;
  final String familyId;
  final String childId;

  /// Non-null when this badge has been earned.
  final Badge? badge;

  @override
  ConsumerState<BadgeDetailSheet> createState() => _BadgeDetailSheetState();
}

class _BadgeDetailSheetState extends ConsumerState<BadgeDetailSheet> {
  @override
  void initState() {
    super.initState();
    // Mark as seen when the sheet opens (only for earned, unseen badges).
    if (widget.badge != null && !widget.badge!.seen) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ref
            .read(badgeRepositoryProvider)
            .markSeen(widget.familyId, widget.childId, widget.badge!.id);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final isEarned = widget.badge != null;
    final emoji = badgeEmoji(widget.type);
    final name = badgeLocalizedName(l10n, widget.type);
    final description = badgeLocalizedDescription(l10n, widget.type);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),

            // Large emoji
            Text(emoji, style: const TextStyle(fontSize: 72)),
            const SizedBox(height: 16),

            // Badge name
            Text(
              name,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: colorScheme.onSurface,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),

            // Description
            Text(
              description,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),

            // Earned date OR locked message
            if (isEarned) ...[
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  l10n.earnedOnDate(_formatDate(widget.badge!.earnedAt)),
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ] else ...[
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('🔒', style: TextStyle(fontSize: 16)),
                    const SizedBox(width: 8),
                    Text(
                      l10n.keepGoingToUnlock,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Close button
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(isEarned ? l10n.awesome : l10n.cancel),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
