// End-to-end import test against a real in-memory SQLite database. Proves the
// service writes correct rows, converts units to kg, creates custom exercises
// for unmatched names, detects PRs, and is idempotent on re-import.

import 'dart:ffi';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymlog/core/database/database.dart';
import 'package:gymlog/features/import/data/workout_import_service.dart';
import 'package:sqlite3/open.dart';

import 'import_fixtures.dart';

void main() {
  late AppDatabase db;
  late WorkoutImportService service;
  const userId = 'user-1';

  setUpAll(() {
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

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    service = WorkoutImportService(db);
    // Seed two catalog exercises so we can assert matched-vs-created behaviour.
    await db.exercisesDao.insertExercise(ExercisesCompanion.insert(
      name: 'Bench Press (Dumbbell)',
      bodyPart: 'chest',
      equipment: 'dumbbell',
      target: 'pectorals',
    ));
    await db.exercisesDao.insertExercise(ExercisesCompanion.insert(
      name: 'Face Pull',
      bodyPart: 'shoulders',
      equipment: 'cable',
      target: 'delts',
    ));
  });

  tearDown(() async => db.close());

  Future<double> totalStoredVolume() async {
    final sessions = await db.workoutsDao.getSessionsForUser(userId);
    return sessions.fold<double>(0.0, (s, x) => s + x.totalVolumeKg);
  }

  test('imports the Hevy export into the local database', () async {
    final r = await service.import(hevySampleCsv, userId: userId);

    expect(r.sessionsImported, 2);
    expect(r.setsImported, 22);
    expect(r.sessionsSkipped, 0);

    // 8 distinct exercises; 2 pre-seeded → 6 created as custom.
    expect(r.exercisesMatched, 2);
    expect(r.exercisesCreated.length, 6);
    expect(r.exercisesCreated, contains('Lower Chest Fly'));

    // Every exercise's first all-time appearance is a PR (8 total).
    expect(r.prsDetected, 8);

    // Stored volume matches the parsed total.
    expect(await totalStoredVolume(), closeTo(9483.0, 0.01));

    // Sessions are completed (endedAt set) so they count in history.
    final count = await db.workoutsDao.watchWorkoutCountForUser(userId).first;
    expect(count, 2);
  });

  test('stores weights in kilograms when importing a Strong (lbs) export',
      () async {
    final r = await service.import(strongSampleCsv, userId: userId);
    expect(r.sessionsImported, 2);
    expect(r.setsImported, 22);
    // Same workouts as Hevy, logged in lbs → same kg volume within rounding.
    expect(await totalStoredVolume(), closeTo(9481.31, 0.5));
  });

  test('re-importing the same file is idempotent', () async {
    await service.import(hevySampleCsv, userId: userId);
    final again = await service.import(hevySampleCsv, userId: userId);

    expect(again.sessionsImported, 0);
    expect(again.sessionsSkipped, 2);

    // No duplicate sessions or custom exercises were created.
    final sessions = await db.workoutsDao.getSessionsForUser(userId);
    expect(sessions.length, 2);
    final exercises = await db.exercisesDao.getAllExercises();
    expect(exercises.where((e) => e.isCustom).length, 6);
  });

  test('preview reports the same shape without writing anything', () async {
    final summary = await service.preview(hevySampleCsv, userId: userId);

    expect(summary.sessionCount, 2);
    expect(summary.newSessionCount, 2);
    expect(summary.setCount, 22);
    expect(summary.exerciseCount, 8);
    expect(summary.newExerciseNames.length, 6);
    expect(summary.totalVolumeKg, closeTo(9483.0, 0.01));

    // Nothing was persisted by preview.
    final sessions = await db.workoutsDao.getSessionsForUser(userId);
    expect(sessions, isEmpty);
  });
}
