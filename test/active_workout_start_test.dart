// Guards the reorder root-cause fix: when a workout is started from a routine
// (callers pass initialExercises), every exercise must end up with a UNIQUE,
// non-empty id. Without it they all defaulted to '' → identical keys → the
// active-workout list and reorder sheet collapsed to a single row.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymlog/features/workout/domain/active_workout_state.dart';
import 'package:gymlog/features/workout/presentation/providers/active_workout_provider.dart';

void main() {
  late ProviderContainer container;
  late ActiveWorkoutNotifier notifier;

  setUp(() {
    container = ProviderContainer();
    notifier = container.read(activeWorkoutProvider.notifier);
  });
  tearDown(() => container.dispose());

  test('startWorkout backfills unique ids for exercises passed without one',
      () async {
    // Mirrors routine_detail / workout_screen, which build states with no id.
    await notifier.startWorkout(
      routineId: 'r1',
      name: 'Push Day',
      initialExercises: const [
        WorkoutExerciseState(exerciseId: 1, name: 'Bench'),
        WorkoutExerciseState(exerciseId: 2, name: 'Press'),
        WorkoutExerciseState(exerciseId: 3, name: 'Fly'),
      ],
    );

    final ex = container.read(activeWorkoutProvider)!.exercises;
    expect(ex.length, 3);
    final ids = ex.map((e) => e.id).toSet();
    expect(ids.length, 3, reason: 'ids must be unique (was all "")');
    expect(ids.any((id) => id.isEmpty), isFalse, reason: 'no empty ids');
    expect(container.read(activeWorkoutProvider)!.name, 'Push Day');
  });

  test('startWorkout preserves ids that callers already set', () async {
    await notifier.startWorkout(
      initialExercises: const [
        WorkoutExerciseState(id: 'keep-me', exerciseId: 1, name: 'Bench'),
      ],
    );
    expect(
        container.read(activeWorkoutProvider)!.exercises.first.id, 'keep-me');
  });
}
