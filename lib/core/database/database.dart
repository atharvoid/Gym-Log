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
import 'daos/user_dao.dart';
import 'daos/exercises_dao.dart';
import 'daos/workouts_dao.dart';
import 'daos/routines_dao.dart';

part 'database.g.dart';

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
  ],
  daos: [UserDao, ExercisesDao, WorkoutsDao, RoutinesDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  /// Used by widget/unit tests to run against an in-memory database.
  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
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
        },
      );

  static QueryExecutor _openConnection() {
    return LazyDatabase(() async {
      final dbFolder = await getApplicationDocumentsDirectory();
      final file = File(p.join(dbFolder.path, 'gymlog_db.sqlite'));
      return NativeDatabase.createInBackground(file);
    });
  }
}
