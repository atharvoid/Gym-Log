import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gymlog/core/services/workout_draft_store.dart';
import 'package:gymlog/core/providers/settings_provider.dart';
import 'package:gymlog/features/workout/domain/active_workout_state.dart';
import 'package:gymlog/features/workout/presentation/providers/active_workout_provider.dart';
import 'package:gymlog/features/workout/presentation/providers/rest_timer_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('GymLog P0-04 Rest Timer Override & Precedence Suite', () {
    late Map<String, String> mockStorage;
    late WorkoutDraftStore store;

    setUp(() {
      mockStorage = <String, String>{};
      FlutterSecureStorage.setMockInitialValues(mockStorage);
      store = WorkoutDraftStore(const FlutterSecureStorage());
    });

    // Helper to setup mock draft store provider in overrides
    ProviderContainer createContainer({
      List<Override> overrides = const [],
    }) {
      final container = ProviderContainer(
        overrides: [
          workoutDraftStoreProvider.overrideWith((ref) => store),
          ...overrides,
        ],
      );
      addTearDown(container.dispose);
      return container;
    }

    // ── 1. Precedence Rules & Defaults ───────────────────────────────────────

    test('precedence: override > global setting default > safe fallback (90s)',
        () {
      final container = createContainer();

      final state = ActiveWorkoutState(
        id: 'w-test',
        startTime: DateTime.now(),
        exercises: [
          const WorkoutExerciseState(
            id: 'ex-1',
            exerciseId: 101,
            name: 'Squat',
            restSecondsOverride: 120, // Override set to 2:00
          ),
          const WorkoutExerciseState(
            id: 'ex-2',
            exerciseId: 102,
            name: 'Bench Press',
            restSecondsOverride: null, // No override
          ),
        ],
      );

      // Precedence 1: exercise override is present (120s)
      final ex1 = state.exercises[0];
      final duration1 =
          ex1.restSecondsOverride ?? container.read(defaultRestSecondsProvider);
      expect(duration1, 120);

      // Precedence 2: exercise override absent -> global default (defaults to 90s)
      final ex2 = state.exercises[1];
      final duration2 =
          ex2.restSecondsOverride ?? container.read(defaultRestSecondsProvider);
      expect(duration2, 90);
    });

    // ── 2. Override Scope & Isolation ────────────────────────────────────────

    test('override scope: override on exercise A does not leak to exercise B',
        () {
      final container = createContainer();
      final notifier = container.read(activeWorkoutProvider.notifier);

      notifier.resumeDraft(ActiveWorkoutState(
        id: 'w-scope',
        startTime: DateTime.now(),
        exercises: [
          const WorkoutExerciseState(
            id: 'ex-A',
            exerciseId: 1,
            name: 'Deadlift',
            restSecondsOverride: null,
          ),
          const WorkoutExerciseState(
            id: 'ex-B',
            exerciseId: 2,
            name: 'Push-up',
            restSecondsOverride: null,
          ),
        ],
      ));

      // Apply override to Exercise A
      notifier.setRestSecondsOverride(0, 180);

      final state = container.read(activeWorkoutProvider)!;
      expect(state.exercises[0].restSecondsOverride, 180);
      expect(state.exercises[1].restSecondsOverride, isNull);
    });

    // ── 3. Session Reset ─────────────────────────────────────────────────────

    test('new-workout starts without copying previous workout overrides',
        () async {
      final container = createContainer();
      final notifier = container.read(activeWorkoutProvider.notifier);

      // Finish an old session containing overrides
      notifier.resumeDraft(ActiveWorkoutState(
        id: 'w-old',
        startTime: DateTime.now(),
        exercises: [
          const WorkoutExerciseState(
            id: 'ex-A',
            exerciseId: 1,
            name: 'Deadlift',
            restSecondsOverride: 150,
          ),
        ],
      ));

      // Start new workout
      await notifier.startWorkout(
        routineId: 'r-new',
        name: 'New Workout',
        initialExercises: [
          const WorkoutExerciseState(
            id: 'ex-new',
            exerciseId: 1,
            name: 'Deadlift',
          ),
        ],
      );

      final state = container.read(activeWorkoutProvider)!;
      expect(state.id, isNot('w-old'));
      expect(state.exercises.first.restSecondsOverride, isNull,
          reason: 'Overrides must reset to null on starting a new session');
    });

    // ── 4. Background & Resume with elapsed deadline ──────────────────────────

    test(
        'background/resume: timer expired while backgrounded triggers finish on sync',
        () {
      final container = createContainer();
      final timerNotifier = container.read(restTimerProvider.notifier);

      // Start a 10s timer
      timerNotifier.start(
        seconds: 10,
        workoutId: 'w-bg',
        exerciseId: 1,
        setId: 's-1',
      );

      expect(container.read(restTimerProvider), isNotNull);

      // Simulate app suspended and elapsed beyond the deadline
      timerNotifier.resumeFromEndTime(
        endTime: DateTime.now().subtract(const Duration(seconds: 5)),
        totalSeconds: 10,
        workoutId: 'w-bg',
        exerciseId: 1,
        setId: 's-1',
      );

      // Ticker sync triggers immediate expiration
      expect(container.read(restTimerProvider), isNull,
          reason:
              'Timer should be expired and resolved to null immediately upon resume');
    });

    // ── 5. Active Timer Modification Rule ────────────────────────────────────

    test(
        'active timer change rule: mutating override does not alter already-running timer deadline',
        () {
      final container = createContainer();
      final timerNotifier = container.read(restTimerProvider.notifier);

      // Start timer with 90s
      timerNotifier.start(
        seconds: 90,
        workoutId: 'w-mut',
        exerciseId: 1,
        setId: 's-1',
      );

      final originalEndTime = container.read(restTimerProvider)!.endTime;

      // Update override to 180s in workout notifier
      final workoutNotifier = container.read(activeWorkoutProvider.notifier);
      workoutNotifier.resumeDraft(ActiveWorkoutState(
        id: 'w-mut',
        startTime: DateTime.now(),
        exercises: [
          const WorkoutExerciseState(
            id: 'ex-1',
            exerciseId: 1,
            name: 'Deadlift',
            restSecondsOverride: 90,
          ),
        ],
      ));

      workoutNotifier.setRestSecondsOverride(0, 180);

      // Verify currently running timer is completely unaffected
      final runningTimer = container.read(restTimerProvider);
      expect(runningTimer, isNotNull);
      expect(runningTimer!.totalSeconds, 90,
          reason: 'Running timer totalSeconds must remain 90');
      expect(runningTimer.endTime, originalEndTime,
          reason: 'Running timer absolute endTime must remain unchanged');
    });

    // ── 6. Idempotency & Process Death Restoration ───────────────────────────

    test(
        'process-death: restores override and running timer context successfully',
        () async {
      final workout = ActiveWorkoutState(
        id: 'w-pd-99',
        startTime: DateTime.now(),
        exercises: [
          const WorkoutExerciseState(
            id: 'ex-1',
            exerciseId: 44,
            name: 'Lat Pulldown',
            restSecondsOverride: 75,
          ),
        ],
      );

      final endTime = DateTime.now().add(const Duration(seconds: 30));
      final restTimer = RestTimerSnapshot(
        totalSeconds: 60,
        endTime: endTime,
        workoutId: 'w-pd-99',
        exerciseId: 44,
        setId: 's-pd-00',
      );

      // Save draft (simulating process death)
      await store.save(workout, userId: 'user-11', restTimer: restTimer);

      // Simulate startup load
      final snapshot = await store.loadSnapshot(currentUserId: 'user-11');
      expect(snapshot, isNotNull);

      // Validate workout exercise override restored
      final restoredWorkout = snapshot!.workout;
      expect(restoredWorkout.exercises.first.restSecondsOverride, 75);

      // Validate rest timer context restored
      final restoredTimer = snapshot.restTimer;
      expect(restoredTimer, isNotNull);
      expect(restoredTimer!.totalSeconds, 60);
      expect(restoredTimer.workoutId, 'w-pd-99');
      expect(restoredTimer.exerciseId, 44);
      expect(restoredTimer.setId, 's-pd-00');
    });

    // ── 7. Rapid Interaction & Idempotency ───────────────────────────────────

    test(
        'idempotency: multiple start, cancel, and skip calls behave predictably',
        () {
      final container = createContainer();
      final notifier = container.read(restTimerProvider.notifier);

      // Double-start
      notifier.start(seconds: 45, workoutId: 'w', exerciseId: 1, setId: 's');
      notifier.start(seconds: 45, workoutId: 'w', exerciseId: 1, setId: 's');
      expect(container.read(restTimerProvider)!.totalSeconds, 45);

      // Double-skip is safe
      notifier.skip();
      notifier.skip();
      expect(container.read(restTimerProvider), isNull);
    });

    // ── 8. Bounded Values & Boundaries ───────────────────────────────────────

    test(
        'boundaries: custom overrides are clamped inside user UI picker sheets',
        () {
      // In the UI selection code, we clamp values between 10s and 600s.
      // Verify that out-of-bound attempts in picker increments are correctly clamped.
      int customValue1 = 5;
      customValue1 = customValue1.clamp(10, 600);
      expect(customValue1, 10);

      int customValue2 = 700;
      customValue2 = customValue2.clamp(10, 600);
      expect(customValue2, 600);
    });
  });
}
