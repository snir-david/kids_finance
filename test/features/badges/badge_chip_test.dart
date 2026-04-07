// Widget tests for BadgeChip and BadgeShelf components.
//
// Local widget stubs are defined below so these tests run immediately, before
// Rhodey ships lib/features/badges/presentation/widgets/.
// The stubs are intentionally minimal and serve as a behavioural spec.
//
// TODO: Once the real widgets land in lib/, remove the local stubs and replace:
//   import 'package:kids_finance/features/badges/presentation/widgets/badge_chip.dart';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'badge_test_stubs.dart';

// ── Local BadgeChip stub ──────────────────────────────────────────────────────
//
// Behavioural spec for Rhodey's real BadgeChip widget:
// - Shows the badge emoji when earned=true
// - Shows a 🔒 overlay when earned=false
// - Fires onTap when tapped

class BadgeChip extends StatelessWidget {
  final BadgeType type;
  final bool earned;
  final VoidCallback? onTap;

  const BadgeChip({
    super.key,
    required this.type,
    required this.earned,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Text(type.emoji, key: Key('emoji-${type.name}')),
          if (!earned)
            const Text('🔒', key: Key('lock-overlay')),
        ],
      ),
    );
  }
}

// ── Local BadgeShelf stub ─────────────────────────────────────────────────────
//
// Behavioural spec: renders one BadgeChip slot for every BadgeType value (6
// total), earned or not depending on the earnedBadges set.

class BadgeShelf extends StatelessWidget {
  final Set<BadgeType> earnedBadges;

  const BadgeShelf({super.key, required this.earnedBadges});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      children: BadgeType.values
          .map(
            (type) => BadgeChip(
              key: Key('chip-${type.name}'),
              type: type,
              earned: earnedBadges.contains(type),
            ),
          )
          .toList(),
    );
  }
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  // ── BadgeChip ──────────────────────────────────────────────────────────────

  group('BadgeChip widget', () {
    testWidgets('shows badge emoji for an earned badge', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: BadgeChip(
              type: BadgeType.firstDeposit,
              earned: true,
            ),
          ),
        ),
      );

      expect(find.text('🏦'), findsOneWidget);
      expect(find.byKey(const Key('lock-overlay')), findsNothing);
    });

    testWidgets('shows emoji and 🔒 overlay for an unearned badge',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: BadgeChip(
              type: BadgeType.goalGetter,
              earned: false,
            ),
          ),
        ),
      );

      expect(find.text('🏆'), findsOneWidget,
          reason: 'Unearned chip should still render the badge emoji');
      expect(find.byKey(const Key('lock-overlay')), findsOneWidget,
          reason: '🔒 overlay must be present for unearned badges');
    });

    testWidgets('calls onTap callback when tapped', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BadgeChip(
              type: BadgeType.saver,
              earned: true,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(BadgeChip));
      expect(tapped, isTrue);
    });

    testWidgets('earned badge has no lock overlay', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: BadgeChip(
              type: BadgeType.youngInvestor,
              earned: true,
            ),
          ),
        ),
      );

      expect(find.byKey(const Key('lock-overlay')), findsNothing);
    });
  });

  // ── BadgeShelf ─────────────────────────────────────────────────────────────

  group('BadgeShelf widget', () {
    testWidgets('shows all 6 badge slots', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: BadgeShelf(earnedBadges: {}),
          ),
        ),
      );

      expect(find.byType(BadgeChip), findsNWidgets(6),
          reason: 'BadgeShelf must render one slot per BadgeType (6 total)');
    });

    testWidgets('earned badges do not show lock overlay', (tester) async {
      const earned = {BadgeType.firstDeposit, BadgeType.saver};
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: BadgeShelf(earnedBadges: earned),
          ),
        ),
      );

      // 4 unearned badges should each have a lock overlay
      expect(find.byKey(const Key('lock-overlay')), findsNWidgets(4));
    });

    testWidgets('all slots are locked when no badges are earned',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: BadgeShelf(earnedBadges: {}),
          ),
        ),
      );

      expect(find.byKey(const Key('lock-overlay')), findsNWidgets(6));
    });

    testWidgets('no lock overlays when all badges are earned', (tester) async {
      final allEarned = BadgeType.values.toSet();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BadgeShelf(earnedBadges: allEarned),
          ),
        ),
      );

      expect(find.byKey(const Key('lock-overlay')), findsNothing);
    });
  });
}
