import 'package:flutter/material.dart';
import '../../data/models/goal_model.dart';
import '../../../../../core/l10n/app_localizations.dart';

class GoalCard extends StatelessWidget {
  const GoalCard({
    super.key,
    required this.goal,
    required this.currentBalance,
    this.onTap,
  });

  final Goal goal;

  /// The child's My Money bucket balance, used to compute progress.
  final double currentBalance;

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isCompleted = goal.isCompleted;
    final progress = goal.progressPercent(currentBalance);
    final remaining = (goal.targetAmount - currentBalance).clamp(0.0, double.infinity);

    final cardColor = isCompleted
        ? (isDark ? Colors.green.shade900 : Colors.green.shade100)
        : Theme.of(context).colorScheme.surfaceContainerHighest;

    final borderColor = isCompleted
        ? Colors.green.withValues(alpha: 0.5)
        : Theme.of(context).colorScheme.outline.withValues(alpha: 0.3);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row: name + completion badge
            Row(
              children: [
                Expanded(
                  child: Text(
                    goal.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                  ),
                ),
                if (isCompleted)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.check_circle,
                            color: Colors.white, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          l10n.goalReached,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 10),

            // Progress bar
            LinearProgressIndicator(
              value: progress,
              backgroundColor:
                  Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(Colors.green),
              borderRadius: BorderRadius.circular(4),
              minHeight: 8,
            ),

            const SizedBox(height: 8),

            // Amount label row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isCompleted
                      ? '🎉 ${l10n.goalReached}'
                      : '${currentBalance.toStringAsFixed(0)}₪ / ${goal.targetAmount.toStringAsFixed(0)}₪',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isCompleted
                            ? Colors.green
                            : Theme.of(context).colorScheme.onSurface,
                      ),
                ),
                if (!isCompleted)
                  Text(
                    '${remaining.toStringAsFixed(0)}₪ ${l10n.toGo}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color:
                              Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
