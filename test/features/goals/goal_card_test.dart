// Widget tests for the GoalCard component.
//
// A local GoalCard stub is defined below so these tests run immediately,
// before Rhodey ships lib/features/goals/presentation/widgets/goal_card.dart.
// The stub is intentionally minimal and serves as a behavioural spec.
//
// TODO: Once GoalCard lands in lib/, remove the local stub and replace with:
//   import 'package:kids_finance/features/goals/presentation/widgets/goal_card.dart';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'goal_test_stubs.dart';

// ── Local GoalCard stub ───────────────────────────────────────────────────────
//
// Implements the minimum expected API and rendering behaviour.
// Rhodey's real GoalCard must satisfy all assertions below.

class GoalCard extends StatelessWidget {
  final Goal goal;
  final VoidCallback? onTap;

  const GoalCard({super.key, required this.goal, this.onTap});

  @override
  Widget build(BuildContext context) {
    final isCompleted = goal.completedAt != null;
    final percent = goal.targetAmount > 0
        ? (goal.balance / goal.targetAmount).clamp(0.0, 1.0)
        : 0.0;
    final remaining =
        (goal.targetAmount - goal.balance).clamp(0.0, double.infinity);

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(goal.name),
          LinearProgressIndicator(value: percent),
          if (isCompleted)
            const Text('Goal Reached!')
          else
            Text('\$${remaining.toStringAsFixed(2)} remaining'),
        ],
      ),
    );
  }
}

// ── Test helper ───────────────────────────────────────────────────────────────

Goal makeGoal({
  String name = 'New Bike',
  double targetAmount = 100.0,
  double balance = 0.0,
  DateTime? completedAt,
}) =>
    Goal(
      id: 'goal-1',
      familyId: 'family-1',
      childId: 'child-1',
      name: name,
      targetAmount: targetAmount,
      balance: balance,
      completedAt: completedAt,
      createdAt: DateTime(2026, 4, 7),
    );

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  group('GoalCard widget', () {
    testWidgets('shows goal name', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GoalCard(goal: makeGoal(name: 'Skateboard')),
          ),
        ),
      );

      expect(find.text('Skateboard'), findsOneWidget);
    });

    testWidgets('shows progress bar at 0% when balance is 0', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GoalCard(
              goal: makeGoal(targetAmount: 100.0, balance: 0.0),
            ),
          ),
        ),
      );

      final bar = tester
          .widget<LinearProgressIndicator>(find.byType(LinearProgressIndicator));
      expect(bar.value, equals(0.0));
    });

    testWidgets('shows progress bar at 50% when balance is half target',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GoalCard(
              goal: makeGoal(targetAmount: 100.0, balance: 50.0),
            ),
          ),
        ),
      );

      final bar = tester
          .widget<LinearProgressIndicator>(find.byType(LinearProgressIndicator));
      expect(bar.value, equals(0.5));
    });

    testWidgets('shows progress bar at 100% when goal is completed',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GoalCard(
              goal: makeGoal(
                targetAmount: 100.0,
                balance: 100.0,
                completedAt: DateTime(2026, 4, 7),
              ),
            ),
          ),
        ),
      );

      final bar = tester
          .widget<LinearProgressIndicator>(find.byType(LinearProgressIndicator));
      expect(bar.value, equals(1.0));
    });

    testWidgets('shows "Goal Reached!" when goal is completed', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GoalCard(
              goal: makeGoal(
                targetAmount: 100.0,
                balance: 100.0,
                completedAt: DateTime(2026, 4, 7),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Goal Reached!'), findsOneWidget);
    });

    testWidgets('shows correct amount remaining when goal is not complete',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GoalCard(
              goal: makeGoal(targetAmount: 100.0, balance: 60.0),
            ),
          ),
        ),
      );

      // $40.00 = targetAmount(100) - balance(60)
      expect(find.text('\$40.00 remaining'), findsOneWidget);
    });

    testWidgets('calls onTap callback when tapped', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GoalCard(
              goal: makeGoal(),
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(GoalCard));
      expect(tapped, isTrue);
    });
  });
}
