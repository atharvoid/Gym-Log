// DAO integration tests against a real in-memory SQLite database.
//
// These exist to catch exactly the class of bug that static analysis cannot:
// raw SQL that parses but explodes (or silently lies) at runtime. They cover
// the full hydration path behind the Workout Detail screen, the Home feed
// previews, PR detection, and the previous-session CTE.

import 'dart:ffi';
import 'dart:io';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymlog/core/database/daos/routines_dao.dart';
import 'package:gymlog/core/database/database.dart';
import 'package:sqlite3/open.dart';

void main() {
  late AppDatabase db;
  const userId = 'user-1';

  setUpAll(() {
    // Host machines (CI runners, dev sandboxes) often ship only the
    // versioned soname. Fall back so VM tests run anywhere.
    if (Platform.isLinux) {
      open.overrideFor(OperatingSystem.linux, () {
        try {
          return DynamicLibrary.open('libsqlite3.so');
        } catch (_) {
          return DynamicLibrary.open('libsqlite3.so.0');
        }
      });
    }
  });

  Future<int> insertExercise(
      String name, String bodyPart, String equipment, String target) async {
    await db.exercisesDao.insertExercise(ExercisesCompanion.insert(
      name: name,
      bodyPart: bodyPart,
      equipment: equipment,
      target: target,
    ));
    final all = await db.exercisesDao.getAllExercises();
    return all.firstWhere((e) => e.name == name).id;
  }

  /// Inserts a completed session with [sets] = list of (exerciseId, weight, reps).
  Future<String> insertSession(
    String id,
    DateTime startedAt, {
    String? routineId,
    required List<(int, double, int)> sets,
  }) async {
    double volume = 0;
    for (final (_, w, r) in sets) {
      volume += w * r;
    }
    await db.workoutsDao.insertSession(WorkoutSessionsCompanion(
      id: Value(id),
      userId: const Value(userId),
      routineId: Value(routineId),
      startedAt: Value(startedAt),
      endedAt: Value(startedAt.add(const Duration(hours: 1))),
      totalVolumeKg: Value(volume),
    ));

    // Group by exercise, preserving order.
    final byExercise = <int, List<(double, int)>>{};
    for (final (exId, w, r) in sets) {
      byExercise.putIfAbsent(exId, () => []).add((w, r));
    }
    var exIndex = 0;
    for (final entry in byExercise.entries) {
      final weId = '$id-we-$exIndex';
      await db.workoutsDao.insertWorkoutExercise(WorkoutExercisesCompanion(
        id: Value(weId),
        sessionId: Value(id),
        exerciseId: Value(entry.key),
        orderIndex: Value(exIndex),
      ));
      var setIndex = 0;
      for (final (w, r) in entry.value) {
        await db.workoutsDao.insertSet(WorkoutSetsCompanion(
          id: Value('$weId-s-$setIndex'),
          workoutExerciseId: Value(weId),
          exerciseId: Value(entry.key),
          orderIndex: Value(setIndex),
          weightKg: Value(w),
          reps: Value(r),
          completedAt: Value(startedAt.add(Duration(minutes: setIndex * 3))),
        ));
        setIndex++;
      }
      exIndex++;
    }
    return id;
  }

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  test('getHydratedWorkout returns full graph incl. previous-session sets',
      () async {
    final bench =
        await insertExercise('Bench Press', 'chest', 'barbell', 'pectorals');
    final squat =
        await insertExercise('Squat', 'upper legs', 'barbell', 'quadriceps');

    await insertSession('s1', DateTime(2026, 6, 1, 10),
        sets: [(bench, 80, 8), (bench, 85, 6), (squat, 100, 5)]);
    await insertSession('s2', DateTime(2026, 6, 8, 10),
        sets: [(bench, 82.5, 8), (squat, 105, 5)]);

    final hydrated = await db.workoutsDao.getHydratedWorkout('s2');
    expect(hydrated, isNotNull);
    expect(hydrated!.exercises.length, 2);

    final benchEx = hydrated.exercises
        .firstWhere((e) => e.exerciseMetadata.name == 'Bench Press');
    expect(benchEx.sets.length, 1);
    expect(benchEx.sets.first.weightKg, 82.5);

    // Previous-session CTE: s1's bench sets, ordered.
    expect(benchEx.previousSets.length, 2);
    expect(benchEx.previousSets.first.weightKg, 80);
    expect(benchEx.previousSets.last.weightKg, 85);

    // Missing session → null, not a throw (detail screen shows not-found).
    expect(await db.workoutsDao.getHydratedWorkout('nope'), isNull);
  });

  test('getHydratedWorkout survives a session with zero exercises', () async {
    await db.workoutsDao.insertSession(WorkoutSessionsCompanion(
      id: const Value('empty'),
      userId: const Value(userId),
      startedAt: Value(DateTime(2026, 6, 1)),
      endedAt: Value(DateTime(2026, 6, 1, 1)),
    ));
    final hydrated = await db.workoutsDao.getHydratedWorkout('empty');
    expect(hydrated, isNotNull);
    expect(hydrated!.exercises, isEmpty);
  });

  test('getSessionPreviewsForUser batches stats + top exercises', () async {
    final bench =
        await insertExercise('Bench Press', 'chest', 'barbell', 'pectorals');
    final squat =
        await insertExercise('Squat', 'upper legs', 'barbell', 'quadriceps');
    final row = await insertExercise('Row', 'back', 'barbell', 'lats');

    await insertSession('s1', DateTime(2026, 6, 1, 10),
        sets: [(bench, 80, 8), (squat, 100, 5), (row, 60, 10)]);
    await insertSession('s2', DateTime(2026, 6, 8, 10), sets: [(bench, 85, 8)]);

    final previews = await db.workoutsDao
        .getSessionPreviewsForUser(userId, limit: 10, offset: 0);
    expect(previews.length, 2);
    expect(previews.first.session.id, 's2'); // newest first
    expect(previews.last.totalExerciseCount, 3);
    expect(previews.last.topExercises.length, 2); // capped at 2
    expect(previews.last.topExercises.first.exerciseName, 'Bench Press');
    expect(previews.last.topExercises.first.setCount, 1);
    expect(previews.last.totalVolumeKg, 80 * 8 + 100 * 5 + 60 * 10);
  });

  test('detectAndMarkPrs fires on a fresh database and returns records',
      () async {
    final bench =
        await insertExercise('Bench Press', 'chest', 'barbell', 'pectorals');

    await insertSession('s1', DateTime(2026, 6, 1, 10), sets: [(bench, 80, 8)]);
    final prs1 =
        await db.workoutsDao.detectAndMarkPrs('s1', DateTime(2026, 6, 1, 10));
    expect(prs1.length, 1, reason: 'first ever session must produce a PR');
    expect(prs1.first.exerciseName, 'Bench Press');
    expect(prs1.first.previousBest1rm, 0);

    // Heavier session → new PR beating the old max.
    await insertSession('s2', DateTime(2026, 6, 8, 10), sets: [(bench, 90, 8)]);
    final prs2 =
        await db.workoutsDao.detectAndMarkPrs('s2', DateTime(2026, 6, 8, 10));
    expect(prs2.length, 1);
    expect(prs2.first.previousBest1rm, greaterThan(0));

    // Lighter session → no PR.
    await insertSession('s3', DateTime(2026, 6, 15, 10),
        sets: [(bench, 60, 5)]);
    final prs3 =
        await db.workoutsDao.detectAndMarkPrs('s3', DateTime(2026, 6, 15, 10));
    expect(prs3, isEmpty);
  });

  test('exercise history honors since-filter with typed date binds', () async {
    final bench =
        await insertExercise('Bench Press', 'chest', 'barbell', 'pectorals');
    await insertSession('old', DateTime(2026, 1, 1, 10),
        sets: [(bench, 70, 8)]);
    await insertSession('new', DateTime(2026, 6, 8, 10),
        sets: [(bench, 85, 8)]);

    final all = await db.workoutsDao.getExerciseHistory(bench);
    expect(all.length, 2);

    final ranged = await db.workoutsDao
        .watchExerciseHistory(bench, since: DateTime(2026, 3, 1))
        .first;
    expect(ranged.length, 1, reason: 'int >= iso-string would return 0 rows');
    expect(ranged.first.weight, 85);
  });

  test('exercise history best-1RM uses per-set Epley, not MAX(w)×MAX(reps)',
      () async {
    // Regression: a heavy single + a light burnout set in the same session.
    // The old query took MAX(weight)=100 and MAX(reps)=15 from DIFFERENT sets
    // and fed both into Epley → 100×(1+15/30)=150kg, a 50% overstatement.
    // The correct value is the best PER-SET estimate: max(epley(100,1)=100,
    // epley(40,15)=60) = 100.
    final bench =
        await insertExercise('Bench Press', 'chest', 'barbell', 'pectorals');
    await insertSession('mix', DateTime(2026, 6, 1, 10),
        sets: [(bench, 100, 1), (bench, 40, 15)]);

    final history = await db.workoutsDao.getExerciseHistory(bench);
    expect(history.length, 1);
    expect(history.first.estimated1RM, closeTo(100.0, 0.001),
        reason: 'best per-set Epley, not epley(maxWeight, maxReps)=150');
    expect(history.first.weight, 100); // heaviest weight that session
    expect(history.first.volume, 100 * 1 + 40 * 15); // 700
  });

  test('detectAndMarkPrs fires for a genuine heavier single (1-rep guard)',
      () async {
    // Regression: the historical-max SQL used raw Epley (w×31/30 at 1 rep),
    // inflating a prior 100kg×1 to 103.33, while the new set was scored with
    // the guarded _epley (=102). 102 > 103.33 was false, so a real +2kg single
    // PR was silently missed. Both sides must use the same reps<=1 guard.
    final bench =
        await insertExercise('Bench Press', 'chest', 'barbell', 'pectorals');

    await insertSession('s1', DateTime(2026, 6, 1, 10), sets: [(bench, 100, 1)]);
    final prs1 =
        await db.workoutsDao.detectAndMarkPrs('s1', DateTime(2026, 6, 1, 10));
    expect(prs1.length, 1);

    await insertSession('s2', DateTime(2026, 6, 8, 10), sets: [(bench, 102, 1)]);
    final prs2 =
        await db.workoutsDao.detectAndMarkPrs('s2', DateTime(2026, 6, 8, 10));
    expect(prs2.length, 1, reason: 'a +2kg single over a prior single is a PR');
    expect(prs2.first.previousBest1rm, closeTo(100.0, 0.001),
        reason: 'prior 1-rep max must be 100, not the inflated 103.33');
    expect(prs2.first.estimated1rm, closeTo(102.0, 0.001));
  });

  test('deleteSession cascades sets + exercises with FKs enforced', () async {
    final bench =
        await insertExercise('Bench Press', 'chest', 'barbell', 'pectorals');
    await insertSession('s1', DateTime(2026, 6, 1, 10), sets: [(bench, 80, 8)]);

    await db.workoutsDao.deleteSession('s1');

    final orphanSets = await db
        .customSelect('SELECT COUNT(*) c FROM workout_sets')
        .getSingle();
    final orphanWes = await db
        .customSelect('SELECT COUNT(*) c FROM workout_exercises')
        .getSingle();
    expect(orphanSets.read<int>('c'), 0);
    expect(orphanWes.read<int>('c'), 0);
  });

  test('routine hydration + last-session sets + daily volume', () async {
    final bench =
        await insertExercise('Bench Press', 'chest', 'barbell', 'pectorals');
    final squat =
        await insertExercise('Squat', 'upper legs', 'barbell', 'quadriceps');

    final routineId = await db.routinesDao.createRoutine(
      userId: userId,
      name: 'Push Day',
      exercises: [
        RoutineDraftExercise(exerciseId: bench, defaultSets: 3),
        RoutineDraftExercise(exerciseId: squat, defaultSets: 2),
      ],
    );

    await insertSession('s1', DateTime(2026, 6, 1, 10),
        routineId: routineId, sets: [(bench, 80, 8), (squat, 100, 5)]);

    final hydrated =
        await db.routinesDao.watchHydratedRoutinesForUser(userId).first;
    expect(hydrated.length, 1);
    expect(hydrated.first.exerciseNames, ['Bench Press', 'Squat']);
    expect(hydrated.first.muscleTags, ['Chest', 'Upper Legs']);
    expect(hydrated.first.lastTrained, isNotNull);

    final detail = await db.routinesDao.getHydratedRoutineDetail(routineId);
    expect(detail!.exercises.length, 2);

    final lastSets = await db.workoutsDao
        .getLastSessionSetsForRoutine(routineId: routineId, userId: userId);
    expect(lastSets['$bench']!.length, 1);
    expect(lastSets['$bench']!.first.weightKg, 80);

    final volume =
        await db.workoutsDao.watchDailyVolumeForRoutine(routineId).first;
    expect(volume.length, 1);
    expect(volume.first.volume, 80 * 8 + 100 * 5);

    // Cascade delete leaves no routine children behind.
    await db.routinesDao.deleteRoutine(routineId);
    final days = await db
        .customSelect('SELECT COUNT(*) c FROM routine_days')
        .getSingle();
    expect(days.read<int>('c'), 0);
  });
}
