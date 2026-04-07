import 'package:flutter/material.dart' hide Badge;
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../data/models/badge_model.dart';
import 'badge_detail_sheet.dart';

/// Maps BadgeType → emoji string (mirrors Badge.emoji getter).
String badgeEmoji(BadgeType type) {
  switch (type) {
    case BadgeType.firstDeposit:
      return '🌱';
    case BadgeType.generousHeart:
      return '💚';
    case BadgeType.youngInvestor:
      return '📈';
    case BadgeType.goalGetter:
      return '🎯';
    case BadgeType.saver:
      return '💰';
    case BadgeType.streak:
      return '🔥';
  }
}

/// Returns the localized badge name for a given [type].
String badgeLocalizedName(AppLocalizations l10n, BadgeType type) {
  switch (type) {
    case BadgeType.firstDeposit:
      return l10n.badgeNameFirstDeposit;
    case BadgeType.generousHeart:
      return l10n.badgeNameGenerousHeart;
    case BadgeType.youngInvestor:
      return l10n.badgeNameYoungInvestor;
    case BadgeType.goalGetter:
      return l10n.badgeNameGoalGetter;
    case BadgeType.saver:
      return l10n.badgeNameSaver;
    case BadgeType.streak:
      return l10n.badgeNameStreak;
  }
}

/// Returns the localized badge description for a given [type].
String badgeLocalizedDescription(AppLocalizations l10n, BadgeType type) {
  switch (type) {
    case BadgeType.firstDeposit:
      return l10n.badgeDescFirstDeposit;
    case BadgeType.generousHeart:
      return l10n.badgeDescGenerousHeart;
    case BadgeType.youngInvestor:
      return l10n.badgeDescYoungInvestor;
    case BadgeType.goalGetter:
      return l10n.badgeDescGoalGetter;
    case BadgeType.saver:
      return l10n.badgeDescSaver;
    case BadgeType.streak:
      return l10n.badgeDescStreak;
  }
}

/// A small circular chip showing a badge's emoji and name.
///
/// Earned badges appear in full color with an animated scale-bounce entrance.
/// Locked badges are greyed out with a 🔒 overlay. Tapping opens [BadgeDetailSheet].
class BadgeChip extends ConsumerWidget {
  const BadgeChip({
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

  bool get _isEarned => badge != null;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final name = badgeLocalizedName(l10n, type);
    final emoji = badgeEmoji(type);

    Widget chipContent = GestureDetector(
      onTap: () => _openDetailSheet(context),
      child: SizedBox(
        width: 80,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: _isEarned
                    ? colorScheme.surfaceContainerHighest
                    : colorScheme.surfaceContainerLow,
                shape: BoxShape.circle,
                border: Border.all(
                  color: _isEarned
                      ? colorScheme.primary.withValues(alpha: 0.4)
                      : colorScheme.outline.withValues(alpha: 0.2),
                  width: 2,
                ),
                boxShadow: _isEarned
                    ? [
                        BoxShadow(
                          color: colorScheme.primary.withValues(alpha: 0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              alignment: Alignment.center,
              child: _isEarned
                  ? Text(emoji, style: const TextStyle(fontSize: 32))
                  : Stack(
                      alignment: Alignment.center,
                      children: [
                        ColorFiltered(
                          colorFilter: const ColorFilter.matrix([
                            0.2126, 0.7152, 0.0722, 0, 0,
                            0.2126, 0.7152, 0.0722, 0, 0,
                            0.2126, 0.7152, 0.0722, 0, 0,
                            0,      0,      0,      1, 0,
                          ]),
                          child: Opacity(
                            opacity: 0.4,
                            child: Text(emoji,
                                style: const TextStyle(fontSize: 28)),
                          ),
                        ),
                        const Text('🔒', style: TextStyle(fontSize: 18)),
                      ],
                    ),
            ),
            const SizedBox(height: 6),
            Text(
              name,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: _isEarned
                        ? colorScheme.onSurface
                        : colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                    fontWeight:
                        _isEarned ? FontWeight.w600 : FontWeight.w400,
                  ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );

    if (_isEarned) {
      chipContent = chipContent
          .animate()
          .scale(
            begin: const Offset(0.5, 0.5),
            end: const Offset(1.0, 1.0),
            duration: const Duration(milliseconds: 400),
            curve: Curves.elasticOut,
          )
          .fadeIn(duration: const Duration(milliseconds: 200));
    }

    return chipContent;
  }

  void _openDetailSheet(BuildContext context) {
    showModalBottomSheet<void>(
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
    );
  }
}
