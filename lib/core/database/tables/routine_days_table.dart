import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import 'routines_table.dart';

@DataClassName('RoutineDay')
class RoutineDays extends Table {
  TextColumn get id => text().clientDefault(() => const Uuid().v4())();
  TextColumn get routineId => text().references(Routines, #id)();
  TextColumn get name => text()();
  IntColumn get orderIndex => integer()();

  @override
  Set<Column> get primaryKey => {id};
}
