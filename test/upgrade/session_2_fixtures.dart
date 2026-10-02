// Synthetic evidence for Session 2 exploration, not production launch logic.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gymlog/core/database/database.dart';
import 'package:gymlog/core/database/daos/routines_dao.dart';
import 'package:gymlog/core/database/daos/workouts_dao.dart';
import 'package:gymlog/core/routines/program_membership.dart';
import 'package:gymlog/core/theme/app_theme.dart';
import 'package:gymlog/core/theme/theme_palette.dart';
import 'package:gymlog/features/auth/presentation/providers/auth_provider.dart';
import 'package:gymlog/features/home/presentation/providers/home_provider.dart';
import 'package:gymlog/features/home/presentation/screens/home_screen.dart';
import 'package:gymlog/features/profile/presentation/providers/profile_stats_provider.dart';
import 'package:gymlog/features/routines/presentation/providers/routines_provider.dart';
import 'package:gymlog/features/routines/presentation/providers/training_launch_provider.dart';
import 'package:gymlog/features/workout/presentation/screens/workout_screen.dart';
import 'package:gymlog/features/workout/presentation/providers/active_workout_provider.dart';
import 'package:gymlog/features/workout/domain/active_workout_state.dart';
import 'package:gymlog/shared/providers/bottom_chrome_provider.dart';
import 'package:gymlog/shared/widgets/bottom_nav_bar.dart';

enum LaunchState { returning, inactive, empty, noRoutine, lowData, error }

final session2Date = DateTime(2026, 10, 2, 12);

const samplePlans = [
  (
    name: 'Push A',
    exercises: [
      'Bench Press',
      'Incline Press',
      'Overhead Press',
      'Lateral Raise',
      'Triceps Pushdown'
    ],
    focus: ['Chest', 'Shoulders', 'Triceps']
  ),
  (
    name: 'Pull A',
    exercises: [
      'Lat Pulldown',
      'Cable Row',
      'Face Pull',
      'Dumbbell Curl',
      'Hammer Curl'
    ],
    focus: ['Back', 'Biceps']
  ),
  (
    name: 'Legs A',
    exercises: [
      'Squat',
      'Romanian Deadlift',
      'Leg Press',
      'Leg Curl',
      'Calf Raise'
    ],
    focus: ['Legs']
  ),
  (
    name: 'Full Body',
    exercises: ['Squat', 'Bench Press', 'Cable Row', 'Overhead Press'],
    focus: ['Legs', 'Chest', 'Back']
  ),
  (name: 'Outdoor walk', exercises: ['Outdoor Walk'], focus: <String>[]),
];

List<HydratedRoutine> sampleRoutines(LaunchState state) {
  if (state == LaunchState.empty ||
      state == LaunchState.noRoutine ||
      state == LaunchState.error) {
    return [];
  }
  final indexes = state == LaunchState.lowData ? [4] : [0, 1, 2, 3, 4];
  return [
    for (final i in indexes)
      HydratedRoutine(
        routine: Routine(
            id: 'sample-$i',
            userId: 'sample',
            name: samplePlans[i].name,
            notes: i < 3
                ? encodeProgramMembership(ProgramMembership(
                    programSlug: 'sample-ppl',
                    programLabel: 'Push / Pull / Legs',
                    orderIndex: i,
                    totalRoutines: 3,
                    routineSlug: 'sample-$i'))
                : '',
            sourceProgramName: i < 3 ? 'Push / Pull / Legs' : null,
            createdAt: session2Date.subtract(const Duration(days: 30)),
            updatedAt: session2Date),
        exerciseNames: samplePlans[i].exercises,
        exerciseIds: [
          for (var j = 0; j < samplePlans[i].exercises.length; j++)
            i * 10 + j + 1
        ],
        muscleTags: samplePlans[i].focus,
        lastTrained: state == LaunchState.lowData || i > 2
            ? null
            : session2Date.subtract(Duration(
                days: state == LaunchState.inactive
                    ? (i == 2 ? 23 : 18 + (i == 0 ? 2 : 0))
                    : (i == 0
                        ? 4
                        : i == 1
                            ? 2
                            : 6))),
      )
  ];
}

List<WorkoutSessionPreview> sampleHistory(LaunchState state) {
  if (state == LaunchState.empty ||
      state == LaunchState.lowData ||
      state == LaunchState.error) {
    return [];
  }
  return [
    for (final i in [1, 0])
      WorkoutSessionPreview(
        session: WorkoutSession(
            id: 'sample-session-$i',
            userId: 'sample',
            name: samplePlans[i].name,
            routineId: state == LaunchState.noRoutine ? null : 'sample-$i',
            startedAt: session2Date.subtract(Duration(
                days: state == LaunchState.inactive
                    ? 18 + (i == 0 ? 2 : 0)
                    : (i == 1 ? 2 : 4))),
            endedAt: session2Date
                .subtract(Duration(
                    days: state == LaunchState.inactive
                        ? 18 + (i == 0 ? 2 : 0)
                        : (i == 1 ? 2 : 4)))
                .add(const Duration(minutes: 48)),
            notes: '',
            totalVolumeKg: i == 0 ? 4200 : 3850,
            synced: false),
        duration: const Duration(minutes: 48),
        totalVolumeKg: i == 0 ? 4200 : 3850,
        prCount: 0,
        topExercises: [
          for (final name in samplePlans[i].exercises.take(2))
            ExercisePreviewItem(exerciseName: name, setCount: 3)
        ],
        totalExerciseCount: 5,
      )
  ];
}

class _SampleHistory extends WorkoutHistoryNotifier {
  _SampleHistory(super.ref, LaunchState fixtureState) {
    state = WorkoutHistoryState(
        items: sampleHistory(fixtureState),
        hasMore: false,
        isLoadingMore: false,
        isInitialLoad: false,
        error: fixtureState == LaunchState.error
            ? StateError('Synthetic read failure')
            : null);
  }
}

class _SampleActive extends ActiveWorkoutNotifier {
  _SampleActive(super.ref, bool active) {
    state = active
        ? ActiveWorkoutState(
            id: 'fixture-active',
            name: 'Pull A',
            startTime: session2Date,
            exercises: const [])
        : null;
  }
}

Widget launchFixtureApp(
    {required Widget child,
    required ThemePalette palette,
    required double scale,
    required String screen,
    required LaunchState fixtureState,
    List<HydratedRoutine>? routines,
    Stream<List<HydratedRoutine>>? routineStream,
    bool previousError = false,
    bool routinesLoading = false,
    bool activeWorkout = false,
    required Key captureKey}) {
  return ProviderScope(
      overrides: [
        authProvider.overrideWithValue(null),
        activeWorkoutProvider
            .overrideWith((ref) => _SampleActive(ref, activeWorkout)),
        trainingClockProvider.overrideWithValue(() => session2Date),
        routineDetailProvider.overrideWith(
            (ref, id) => Stream.value(sampleRoutineDetail(id, fixtureState))),
        routineLastSetsProvider.overrideWith((ref, id) => previousError
            ? Stream.error(StateError('Synthetic previous-set read failure'))
            : Stream.value(fixtureState == LaunchState.lowData ||
                    fixtureState == LaunchState.empty
                ? <String, List<LastSessionSetData>>{}
                : {
                    '1': [
                      const LastSessionSetData(
                          setNumber: 1, weightKg: 60, reps: 8)
                    ],
                    '11': [
                      const LastSessionSetData(
                          setNumber: 1, weightKg: 50, reps: 10)
                    ],
                    '21': [
                      const LastSessionSetData(
                          setNumber: 1, weightKg: 80, reps: 5)
                    ],
                  })),
        hydratedRoutinesProvider.overrideWith((ref) =>
            routineStream ??
            (routinesLoading
                ? const Stream.empty()
                : fixtureState == LaunchState.error
                    ? Stream.error(StateError('Synthetic routine read failure'))
                    : Stream.value(routines ?? sampleRoutines(fixtureState)))),
        workoutHistoryProvider
            .overrideWith((ref) => _SampleHistory(ref, fixtureState)),
        streakStatsProvider.overrideWithValue(StreakStats(
            workoutsThisWeek: fixtureState == LaunchState.returning ||
                    fixtureState == LaunchState.noRoutine
                ? 2
                : 0,
            hasError: fixtureState == LaunchState.error)),
        bottomChromeInsetProvider.overrideWithValue(BottomNavBar.height),
      ],
      child: RepaintBoundary(
          key: captureKey,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: buildAppTheme(palette.tokens, palette: palette),
            builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(textScaler: TextScaler.linear(scale)),
                child: child!),
            home: child,
          )));
}

Widget currentLaunchScreen(String screen) => Scaffold(
      body: screen == 'home' ? const HomeScreen() : const WorkoutScreen(),
      bottomNavigationBar:
          BottomNavBar(currentIndex: screen == 'home' ? 0 : 1, onTap: (_) {}),
    );

HydratedRoutineDetail? sampleRoutineDetail(String id, LaunchState state) {
  HydratedRoutine? plan;
  for (final r in sampleRoutines(state)) {
    if (r.routine.id == id) plan = r;
  }
  if (plan == null) return null;
  return HydratedRoutineDetail(routine: plan.routine, exercises: [
    for (var i = 0; i < plan.exerciseIds.length; i++)
      HydratedRoutineExercise(
          exercise: Exercise(
              id: plan.exerciseIds[i],
              name: plan.exerciseNames[i],
              bodyPart: plan.muscleTags.isEmpty ? '' : plan.muscleTags.first,
              equipment: id == 'sample-4' ? '' : 'Barbell',
              target: '',
              isCustom: false,
              measurementType:
                  id == 'sample-4' ? 'distance' : 'weight_and_reps'),
          config: RoutineExercise(
              id: '$id-$i',
              routineDayId: 'fixture-day-$id',
              exerciseId: plan.exerciseIds[i],
              orderIndex: i,
              defaultSets: id == 'sample-4' ? 1 : 3)),
  ]);
}
