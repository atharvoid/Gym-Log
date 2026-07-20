import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymlog/core/models/rest_preference.dart';
import 'package:gymlog/features/workout/presentation/providers/active_workout_provider.dart';

void main() {
  group('UI-P0-01 Complete Device Acceptance & Geometry Test Suite', () {
    testWidgets('DEV-01 & DEV-03: No-equipment vs Assisted Machine layout',
        (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(activeWorkoutProvider.notifier);
      await notifier.startWorkout(name: 'Acceptance Test Workout');

      // Add Bodyweight / No-equipment move
      notifier.addExercise(10, 'Archer Push Up', measurementType: 'reps_only');
      // Add Assisted Machine move
      notifier.addExercise(20, 'Assisted Chest Dip',
          measurementType: 'weight_and_reps');

      final state = container.read(activeWorkoutProvider);
      expect(state, isNotNull);
      expect(state!.exercises.length, 2);

      // Archer Push Up must be reps_only with null weightKg
      expect(state.exercises[0].measurementType, 'reps_only');
      expect(state.exercises[0].sets.first.weightKg, isNull);

      // Assisted Chest Dip must be weight_and_reps with numeric weightKg
      expect(state.exercises[1].measurementType, 'weight_and_reps');
      expect(state.exercises[1].sets.first.weightKg, 0.0);
    });

    testWidgets('Finish button is disabled until first set completion',
        (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(activeWorkoutProvider.notifier);
      await notifier.startWorkout(name: 'Finish Test');

      notifier.addExercise(10, 'Push Up', measurementType: 'reps_only');

      // Before completing set, completedSets is 0
      final (vol1, completed1) = notifier.sessionTotals;
      expect(completed1, 0);

      // Complete set
      notifier.toggleSetCompletion(0, 0);

      // After completing set, completedSets is 1
      final (vol2, completed2) = notifier.sessionTotals;
      expect(completed2, 1);
    });

    testWidgets('RestPreference model converts raw seconds cleanly',
        (tester) async {
      expect(
          RestPreference.fromRaw(null), isA<RestPreferenceUseGlobalDefault>());
      expect(RestPreference.fromRaw(0), isA<RestPreferenceDisabled>());
      expect(RestPreference.fromRaw(45), isA<RestPreferenceCustomDuration>());

      expect(RestPreference.fromRaw(null).toRaw(), isNull);
      expect(RestPreference.fromRaw(0).toRaw(), 0);
      expect(RestPreference.fromRaw(45).toRaw(), 45);
    });

    testWidgets(
        'Nullable-weight updates clear weight when switching to reps_only',
        (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(activeWorkoutProvider.notifier);
      await notifier.startWorkout(name: 'Switch Test');

      // Add weighted exercise
      notifier.addExercise(100, 'Bench Press',
          measurementType: 'weight_and_reps');
      notifier.updateSet(0, 0, weight: 80.0, reps: 10);

      var state = container.read(activeWorkoutProvider)!;
      expect(state.exercises[0].sets[0].weightKg, 80.0);

      // Replace with reps-only exercise
      notifier.replaceExercise(0, 200, 'Push Up', measurementType: 'reps_only');

      state = container.read(activeWorkoutProvider)!;
      expect(state.exercises[0].measurementType, 'reps_only');
      expect(state.exercises[0].sets[0].weightKg, isNull);
    });
  });
}
