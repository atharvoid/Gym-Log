// Regression guard for exercise reordering on the Active Workout screen.
//
// Flutter 3.16+ replaced ReorderableListView's `onReorder` with `onReorderItem`,
// whose newIndex is ALREADY adjusted for the removed item — so the notifier
// must NOT apply the legacy "if (newIndex > oldIndex) newIndex--" decrement.
// These tests pin that contract for representative moves.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymlog/features/workout/domain/active_workout_state.dart';
import 'package:gymlog/features/workout/presentation/providers/active_workout_provider.dart';

void main() {
  late ProviderContainer container;
  late ActiveWorkoutNotifier notifier;

  WorkoutExerciseState ex(String id) =>
      WorkoutExerciseState(id: id, exerciseId: id.hashCode, name: id);

  setUp(() {
    container = ProviderContainer();
    notifier = container.read(activeWorkoutProvider.notifier);
    notifier.startWorkout(initialExercises: [
      ex('A'),
      ex('B'),
      ex('C'),
      ex('D'),
    ]);
  });

  tearDown(() => container.dispose());

  List<String> order() =>
      container.read(activeWorkoutProvider)!.exercises.map((e) => e.name).toList();

  test('move first item down (A→index 2): B, C, A, D', () {
    notifier.reorderExercise(0, 2); // onReorderItem newIndex is post-removal
    expect(order(), ['B', 'C', 'A', 'D']);
  });

  test('move last item to front (D→index 0): D, A, B, C', () {
    notifier.reorderExercise(3, 0);
    expect(order(), ['D', 'A', 'B', 'C']);
  });

  test('move middle up (C→index 1): A, C, B, D', () {
    notifier.reorderExercise(2, 1);
    expect(order(), ['A', 'C', 'B', 'D']);
  });

  test('out-of-range oldIndex is ignored (no throw, order intact)', () {
    notifier.reorderExercise(9, 0);
    expect(order(), ['A', 'B', 'C', 'D']);
  });
}
