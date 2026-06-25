import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import 'exercises_table.dart';

@DataClassName('WorkoutSession')
class WorkoutSessions extends Table {
  TextColumn get id => text().clientDefault(() => const Uuid().v4())();
  TextColumn get userId => text()();
  TextColumn get routineId => text().nullable()();
  TextColumn get name => text().nullable()();
  DateTimeColumn get startedAt => dateTime()();
  DateTimeColumn get endedAt => dateTime().nullable()();
  TextColumn get notes => text().withDefault(const Constant(''))();
  RealColumn get totalVolumeKg => real().withDefault(const Constant(0))();
  BoolColumn get synced => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('WorkoutExercise')
class WorkoutExercises extends Table {
  TextColumn get id => text().clientDefault(() => const Uuid().v4())();
  TextColumn get sessionId => text().references(WorkoutSessions, #id)();
  IntColumn get exerciseId => integer().references(Exercises, #id)();
  IntColumn get orderIndex => integer()();
  TextColumn get notes => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('WorkoutSet')
class WorkoutSets extends Table {
  TextColumn get id => text().clientDefault(() => const Uuid().v4())();
  TextColumn get workoutExerciseId =>
      text().references(WorkoutExercises, #id)();
  IntColumn get exerciseId => integer()();
  IntColumn get orderIndex => integer()();
  TextColumn get setType => text().withDefault(const Constant('normal'))();
  RealColumn get weightKg => real()();
  IntColumn get reps => integer()();
  RealColumn get rpe => real().nullable()();
  BoolColumn get isPr => boolean().withDefault(const Constant(false))();
  RealColumn get estimated1rm => real().nullable()();
  DateTimeColumn get completedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
