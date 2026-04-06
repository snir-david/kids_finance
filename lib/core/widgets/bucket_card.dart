import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../features/buckets/domain/bucket.dart';
import '../theme/app_theme.dart';

class BucketCard extends StatelessWidget {
  const BucketCard({
    super.key,
    required this.bucket,
    required this.isKidMode,
    this.onTap,
  });

  final Bucket bucket;
  final bool isKidMode;
  final VoidCallback? onTap;

  Color _getBucketColor() {
    switch (bucket.type) {
      case BucketType.money:
        return AppTheme.moneyColor;
      case BucketType.investment:
        return AppTheme.investmentsColor;
      case BucketType.charity:
        return AppTheme.charityColor;
    }
  }

  String _getBucketEmoji() {
    switch (bucket.type) {
      case BucketType.money:
        return '💰';
      case BucketType.investment:
        return '📈';
      case BucketType.charity:
        return '❤️';
    }
  }

  String _getBucketLabel() {
    switch (bucket.type) {
      case BucketType.money:
        return 'Money';
      case BucketType.investment:
        return 'Investments';
      case BucketType.charity:
        return 'Charity';
    }
  }

  String _formatBalance(double balance) {
    final formatter = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    return formatter.format(balance);
  }

  @override
  Widget build(BuildContext context) {
    final color = _getBucketColor();
    final emoji = _getBucketEmoji();
    final label = _getBucketLabel();
    final balanceText = _formatBalance(bucket.balance);

    if (isKidMode) {
      // Kid Mode: big card, large emoji (64px), bold balance, rounded corners, animated
      return Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  color.withValues(alpha: 0.1),
                  color.withValues(alpha: 0.05),
                ],
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  emoji,
                  style: const TextStyle(fontSize: 64),
                ),
                const SizedBox(height: 16),
                Text(
                  balanceText,
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        color: color,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  label,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.black54,
                      ),
                ),
              ],
            ),
          ),
        ),
      ).animate().fadeIn(duration: 300.ms).scale(
            begin: const Offset(0.9, 0.9),
            end: const Offset(1.0, 1.0),
            duration: 300.ms,
          );
    } else {
      // Parent Mode: compact card, smaller emoji, balance + label, less rounding
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: color.withValues(alpha: 0.3),
                width: 2,
              ),
            ),
            child: Row(
              children: [
                Text(
                  emoji,
                  style: const TextStyle(fontSize: 36),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        label,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: Colors.black87,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        balanceText,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: color,
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: color,
                  size: 28,
                ),
              ],
            ),
          ),
        ),
      );
    }
  }
}
