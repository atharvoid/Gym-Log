import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymlog/core/database/daos/routines_dao.dart';
import 'package:gymlog/features/routines/presentation/providers/training_launch_provider.dart';
import 'package:gymlog/features/workout/domain/active_workout_state.dart';
import 'package:gymlog/features/workout/presentation/providers/active_workout_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:gymlog/features/auth/presentation/providers/auth_provider.dart';
import 'session_2_fixtures.dart';

class _Active extends ActiveWorkoutNotifier {
  _Active(super.ref);
  int starts = 0;
  void resumeFixture() => state = ActiveWorkoutState(
      id: 'existing', startTime: session2Date, exercises: const []);
  @override
  Future<void> startWorkout(
      {String? routineId,
      String? name,
      List<WorkoutExerciseState>? initialExercises}) async {
    starts++;
    state = ActiveWorkoutState(
        id: 'new',
        startTime: session2Date,
        routineId: routineId,
        name: name,
        exercises: initialExercises ?? const []);
  }
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  ProviderContainer container(
      Future<HydratedRoutineDetail?> Function(String) load) {
    final c = ProviderContainer(overrides: [
      activeWorkoutProvider.overrideWith(_Active.new),
      trainingRoutineLoaderProvider.overrideWithValue(load),
    ]);
    addTearDown(c.dispose);
    return c;
  }

  test('account switch during routine lookup cannot launch old-account content',
      () async {
    final lookup = Completer<HydratedRoutineDetail?>();
    Future<HydratedRoutineDetail?> loader(String _) => lookup.future;
    User user(String id) => User(
        id: id,
        appMetadata: {},
        userMetadata: {},
        aud: 'authenticated',
        createdAt: '2026-01-01');
    final c = ProviderContainer(overrides: [
      activeWorkoutProvider.overrideWith(_Active.new),
      trainingRoutineLoaderProvider.overrideWithValue(loader),
      authProvider.overrideWithValue(user('a'))
    ]);
    addTearDown(c.dispose);
    final start = c.read(trainingLauncherProvider).startRoutine('sample-0');
    c.updateOverrides([
      activeWorkoutProvider.overrideWith(_Active.new),
      trainingRoutineLoaderProvider.overrideWithValue(loader),
      authProvider.overrideWithValue(user('b'))
    ]);
    lookup.complete(sampleRoutineDetail('sample-0', LaunchState.returning));
    expect(await start, LaunchResult.unavailable);
    expect((c.read(activeWorkoutProvider.notifier) as _Active).starts, 0);
  });

  test('valid routine Start seeds the saved plan and freestyle is explicit',
      () async {
    final c = container(
        (_) async => sampleRoutineDetail('sample-0', LaunchState.returning));
    expect(await c.read(trainingLauncherProvider).startRoutine('sample-0'),
        LaunchResult.started);
    final active = c.read(activeWorkoutProvider)!;
    expect(active.routineId, 'sample-0');
    expect(active.name, 'Push A');
    expect(active.exercises.length, 5);
    expect(active.exercises.first.sets.length, 3);
    final freestyle =
        container((_) async => throw StateError('should not load'));
    expect(await freestyle.read(trainingLauncherProvider).startFreestyle(),
        LaunchResult.started);
    expect(freestyle.read(activeWorkoutProvider)?.routineId, isNull);
  });

  test('deleted or emptied routine cannot start a session', () async {
    final c = container((_) async => null);
    expect(await c.read(trainingLauncherProvider).startRoutine('deleted'),
        LaunchResult.unavailable);
    final empty = HydratedRoutineDetail(
        routine: sampleRoutines(LaunchState.returning).first.routine,
        exercises: []);
    final emptyContainer = container((_) async => empty);
    expect(
        await emptyContainer
            .read(trainingLauncherProvider)
            .startRoutine('empty'),
        LaunchResult.unavailable);
    expect((c.read(activeWorkoutProvider.notifier) as _Active).starts, 0);
    expect(
        (emptyContainer.read(activeWorkoutProvider.notifier) as _Active).starts,
        0);
  });
  test('a read failure never creates an empty workout', () async {
    final c = container((_) async => throw StateError('read failed'));
    await expectLater(
        c.read(trainingLauncherProvider).startRoutine('r'), throwsStateError);
    expect((c.read(activeWorkoutProvider.notifier) as _Active).starts, 0);
  });
  test('existing workout is resumed rather than overwritten', () async {
    final c = container((_) async => throw StateError('must not read'));
    final active = c.read(activeWorkoutProvider.notifier) as _Active;
    active.resumeFixture();
    expect(await c.read(trainingLauncherProvider).startRoutine('r'),
        LaunchResult.resume);
    expect(await c.read(trainingLauncherProvider).startFreestyle(),
        LaunchResult.resume);
    expect(c.read(activeWorkoutProvider)?.id, 'existing');
    expect(active.starts, 0);
  });
  test(
      'concurrent Start and an active workout appearing during lookup are guarded',
      () async {
    final lookup = Completer<HydratedRoutineDetail?>();
    final c = container((_) => lookup.future);
    final first = c.read(trainingLauncherProvider).startRoutine('r');
    expect(await c.read(trainingLauncherProvider).startRoutine('r'),
        LaunchResult.busy);
    final active = c.read(activeWorkoutProvider.notifier) as _Active;
    active.resumeFixture();
    lookup.complete(null);
    expect(await first, LaunchResult.resume);
    expect(active.starts, 0);
  });
}
