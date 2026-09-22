import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gymlog/core/models/measurement_type.dart';
import 'package:gymlog/core/providers/settings_provider.dart';
import 'package:gymlog/core/services/workout_draft_store.dart';
import 'package:gymlog/features/workout/domain/active_workout_state.dart';
import 'package:gymlog/features/workout/presentation/providers/active_workout_provider.dart';
import 'package:gymlog/features/workout/presentation/providers/hold_timer_provider.dart';
import 'package:gymlog/features/workout/presentation/providers/rest_timer_provider.dart';
import 'package:gymlog/features/workout/presentation/widgets/exercise_block.dart';
import 'package:gymlog/features/workout/presentation/widgets/hold_timer_bar.dart';
import 'package:gymlog/features/workout/presentation/widgets/rest_timer_bar.dart';

void main() {
  testWidgets('ExerciseBlock renders TIMER column and triggers HoldTimer',
      (tester) async {
    final workout = ActiveWorkoutState(
      id: 'w-test',
      startTime: DateTime.now(),
      exercises: [
        WorkoutExerciseState(
          id: 'ex-1',
          exerciseId: 101,
          name: 'Plank',
          measurementType: MeasurementType.duration.raw,
          restSecondsOverride: 60,
          sets: const [
            WorkoutSetState(
              id: 's-1',
              reps: 30, // 30s target
            ),
          ],
        ),
      ],
    );

    final container = ProviderContainer(
      overrides: [
        workoutDraftStoreProvider.overrideWithValue(WorkoutDraftStore()),
        defaultRestSecondsProvider.overrideWith((ref) => 60),
        activeWorkoutProvider.overrideWith(
            (ref) => ActiveWorkoutNotifier(ref)..resumeDraft(workout)),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Scaffold(
            body: ExerciseBlock(
              exerciseIndex: 0,
              onRemove: () {},
              onReplace: () {},
              onAddSet: () {},
              onRemoveSet: (_) {},
              onSetChanged: (_) {},
              onToggleSetCompletion: (_) {},
            ),
            bottomNavigationBar: Consumer(
              builder: (context, ref, child) {
                final holdTimer = ref.watch(holdTimerProvider);
                final restTimer = ref.watch(restTimerProvider);
                if (holdTimer != null) {
                  return HoldTimerBar(state: holdTimer);
                }
                if (restTimer != null) {
                  return RestTimerBar(state: restTimer);
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      ),
    );

    await tester.pump();

    // Verify single, clean TIME header is rendered
    expect(find.text('TIME'), findsOneWidget);

    // Verify play button trigger in SetRow
    expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);

    // Tap play icon button to start hold timer
    await tester.tap(find.byIcon(Icons.play_arrow_rounded));
    await tester.pump();

    // Verify HoldTimerBar appeared
    expect(find.byType(HoldTimerBar), findsOneWidget);

    // Skip prep if in prep mode
    if (find.text('Skip').evaluate().isNotEmpty) {
      await tester.tap(find.text('Skip'));
      await tester.pump();
    }

    // Tap 'Done' to finish and log
    expect(find.text('Done'), findsOneWidget);
    await tester.tap(find.text('Done'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Verify hold timer dismissed and rest timer bar appeared!
    expect(find.byType(HoldTimerBar), findsNothing);
    expect(find.byType(RestTimerBar), findsOneWidget);

    // Clean up running rest timer
    container.read(restTimerProvider.notifier).skip();
    await tester.pump();
  });
}
