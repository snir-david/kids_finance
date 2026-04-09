import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/tooltips/tooltip_provider.dart';

/// Animated tip card shown above a bucket until the child dismisses it.
class BucketTooltipCard extends ConsumerWidget {
  const BucketTooltipCard({
    super.key,
    required this.tooltipKey,
    required this.color,
  });

  final String tooltipKey;
  final Color color;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dismissed = ref.watch(
      tooltipProvider.select((s) => s.contains(tooltipKey)),
    );

    final l10n = AppLocalizations.of(context);
    final (title, body) = _content(l10n);

    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      child: dismissed
          ? const SizedBox.shrink()
          : _TooltipContent(
              tooltipKey: tooltipKey,
              color: color,
              title: title,
              body: body,
              dismissLabel: l10n.tooltipDismiss,
            ),
    );
  }

  (String, String) _content(AppLocalizations l10n) => switch (tooltipKey) {
        kTooltipMoney => (l10n.tooltipMoneyTitle, l10n.tooltipMoneyBody),
        kTooltipInvestment =>
          (l10n.tooltipInvestmentTitle, l10n.tooltipInvestmentBody),
        kTooltipCharity =>
          (l10n.tooltipCharityTitle, l10n.tooltipCharityBody),
        _ => ('', ''),
      };
}

class _TooltipContent extends ConsumerWidget {
  const _TooltipContent({
    required this.tooltipKey,
    required this.color,
    required this.title,
    required this.body,
    required this.dismissLabel,
  });

  final String tooltipKey;
  final Color color;
  final String title;
  final String body;
  final String dismissLabel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bg = color.withAlpha(30);
    final border = color.withAlpha(80);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: border, width: 1.5),
        ),
        padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: color.withAlpha(220),
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    body,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          height: 1.4,
                        ),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () =>
                        ref.read(tooltipProvider.notifier).dismiss(tooltipKey),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: color.withAlpha(200),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        dismissLabel,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
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
