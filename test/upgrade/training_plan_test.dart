import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:gymlog/core/database/daos/routines_dao.dart';
import 'package:gymlog/core/database/daos/workouts_dao.dart';
import 'package:gymlog/core/database/database.dart';
import 'package:gymlog/features/routines/presentation/providers/training_plan_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'session_2_fixtures.dart';

extension PreviewFixture on WorkoutSessionPreview {
  WorkoutSessionPreview copyForTest(WorkoutSession value) =>
      WorkoutSessionPreview(
          session: value,
          duration: duration,
          totalVolumeKg: totalVolumeKg,
          prCount: prCount,
          topExercises: topExercises,
          totalExerciseCount: totalExerciseCount);
}

class FailedPreferences implements SharedPreferences {
  @override
  Future<bool> setString(String key, String value) async => false;
  @override
  String? getString(String key) => null;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  final routines = sampleRoutines(LaunchState.returning);
  final history = sampleHistory(LaunchState.returning);
  final plan = planForRoutine(routines.first, routines);
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test(
      'program uses latest completion, wraps, and never persists a next cursor',
      () {
    expect(
        resolveTrainingPlan(plan, routines, []).next?.routine.id, 'sample-0');
    expect(resolveTrainingPlan(plan, routines, history).next?.routine.id,
        'sample-2');
    final legs =
        history.first.session.copyWith(routineId: const Value('sample-2'));
    expect(
        resolveTrainingPlan(plan, routines, [history.first.copyForTest(legs)])
            .next
            ?.routine
            .id,
        'sample-0');
    expect(plan.encode(), isNot(contains('next')));
  });
  test(
      'start, unfinished, discard, save failure and rest day have no completed evidence',
      () {
    final unfinished =
        history.first.session.copyWith(endedAt: const Value(null));
    expect(
        resolveTrainingPlan(
                plan, routines, [history.first.copyForTest(unfinished)])
            .next
            ?.routine
            .id,
        'sample-0');
    for (final unchanged in [[], history]) {
      expect(
          resolveTrainingPlan(plan, routines, unchanged.cast())
              .next
              ?.routine
              .id,
          unchanged.isEmpty ? 'sample-0' : 'sample-2');
    }
  });
  test(
      'outside-program and freestyle completions do not advance chosen program',
      () {
    for (final id in ['sample-4', null]) {
      final other = history.first
          .copyForTest(history.first.session.copyWith(routineId: Value(id)));
      expect(resolveTrainingPlan(plan, routines, [other]).next?.routine.id,
          'sample-0');
    }
  });
  test('same-program override continues after the day actually completed', () {
    final push = history.first.copyForTest(
        history.first.session.copyWith(routineId: const Value('sample-0')));
    expect(resolveTrainingPlan(plan, routines, [push]).next?.routine.id,
        'sample-1');
  });
  test(
      'completion chronology overrides start-date order and ignores older imported history',
      () {
    final completedLater = history.last.copyForTest(history.last.session
        .copyWith(
            startedAt: DateTime(2026, 1),
            endedAt: Value(DateTime(2026, 10, 3))));
    expect(
        resolveTrainingPlan(plan, routines, [history.first, completedLater])
            .next
            ?.routine
            .id,
        'sample-1');
  });
  test('missing, duplicate, conflicting program metadata requires choice', () {
    expect(
        resolveTrainingPlan(plan, routines.take(2).toList(), history).problem,
        isNotNull);
    final duplicate = HydratedRoutine(
        routine: routines.first.routine.copyWith(id: 'duplicate'),
        exerciseNames: routines.first.exerciseNames,
        exerciseIds: routines.first.exerciseIds);
    expect(resolveTrainingPlan(plan, [...routines, duplicate], history).problem,
        isNotNull);
    expect(resolveTrainingPlan(plan, routines.skip(1).toList(), history).next,
        isNull);
  });
  test(
      'tied latest program days require explicit choice; same-day duplicate does not',
      () {
    final tied = history.last.copyForTest(history.last.session
        .copyWith(endedAt: Value(history.first.session.endedAt)));
    expect(resolveTrainingPlan(plan, routines, [history.first, tied]).problem,
        isNotNull);
    final sameDay = tied
        .copyForTest(tied.session.copyWith(routineId: const Value('sample-1')));
    expect(
        resolveTrainingPlan(plan, routines, [history.first, sameDay])
            .next
            ?.routine
            .id,
        'sample-2');
  });
  test('repeat mode stays on its chosen routine and rename preserves identity',
      () {
    final repeat = planForRoutine(routines[3], routines);
    expect(repeat.followsProgram, isFalse);
    expect(resolveTrainingPlan(repeat, routines, history).next?.routine.id,
        'sample-3');
    final renamed = [
      for (final r in routines)
        HydratedRoutine(
            routine: r.routine.copyWith(name: '${r.routine.name} renamed'),
            exerciseNames: r.exerciseNames,
            exerciseIds: r.exerciseIds)
    ];
    expect(resolveTrainingPlan(plan, renamed, history).next?.routine.name,
        'Legs A renamed');
  });
  test(
      'explicit starting day resolves a tied import without marking skipped days completed',
      () {
    final end = history.first.session.endedAt!;
    final tied = history.last
        .copyForTest(history.last.session.copyWith(endedAt: Value(end)));
    final explicit = TrainingPlan(
        anchorId: 'sample-0', programSlug: 'sample-ppl', startAfter: end);
    expect(
        resolveTrainingPlan(explicit, routines, [history.first, tied])
            .next
            ?.routine
            .id,
        'sample-0');
    final newCompletion = history.first.copyForTest(history.first.session
        .copyWith(endedAt: Value(end.add(const Duration(days: 1)))));
    expect(
        resolveTrainingPlan(explicit, routines, [newCompletion, tied])
            .next
            ?.routine
            .id,
        'sample-2');
  });
  test(
      'legacy complete program migrates durably and account choice is isolated',
      () async {
    SharedPreferences.setMockInitialValues(
        {'training_routine:owner': 'sample-0'});
    final notifier = TrainingPlanNotifier('owner', () async => routines);
    addTearDown(notifier.dispose);
    await notifier.load();
    expect(notifier.state.requireValue?.programSlug, 'sample-ppl');
    final restarted = TrainingPlanNotifier(
        'owner', () async => throw StateError('not needed'));
    addTearDown(restarted.dispose);
    await restarted.load();
    expect(restarted.state.requireValue?.anchorId, 'sample-0');
    final other = TrainingPlanNotifier('another', () async => routines);
    addTearDown(other.dispose);
    await other.load();
    expect(other.state.requireValue, isNull);
  });
  test(
      'legacy standalone repeats; partial/deleted choices do not become guessed programs',
      () async {
    for (final id in ['sample-3', 'sample-0', 'deleted']) {
      SharedPreferences.setMockInitialValues({'training_routine:owner': id});
      final n = TrainingPlanNotifier(
          'owner', () async => routines.take(2).toList() + [routines[3]]);
      await n.load();
      expect(n.state.requireValue?.needsChoice, id != 'sample-3');
      expect(n.state.requireValue?.followsProgram, isFalse);
      n.dispose();
    }
  });
  test(
      'malformed preferences surface a retryable error without deleting old choice',
      () async {
    for (final value in [7, '{bad json}', '{"version": 99}']) {
      SharedPreferences.setMockInitialValues({'training_plan:v1:owner': value});
      final n = TrainingPlanNotifier('owner', () async => routines);
      await n.load();
      expect(n.state.hasError, isTrue);
      expect(
          (await SharedPreferences.getInstance()).get('training_plan:v1:owner'),
          value);
      n.dispose();
    }
  });
  test('failed preference write does not publish or claim a saved plan',
      () async {
    final n = TrainingPlanNotifier('owner', () async => routines,
        preferences: () async => FailedPreferences());
    addTearDown(n.dispose);
    await n.load();
    await expectLater(n.choose(routines.first, routines), throwsStateError);
    expect(n.state.requireValue, isNull);
  });
  test('disposed account migration cannot finish writing obsolete intent',
      () async {
    SharedPreferences.setMockInitialValues(
        {'training_routine:owner': 'sample-0'});
    final library = Completer<List<HydratedRoutine>>();
    final n = TrainingPlanNotifier('owner', () => library.future);
    final loading = n.load();
    await Future<void>.delayed(Duration.zero);
    n.dispose();
    library.complete(routines);
    await loading;
    expect(
        (await SharedPreferences.getInstance())
            .getString('training_plan:v1:owner'),
        isNull);
  });
}
