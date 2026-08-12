import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';
import 'tables/user_profiles_table.dart';
import 'tables/exercises_table.dart';
import 'tables/routines_table.dart';
import 'tables/routine_days_table.dart';
import 'tables/routine_exercises_table.dart';
import 'tables/workouts_table.dart';
import 'tables/sync_outbox_table.dart';
import 'daos/user_dao.dart';
import 'daos/exercises_dao.dart';
import 'daos/workouts_dao.dart';
import 'daos/routines_dao.dart';
import 'daos/sync_outbox_dao.dart';

part 'database.g.dart';

const int kDatabaseSchemaVersion = 6;

@DriftDatabase(
  tables: [
    UserProfiles,
    Exercises,
    Routines,
    RoutineDays,
    RoutineExercises,
    WorkoutSessions,
    WorkoutExercises,
    WorkoutSets,
    SyncOutbox,
  ],
  daos: [UserDao, ExercisesDao, WorkoutsDao, RoutinesDao, SyncOutboxDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  /// Used by widget/unit tests to run against an in-memory database.
  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => kDatabaseSchemaVersion;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onUpgrade: (m, from, to) async {
          // v1 → v2: add the local sync queue. This ONLY creates a brand-new
          // table — no existing table is altered, so user data is untouched
          // and the upgrade is non-destructive.
          if (from < 2) {
            await m.createTable(syncOutbox);
          }
          if (from < 3) {
            await m.addColumn(userProfiles, userProfiles.age);
            await m.addColumn(userProfiles, userProfiles.experienceLevel);
            await m.addColumn(userProfiles, userProfiles.onboardingComplete);
            // backfill: existing named users are already "done"
            await customStatement(
                "UPDATE user_profiles SET onboarding_complete = 1 WHERE display_name <> ''");
          }
          if (from < 4) {
            await m.addColumn(userProfiles, userProfiles.gender);
          }
          if (from < 5) {
            await m.addColumn(exercises, exercises.measurementType);
            await customStatement(
                "UPDATE exercises SET measurement_type = 'reps_only' WHERE LOWER(REPLACE(equipment, ' ', '')) IN ('bodyweight', 'assisted')");
            // ignore: experimental_member_use
            await m.alterTable(TableMigration(workoutSets));
          }
          // v5 → v6: source program name grouping breadcrumb on routines.
          // Nullable TEXT — existing rows get NULL, no data loss.
          // Guard: migration-unit tests build minimal schemas without a
          // routines table; real production databases always have it.
          if (from < 6) {
            final hasRoutines = await customSelect(
              "SELECT 1 FROM sqlite_master "
              "WHERE type='table' AND name='routines'",
            ).get();
            if (hasRoutines.isNotEmpty) {
              await m.addColumn(routines, routines.sourceProgramName);
            }
          }
        },
        beforeOpen: (details) async {
          // Enforce referential integrity. SQLite ships with foreign keys
          // OFF; without this, child rows silently outlive their parents.
          await customStatement('PRAGMA foreign_keys = ON');

          // Hot-path indexes (idempotent — schema files stay untouched).
          // Every list/feed/analytics query filters or joins on these.
          await customStatement(
              'CREATE INDEX IF NOT EXISTS idx_we_session ON workout_exercises (session_id)');
          await customStatement(
              'CREATE INDEX IF NOT EXISTS idx_we_exercise ON workout_exercises (exercise_id)');
          await customStatement(
              'CREATE INDEX IF NOT EXISTS idx_ws_workout_exercise ON workout_sets (workout_exercise_id)');
          await customStatement(
              'CREATE INDEX IF NOT EXISTS idx_ws_exercise ON workout_sets (exercise_id)');
          await customStatement(
              'CREATE INDEX IF NOT EXISTS idx_sessions_user_started ON workout_sessions (user_id, started_at DESC)');
          await customStatement(
              'CREATE INDEX IF NOT EXISTS idx_sessions_routine_started ON workout_sessions (routine_id, started_at DESC)');
          await customStatement(
              'CREATE INDEX IF NOT EXISTS idx_re_day ON routine_exercises (routine_day_id)');
          await customStatement(
              'CREATE INDEX IF NOT EXISTS idx_rd_routine ON routine_days (routine_id)');
          // Sync queue drains FIFO per user.
          await customStatement(
              'CREATE INDEX IF NOT EXISTS idx_outbox_user_created ON sync_outbox (user_id, created_at_ms)');
          await customStatement(
              'CREATE UNIQUE INDEX IF NOT EXISTS idx_outbox_user_entity ON sync_outbox (user_id, entity_type, entity_id)');
          await customStatement('''
            CREATE TABLE IF NOT EXISTS sync_failures (
              object_id TEXT NOT NULL,
              user_id TEXT NOT NULL,
              entity_type TEXT NOT NULL,
              entity_id TEXT NOT NULL,
              reason TEXT NOT NULL,
              attempts INTEGER NOT NULL DEFAULT 1,
              first_seen_at_ms INTEGER NOT NULL,
              last_seen_at_ms INTEGER NOT NULL,
              sanitized_diagnostic TEXT NOT NULL DEFAULT '',
              PRIMARY KEY (object_id, user_id)
            );
          ''');
          // A6: last revision this device knows the server has for a given
          // entity. Raw table (no Drift Table object), same rationale as
          // sync_failures above — SyncEngine reads/writes it through
          // SyncOutboxDao.getRevision/setRevision so outgoing pushes stop
          // sending a hardcoded revision of 1 after the entity's first sync.
          await customStatement('''
            CREATE TABLE IF NOT EXISTS entity_revisions (
              entity_type TEXT NOT NULL,
              entity_id TEXT NOT NULL,
              user_id TEXT NOT NULL,
              revision INTEGER NOT NULL DEFAULT 0,
              PRIMARY KEY (entity_type, entity_id, user_id)
            );
          ''');
        },
      );

  /// Irreversibly deletes EVERY row in EVERY table — used by the account
  /// deletion flow. Ordered child→parent so it holds with `foreign_keys=ON`
  /// (PRAGMA toggles are no-ops inside a transaction, so correct order is the
  /// guarantee). The bundled exercise catalog is re-seeded by the caller
  /// afterwards (it clears the hydration flag, then calls hydrateFromJson),
  /// so the app stays usable if the user signs in again.
  Future<void> wipeAllData() async {
    await transaction(() async {
      await delete(workoutSets).go();
      await delete(workoutExercises).go();
      await delete(workoutSessions).go();
      await delete(routineExercises).go();
      await delete(routineDays).go();
      await delete(routines).go();
      await delete(syncOutbox).go();
      await delete(exercises).go(); // catalog + user customs
      await delete(userProfiles).go();
      // sync_failures (A5): a raw SQL table created in beforeOpen, not a
      // Drift Table object, so none of the delete(...) calls above touch it.
      // Left alone, a user's quarantined-object rows survive account
      // deletion — a data-retention gap on the deletion path — and would
      // survive any future "reset local data" flow built on this method,
      // leaving the sync-failures badge (quarantinedSyncCountProvider)
      // reporting stale counts for objects that no longer exist locally.
      await customStatement('DELETE FROM sync_failures');
      // entity_revisions (A6): same rationale — raw table, invisible to
      // delete(...), holds per-entity revision bookkeeping that is
      // meaningless once the account's data is gone and must not leak into
      // a fresh sign-in on the same device.
      await customStatement('DELETE FROM entity_revisions');
    });
  }

  static QueryExecutor _openConnection() {
    return LazyDatabase(() async {
      final dbFolder = await getApplicationDocumentsDirectory();
      final file = File(p.join(dbFolder.path, 'gymlog_db.sqlite'));
      return NativeDatabase.createInBackground(file);
    });
  }
}
