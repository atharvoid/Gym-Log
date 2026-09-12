import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymlog/features/auth/presentation/providers/onboarding_draft_provider.dart';
import 'package:gymlog/features/auth/presentation/widgets/onboarding/step_weekly_goal.dart';
import 'package:gymlog/shared/widgets/ui/goal_ring.dart';

void main() {
  Future<void> pumpWeeklyGoalStep(
    WidgetTester tester, {
    int? goal,
  }) async {
    final notifier = OnboardingDraftNotifier();
    if (goal != null) notifier.updateWeeklyGoal(goal);

    await tester.pumpWidget(
      ProviderScope(
        key: UniqueKey(),
        overrides: [
          onboardingDraftProvider.overrideWith((ref) => notifier),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: StepWeeklyGoal(onNext: _noop),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  Future<void> tapGoalSegment(WidgetTester tester, int days) async {
    await tester.tap(find.text('$days'));
    await tester.pump();
  }

  String ringLabel(WidgetTester tester) =>
      tester.getSemantics(find.byType(GoalRing)).label;

  group('StepWeeklyGoal preview consistency', () {
    testWidgets('goal 1 previews 1 of 1 workout completed at 100%',
        (tester) async {
      await pumpWeeklyGoalStep(tester, goal: 1);
      expect(find.text('1 of 1 workout completed'), findsOneWidget);
      expect(ringLabel(tester), contains('100%'));
    });

    testWidgets('goal 2 previews 2 of 2 workouts completed', (tester) async {
      await pumpWeeklyGoalStep(tester, goal: 2);
      expect(find.text('2 of 2 workouts completed'), findsOneWidget);
      expect(ringLabel(tester), contains('100%'));
    });

    testWidgets('goal 3 previews 2 of 3 workouts completed', (tester) async {
      await pumpWeeklyGoalStep(tester, goal: 3);
      expect(find.text('2 of 3 workouts completed'), findsOneWidget);
      expect(ringLabel(tester), contains('67%'));
    });

    testWidgets('goal 7 previews 2 of 7 workouts completed', (tester) async {
      await pumpWeeklyGoalStep(tester, goal: 7);
      expect(find.text('2 of 7 workouts completed'), findsOneWidget);
      expect(ringLabel(tester), contains('29%'));
    });

    testWidgets('tapping goal 1 updates caption and ring together',
        (tester) async {
      await pumpWeeklyGoalStep(tester); // default goal 3
      expect(find.text('2 of 3 workouts completed'), findsOneWidget);

      await tapGoalSegment(tester, 1);
      expect(find.text('1 of 1 workout completed'), findsOneWidget);
      expect(ringLabel(tester), contains('100%'));
    });
  });
}

void _noop() {}
