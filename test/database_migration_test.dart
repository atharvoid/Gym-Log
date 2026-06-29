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

      // Create other tables referenced by beforeOpen index statements
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
          'CREATE TABLE sync_outbox (user_id TEXT, created_at_ms INTEGER);');

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
}

class _DummyQueryExecutorUser extends QueryExecutorUser {
  @override
  int get schemaVersion => 2;

  @override
  Future<void> beforeOpen(
      QueryExecutor executor, OpeningDetails details) async {}
}
