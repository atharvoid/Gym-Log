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

  @override
  int get schemaVersion => 1;

  static QueryExecutor _openConnection() {
    return LazyDatabase(() async {
      final dbFolder = await getApplicationDocumentsDirectory();
      final file = File(p.join(dbFolder.path, 'gymlog_db.sqlite'));
      return NativeDatabase.createInBackground(file);
    });
  }
}
