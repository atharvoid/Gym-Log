import 'dart:ffi';
import 'dart:io';

import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymlog/core/database/database.dart';
import 'package:sqlite3/open.dart';
import 'package:path/path.dart' as p;

void main() {
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

  group('Database v2 to v3 migration', () {
    test('creates new columns and backfills onboardingComplete correctly',
        () async {
      // Create a temporary file database
      final tempDir = Directory.systemTemp.createTempSync('gymlog_test');
      final dbFile = File(p.join(tempDir.path, 'migration_test.db'));
      final executor = NativeDatabase(dbFile);

      // We open a raw connection to set up the v2 schema.
      await executor.ensureOpen(
        _DummyQueryExecutorUser(),
      );

      // Create user_profiles table matching v2 schema
      await executor.runCustom('''
        CREATE TABLE user_profiles (
          id TEXT NOT NULL PRIMARY KEY,
          email TEXT NOT NULL,
          display_name TEXT NOT NULL,
          is_premium INTEGER NOT NULL DEFAULT 0,
          premium_expiry INTEGER,
          weight_unit TEXT NOT NULL DEFAULT 'kg',
          default_rest_seconds INTEGER NOT NULL DEFAULT 90,
          created_at INTEGER NOT NULL
        );
      ''');

      await executor.runCustom(
          'CREATE TABLE exercises (id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, exercise_db_id TEXT, name TEXT, body_part TEXT, equipment TEXT, target TEXT, gif_url TEXT, secondary_muscles TEXT, instructions TEXT, is_custom INTEGER NOT NULL DEFAULT 0, created_by TEXT, seeded_at INTEGER);');
      await executor.runCustom(
          'CREATE TABLE workout_exercises (session_id TEXT, exercise_id TEXT);');
      await executor.runCustom(
          'CREATE TABLE workout_sets (workout_exercise_id TEXT, exercise_id TEXT);');
      await executor.runCustom(
          'CREATE TABLE workout_sessions (user_id TEXT, started_at INTEGER, routine_id TEXT);');
      await executor
          .runCustom('CREATE TABLE routine_exercises (routine_day_id TEXT);');
      await executor.runCustom('CREATE TABLE routine_days (routine_id TEXT);');
      await executor.runCustom(
          'CREATE TABLE sync_outbox (id INTEGER PRIMARY KEY AUTOINCREMENT, entity_type TEXT, entity_id TEXT, user_id TEXT, op TEXT, payload TEXT, updated_at_ms INTEGER, created_at_ms INTEGER);');

      await executor.runCustom('PRAGMA user_version = 2;');

      // Insert two profiles in v2 state:
      // - user-1: has display_name (should be backfilled to onboardingComplete = true)
      // - user-2: has empty display_name (should remain false/default)
      final now = DateTime.now().millisecondsSinceEpoch;
      await executor.runCustom('''
        INSERT INTO user_profiles (id, email, display_name, created_at)
        VALUES ('user-1', 'user1@test.com', 'User One', $now);
      ''');
      await executor.runCustom('''
        INSERT INTO user_profiles (id, email, display_name, created_at)
        VALUES ('user-2', 'user2@test.com', '', $now);
      ''');

      // Close connection to allow AppDatabase to open it and run migration
      await executor.close();

      // 2. Open AppDatabase (v3) using the same database file.
      // This will trigger onUpgrade from v2 to v3 because it's a new executor instance.
      final testExecutor = NativeDatabase(dbFile);
      final db = AppDatabase.forTesting(testExecutor);

      // Fetch user profiles and verify columns exist and are backfilled correctly
      final user1 = await db.userDao.getUser('user-1');
      expect(user1.displayName, 'User One');
      expect(user1.onboardingComplete, isTrue);
      expect(user1.age, isNull);
      expect(user1.experienceLevel, isNull);

      final user2 = await db.userDao.getUser('user-2');
      expect(user2.displayName, '');
      expect(user2.onboardingComplete, isFalse);

      await db.close();

      // Clean up temp dir
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });
  });

  group('Database v4 to v5 migration', () {
    test(
        'adds measurement_type column, backfills bodyweight exercises, and makes weight_kg nullable',
        () async {
      final tempDir = Directory.systemTemp.createTempSync('gymlog_v5_test');
      final dbFile = File(p.join(tempDir.path, 'migration_v5_test.db'));
      final executor = NativeDatabase(dbFile);

      await executor.ensureOpen(_DummyQueryExecutorUser());

      await executor.runCustom('''
        CREATE TABLE exercises (
          id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
          exercise_db_id TEXT UNIQUE,
          name TEXT NOT NULL,
          body_part TEXT NOT NULL,
          equipment TEXT NOT NULL,
          target TEXT NOT NULL,
          gif_url TEXT,
          secondary_muscles TEXT,
          instructions TEXT,
          is_custom INTEGER NOT NULL DEFAULT 0,
          created_by TEXT,
          seeded_at INTEGER
        );
      ''');

      await executor.runCustom('''
        CREATE TABLE workout_sets (
          id TEXT NOT NULL PRIMARY KEY,
          workout_exercise_id TEXT NOT NULL,
          exercise_id INTEGER NOT NULL,
          order_index INTEGER NOT NULL,
          set_type TEXT NOT NULL DEFAULT 'normal',
          weight_kg REAL NOT NULL,
          reps INTEGER NOT NULL,
          rpe REAL,
          is_pr INTEGER NOT NULL DEFAULT 0,
          estimated1rm REAL,
          completed_at INTEGER
        );
      ''');

      await executor.runCustom('''
        CREATE TABLE user_profiles (
          id TEXT NOT NULL PRIMARY KEY,
          email TEXT NOT NULL,
          display_name TEXT NOT NULL,
          is_premium INTEGER NOT NULL DEFAULT 0,
          created_at INTEGER NOT NULL
        );
      ''');
      await executor.runCustom(
          'CREATE TABLE workout_exercises (session_id TEXT, exercise_id TEXT);');
      await executor.runCustom(
          'CREATE TABLE workout_sessions (user_id TEXT, started_at INTEGER, routine_id TEXT);');
      await executor
          .runCustom('CREATE TABLE routine_exercises (routine_day_id TEXT);');
      await executor.runCustom('CREATE TABLE routine_days (routine_id TEXT);');
      await executor.runCustom(
          'CREATE TABLE sync_outbox (id INTEGER PRIMARY KEY AUTOINCREMENT, entity_type TEXT, entity_id TEXT, user_id TEXT, op TEXT, payload TEXT, updated_at_ms INTEGER, created_at_ms INTEGER);');

      await executor.runCustom('PRAGMA user_version = 4;');

      await executor.runCustom('''
        INSERT INTO exercises (id, name, body_part, equipment, target)
        VALUES (1, 'Push-up', 'chest', 'Bodyweight', 'pectorals');
      ''');
      await executor.runCustom('''
        INSERT INTO exercises (id, name, body_part, equipment, target)
        VALUES (2, 'Bench Press', 'chest', 'Barbell', 'pectorals');
      ''');

      await executor.close();

      final testExecutor = NativeDatabase(dbFile);
      final db = AppDatabase.forTesting(testExecutor);

      final ex1 = await db.exercisesDao.getExerciseById(1);
      expect(ex1.measurementType, 'reps_only');

      final ex2 = await db.exercisesDao.getExerciseById(2);
      expect(ex2.measurementType, 'weight_and_reps');

      await db.close();

      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });
  });
}

class _DummyQueryExecutorUser extends QueryExecutorUser {
  @override
  int get schemaVersion => 2;

  @override
  Future<void> beforeOpen(
      QueryExecutor executor, OpeningDetails details) async {}
}
