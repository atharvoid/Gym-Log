import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import 'routine_days_table.dart';
import 'exercises_table.dart';

@DataClassName('RoutineExercise')
class RoutineExercises extends Table {
  TextColumn get id => text().clientDefault(() => const Uuid().v4())();
  TextColumn get routineDayId => text().references(RoutineDays, #id)();
  IntColumn get exerciseId => integer().references(Exercises, #id)();
  IntColumn get orderIndex => integer()();
  IntColumn get defaultSets => integer().withDefault(const Constant(3))();
  IntColumn get defaultReps => integer().nullable()();
  RealColumn get defaultWeightKg => real().nullable()();
  IntColumn get restSeconds => integer().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
