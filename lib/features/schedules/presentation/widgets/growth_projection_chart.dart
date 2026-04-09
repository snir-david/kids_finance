import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/currency/currency_formatter.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/multiply_rule_model.dart';

/// Displays a projected investment balance over 12 periods based on the
/// most-favourable active multiply rule.
class GrowthProjectionChart extends StatelessWidget {
  const GrowthProjectionChart({
    super.key,
    required this.currentBalance,
    required this.rules,
    required this.formatter,
  });

  final double currentBalance;
  final List<MultiplyRule> rules;
  final CurrencyFormatter formatter;

  static const _periods = 12;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    final activeRules = rules.where((r) => r.isActive).toList();
    if (activeRules.isEmpty || currentBalance <= 0) return const SizedBox.shrink();

    // Use the rule with the highest effective factor for projection.
    final rule = activeRules.reduce(
      (a, b) => a.multiplierPercent > b.multiplierPercent ? a : b,
    );

    final points = List.generate(
      _periods + 1,
      (i) => currentBalance * math.pow(rule.factor, i),
    );

    final finalBalance = points.last;

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 10),
      decoration: BoxDecoration(
        color: AppTheme.investmentsColor.withAlpha(15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.investmentsColor.withAlpha(60)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('📈', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 6),
              Text(
                l10n.growthProjection,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.investmentsColor,
                    ),
              ),
              const Spacer(),
              Text(
                l10n.projectionMonths,
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${l10n.growsBy(rule.multiplierPercent.toStringAsFixed(1), l10n.frequencyLabel(rule.frequency.name))}',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 100,
            child: CustomPaint(
              painter: _ChartPainter(
                points: points,
                color: AppTheme.investmentsColor,
              ),
              size: Size.infinite,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _Label(label: l10n.now_, value: formatter.formatAmount(currentBalance)),
              _Label(
                label: l10n.projectedBalance,
                value: formatter.formatAmount(finalBalance),
                highlight: true,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label({required this.label, required this.value, this.highlight = false});
  final String label;
  final String value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          highlight ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: highlight ? AppTheme.investmentsColor : null,
          ),
        ),
      ],
    );
  }
}

class _ChartPainter extends CustomPainter {
  _ChartPainter({required this.points, required this.color});
  final List<double> points;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    final minVal = points.reduce(math.min);
    final maxVal = points.reduce(math.max);
    final range = (maxVal - minVal).clamp(1.0, double.infinity);

    double px(int i) => i * size.width / (points.length - 1);
    double py(double v) =>
        size.height - ((v - minVal) / range) * size.height * 0.85 - size.height * 0.05;

    // Gradient fill
    final path = Path()..moveTo(px(0), py(points[0]));
    for (int i = 1; i < points.length; i++) {
      final cp1x = (px(i - 1) + px(i)) / 2;
      path.cubicTo(cp1x, py(points[i - 1]), cp1x, py(points[i]), px(i), py(points[i]));
    }
    path.lineTo(px(points.length - 1), size.height);
    path.lineTo(0, size.height);
    path.close();

    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [color.withAlpha(80), color.withAlpha(10)],
    );
    canvas.drawPath(
      path,
      Paint()
        ..shader = gradient.createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );

    // Line
    final linePath = Path()..moveTo(px(0), py(points[0]));
    for (int i = 1; i < points.length; i++) {
      final cp1x = (px(i - 1) + px(i)) / 2;
      linePath.cubicTo(cp1x, py(points[i - 1]), cp1x, py(points[i]), px(i), py(points[i]));
    }
    canvas.drawPath(
      linePath,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round,
    );

    // Dots at start and end
    for (final i in [0, points.length - 1]) {
      canvas.drawCircle(
        Offset(px(i), py(points[i])),
        4,
        Paint()..color = color,
      );
    }
  }

  @override
  bool shouldRepaint(_ChartPainter old) =>
      old.points != points || old.color != color;
}
