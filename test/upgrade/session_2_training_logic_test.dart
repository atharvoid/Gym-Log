import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gymlog/core/database/daos/routines_dao.dart';
import 'package:gymlog/core/database/daos/workouts_dao.dart';
import 'package:gymlog/core/models/measurement_type.dart';
import 'package:gymlog/features/routines/presentation/providers/training_launch_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'session_2_fixtures.dart';
import 'package:gymlog/features/profile/presentation/providers/profile_stats_provider.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

void main() {
  test('weekly Home progress counts distinct local days, not session count',
      () {
    tz.initializeTimeZones();
    for (final zone in ['Asia/Kolkata', 'America/New_York']) {
      final location = tz.getLocation(zone);
      final stats = computeStreakStats([
        tz.TZDateTime(location, 2026, 9, 27, 23, 59), // Previous Sunday.
        tz.TZDateTime(
            location, 2026, 9, 28, 0, 1), // Monday, near UTC boundary.
        tz.TZDateTime(
            location, 2026, 9, 28, 23, 59), // Same local training day.
        tz.TZDateTime(location, 2026, 10, 2, 9),
        tz.TZDateTime(location, 2026, 10, 3, 9), // Future day is excluded.
      ], now: tz.TZDateTime(location, 2026, 10, 2, 12));
      expect(stats.workoutsThisWeek, 2, reason: zone);
      expect(stats.trainedToday, isTrue);
    }
  });
  test('duplicate imported day positions do not produce a next suggestion', () {
    final plans = sampleRoutines(LaunchState.returning);
    final duplicate = HydratedRoutine(
        routine: plans.first.routine.copyWith(id: 'duplicate-day'),
        exerciseNames: plans.first.exerciseNames,
        exerciseIds: plans.first.exerciseIds);
    expect(
        nextProgramSuggestion([...plans, duplicate],
            sampleHistory(LaunchState.returning), 'sample-0'),
        isNull);
  });
  test(
      'logged context converts weight and speech; non-weighted context stays typed',
      () {
    const set = LastSessionSetData(setNumber: 1, weightKg: 60, reps: 8);
    expect(launchSetText(MeasurementType.weightAndReps, set, 'lbs'),
        '132.3 lbs × 8');
    expect(
        launchSetText(MeasurementType.weightAndReps, set, 'lbs', spoken: true),
        '132.3 pounds for 8 reps');
    expect(launchSetText(MeasurementType.repsOnly, set, 'lbs'), '8 reps');
    const hold = LastSessionSetData(setNumber: 1, reps: 90);
    expect(launchSetText(MeasurementType.duration, hold, 'lbs'), '1:30');
    expect(launchSetText(MeasurementType.duration, hold, 'lbs', spoken: true),
        '90 seconds');
    const walk = LastSessionSetData(setNumber: 1, weightKg: 1200, reps: 120);
    expect(
        launchSetText(MeasurementType.distance, walk, 'lbs'), '1.2 km · 2:00');
    expect(launchSetText(MeasurementType.distance, walk, 'lbs', spoken: true),
        '1200 metres, 120 seconds');
    expect(launchSetText(MeasurementType.unknown, set, 'lbs'), isNull);
    expect(launchSetText(MeasurementType.weightAndReps, hold, 'lbs'), isNull);
  });
  setUp(() => SharedPreferences.setMockInitialValues({}));
  test('no routine becomes chosen until an explicit successful write',
      () async {
    final choice = ChosenRoutineNotifier('owner');
    await choice.load();
    expect(choice.state.valueOrNull, isNull);
    await choice.choose('sample-0');
    expect(choice.state.valueOrNull, 'sample-0');
    final restart = ChosenRoutineNotifier('owner');
    await restart.load();
    expect(restart.state.valueOrNull, 'sample-0');
    final another = ChosenRoutineNotifier('another');
    await another.load();
    expect(another.state.valueOrNull, isNull);
    choice.dispose();
    restart.dispose();
    another.dispose();
  });
  test('a wrong-type stored choice is an error, not an empty account',
      () async {
    SharedPreferences.setMockInitialValues({'training_routine:owner': 7});
    final choice = ChosenRoutineNotifier('owner');
    await choice.load();
    expect(choice.state.hasError, isTrue);
    choice.dispose();
  });
  test(
      '14-day return uses the most recent completed session, not chosen plan age',
      () {
    final history = sampleHistory(LaunchState.returning);
    final last = history.first.session.endedAt!;
    expect(
        isInactiveReturn(history, last.add(const Duration(days: 14))), isTrue);
    expect(
        isInactiveReturn(
            history,
            last
                .add(const Duration(days: 14))
                .subtract(const Duration(seconds: 1))),
        isFalse);
    expect(isInactiveReturn([], session2Date), isFalse);
    expect(isInactiveReturn(history.reversed.toList(), session2Date), isFalse);
  });
  test('relative training date does not claim a future date is today', () {
    expect(
        trainingAgeLabel(
            session2Date.subtract(const Duration(days: 4)), session2Date),
        'Last trained 4 days ago');
    expect(trainingAgeLabel(null, session2Date),
        'No sessions logged for this routine');
    expect(
        trainingAgeLabel(
            session2Date.add(const Duration(days: 1)), session2Date),
        contains('3 Oct 2026'));
  });
  test('next-program suggestion uses explicit linked saved order and wraps',
      () {
    final routines = sampleRoutines(LaunchState.returning);
    final suggestion = nextProgramSuggestion(
        routines, sampleHistory(LaunchState.returning), 'sample-0');
    expect(suggestion?.routine.routine.id, 'sample-2');
    expect(suggestion?.previousRoutineName, 'Pull A');
    expect(suggestion?.programName, 'Push / Pull / Legs');
  });
  test('legacy names, partial imports and empty days cannot imply next order',
      () {
    final routines = sampleRoutines(LaunchState.returning);
    final history = sampleHistory(LaunchState.returning);
    expect(
        nextProgramSuggestion(routines.take(2).toList(), history, 'sample-0'),
        isNull);
    final legacy = [
      for (final r in routines)
        HydratedRoutine(
            routine: r.routine.copyWith(notes: ''),
            exerciseNames: r.exerciseNames,
            exerciseIds: r.exerciseIds)
    ];
    expect(nextProgramSuggestion(legacy, history, 'sample-0'), isNull);
    final empty = [
      for (final r in routines)
        r.routine.id == 'sample-2'
            ? HydratedRoutine(
                routine: r.routine, exerciseNames: [], exerciseIds: [])
            : r
    ];
    expect(nextProgramSuggestion(empty, history, 'sample-0'), isNull);
    expect(nextProgramSuggestion(routines, [], 'sample-0'), isNull);
  });
}
