// ATOMIC-08: IMPORT-CLUSTER regressions — IM-A, IM-B, IM-C, CP-A, CP-B,
// CP-C, IM-H, IM-I and IM-2, each with a failing-test-first regression.
//
// Importing these from the audit queue:
//   IM-A  Strong unitless files default to kg (never the display pref)
//   IM-B  progress count = importable sessions (dups silent)
//   IM-C  cancel mid-import returns partial result
//   CP-A  GymLog v2 rows run the metric validator (warn + skip, not silent)
//   CP-B  UTC export datetimes parse back as local wall-clock
//   CP-C  session grouping is case-insensitive
//   IM-H  custom exercises roll back with a failing session transaction
//   IM-I  mid-import failure surfaces the real partial count
//   IM-2  GymLog v2 template CSV round-trips through the parser

import 'dart:ffi';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymlog/core/database/database.dart';
import 'package:gymlog/core/models/measurement_type.dart';
import 'package:gymlog/core/services/workout_export_service.dart';
import 'package:gymlog/features/import/data/workout_csv_parser.dart';
import 'package:gymlog/features/import/data/workout_import_service.dart';
import 'package:gymlog/features/import/domain/import_models.dart';
import 'package:sqlite3/open.dart';

void main() {
  late AppDatabase db;
  late WorkoutImportService service;
  const userId = 'user-import-cluster';

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
  });

  tearDown(() async => db.close());

  group('CP-A: GymLog v2 rows are metric-validated (no silent garbage)', () {
    test('a weight_and_reps row missing weight warns and skips', () {
      const csv =
          'gymlog_schema_version,workout_id,workout_name,workout_started_at,'
          'exercise_name,measurement_type,set_index,set_type,weight_kg,reps\n'
          '2,w-1,Full Body,2026-07-01T10:00:00.000Z,Bench Press,'
          'weight_and_reps,0,normal,,10';

      final result = WorkoutCsvParser.parse(csv);

      expect(result.skippedRows, 1);
      expect(result.warnings.first,
          contains('weight is missing for Bench Press.'));
      expect(result.sessions, isEmpty);
    });

    test('a reps_only row missing reps warns and skips', () {
      const csv =
          'gymlog_schema_version,workout_id,workout_name,workout_started_at,'
          'exercise_name,measurement_type,set_index,set_type,reps\n'
          '2,w-1,Leg Day,2026-07-01T10:00:00.000Z,Push Up,reps_only,0,normal,';

      final result = WorkoutCsvParser.parse(csv);

      expect(result.skippedRows, 1);
      expect(result.warnings.first, contains('reps are missing for Push Up.'));
    });
  });

  group('CP-B: UTC export dates come back as local wall-clock', () {
    test('UTC-suffixed startedAt is converted to local on parse', () {
      const csv =
          'gymlog_schema_version,workout_id,workout_name,workout_started_at,'
          'exercise_name,set_index,set_type,weight_kg,reps\n'
          '2,w-1,Morning Run,2026-07-20T10:00:00.000Z,Push Up,0,normal,,15';

      final result = WorkoutCsvParser.parse(csv);

      final start = result.sessions.single.startedAt;
      expect(start.isUtc, isFalse,
          reason: 'stored sessions must be local, matching live logging');
      // The exact instant is preserved: 10:00Z == local wall clock + offset.
      expect(start.toUtc(), DateTime.utc(2026, 7, 20, 10, 0));
    });
  });

  group('CP-C: case-insensitive session grouping', () {
    test('same workout name in different case collapses to one session', () {
      const csv =
          'gymlog_schema_version,workout_id,workout_name,workout_started_at,'
          'exercise_name,set_index,set_type,weight_kg,reps\n'
          '2,w-1,Leg Day,2026-07-01T10:00:00.000Z,Squat,0,normal,100,5\n'
          '2,w-2,leg day,2026-07-01T10:00:00.000Z,Squat,1,normal,120,5';

      final result = WorkoutCsvParser.parse(csv);

      expect(result.sessions.length, 1);
      expect(result.sessions.single.exercises.single.sets.length, 2);
      expect(result.sessions.single.name, 'Leg Day');
    });
  });

  group('IM-A: kg is the default assumed unit', () {
    test('parser defaults a unitless Strong file to kg', () {
      const csv = '''
Date;Workout Name;Exercise Name;Set Order;Weight;Reps;Notes
2026-06-30 19:56:00;Monday;Push Up;1;;20;''';

      final parsed = WorkoutCsvParser.parse(csv);
      expect(parsed.weightUnitAssumed, isTrue);
      expect(parsed.assumedUnit, 'kg');
    });
  });

  group('IM-B: progress counts only importable sessions', () {
    test('a duplicate does not move the progress counter', () async {
      await service.import(hevySquatOnlyCsv, userId: userId);
      final progress = <(int, int)>[];
      final result = await service.import(
        squatThenPushUpCsv,
        userId: userId,
        onProgress: (d, t) => progress.add((d, t)),
      );

      expect(result.sessionsImported, 1);
      expect(result.sessionsSkipped, 1);
      expect(progress, const [(1, 1)],
          reason: 'total must be the importable count, dups not counted');
    });

    test('two fresh sessions report 2 of 2', () async {
      final progress = <(int, int)>[];
      await service.import(
        squatThenPushUpCsv,
        userId: userId,
        onProgress: (d, t) => progress.add((d, t)),
      );
      expect(progress, const [(1, 2), (2, 2)]);
    });
  });

  group('IM-C: cancel mid-import returns partial result', () {
    test('isCancelled after the first session stops the rest', () async {
      final progress = <(int, int)>[];
      final result = await service.import(
        squatThenPushUpCsv,
        userId: userId,
        onProgress: (d, t) => progress.add((d, t)),
        isCancelled: () => progress.isNotEmpty,
      );

      expect(result.cancelled, isTrue);
      expect(result.sessionsImported, 1);
      expect(progress, const [(1, 2)]);
    });
  });

  group('IM-H: custom exercises roll back with a failing session', () {
    test('a failed session transaction leaves no orphan custom exercise',
        () async {
      final db2 = FailingDb(NativeDatabase.memory());
      db2.failOnNthTransaction = 1;
      final svc2 = WorkoutImportService(db2);

      final result = await svc2.import(hevyUnicornCsv, userId: userId);

      expect(result.failure, isNotNull,
          reason: 'mid-import failure must surface partial state');
      expect(result.sessionsImported, 0);

      // The custom exercise created inside the failed txn must be gone.
      final exercises = await db2.exercisesDao.getAllExercises(userId: userId);
      expect(
          exercises.any((e) => e.name == 'Unicorn Hollow (Barbell)'), isFalse,
          reason:
              'custom exercise created in a rolled-back txn must not persist');

      await db2.close();
    });
  });

  group('IM-I: honest partial-import reporting', () {
    test('first session commits, second fails, partial result kept', () async {
      final db2 = FailingDb(NativeDatabase.memory());
      // Transactions: session "First" (txn 1) succeeds, "Second" (txn 2) fails.
      db2.failOnNthTransaction = 2;
      final svc2 = WorkoutImportService(db2);

      final result = await svc2.import(firstThenSecondCsv, userId: userId);

      expect(result.sessionsImported, 1,
          reason: 'the first committed session is real partial progress');
      expect(result.failure, isNotNull);

      final sessions = await db2.workoutsDao.getSessionsForUser(userId);
      expect(sessions.length, 1);
      expect(sessions.single.name, 'First');

      await db2.close();
    });
  });

  group('IM-2: template CSV round-trips', () {
    test('template parses as GymLog v2 with one weight_and_reps set', () {
      final template = WorkoutExportService.buildTemplateCsv();
      final result = WorkoutCsvParser.parse(template);
      expect(result.source, ImportSource.gymlog);
      expect(result.sessions.length, 1);
      final s = result.sessions.single;
      expect(s.name, 'Example Workout');
      final set = s.exercises.single.sets.single;
      expect(set.measurementType, MeasurementType.weightAndReps);
      expect(set.weightKg, 60.0);
      expect(set.reps, 10);
      expect(set.setType, SetTypes.normal);
    });
  });
}

const hevyHeader =
    '"title","start_time","exercise_title","set_index","set_type","weight_kg","reps"';

const hevySquatOnlyCsv = '$hevyHeader\n'
    '"Solo","10 Jun 2025, 08:00","Squat",0,"normal",60,5';

const squatThenPushUpCsv = '$hevyHeader\n'
    '"Solo","10 Jun 2025, 08:00","Squat",0,"normal",60,5\n'
    '"Second","11 Jun 2025, 08:00","Push Up",0,"normal",70,10';

const firstThenSecondCsv =
    'gymlog_schema_version,workout_id,workout_name,workout_started_at,'
    'exercise_name,set_index,set_type,weight_kg,reps\n'
    '2,w-1,First,2026-07-01T08:00:00.000Z,Squat,0,normal,100,5\n'
    '2,w-2,Second,2026-07-02T08:00:00.000Z,Squat,0,normal,100,5';

const hevyUnicornCsv = '$hevyHeader\n'
    '"Broken","10 Jul 2025, 08:00","Unicorn Hollow (Barbell)",0,"normal",100,5';

/// An [AppDatabase] that aborts the Nth [transaction] it opens, after the
/// transaction body has run — exercising rollback of work done inside it.
class FailingDb extends AppDatabase {
  FailingDb(super.executor) : super.forTesting();

  /// 1-based; -1 disables. When the Nth transaction's body finishes, an
  /// exception is thrown so Drift rolls the whole transaction back.
  int failOnNthTransaction = -1;
  int _openCount = 0;

  @override
  Future<T> transaction<T>(Future<T> Function() action,
      {bool requireNew = false}) async {
    _openCount++;
    if (_openCount == failOnNthTransaction) {
      return super.transaction<T>(() async {
        await action();
        throw StateError('forced write failure');
      }, requireNew: requireNew);
    }
    return super.transaction<T>(action, requireNew: requireNew);
  }
}
