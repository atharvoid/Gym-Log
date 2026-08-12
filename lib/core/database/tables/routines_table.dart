import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

@DataClassName('Routine')
class Routines extends Table {
  TextColumn get id => text().clientDefault(() => const Uuid().v4())();
  TextColumn get userId => text()();
  TextColumn get name => text()();
  TextColumn get notes => text().withDefault(const Constant(''))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  /// The name of the source program when this Routine was imported as one
  /// day of a multi-day program (e.g. a 6-day PPL import creates 6 Routines
  /// each tagged with `sourceProgramName = "Push Pull Legs: 6-Day …"`).
  /// NULL for all routines that were NOT created via a program import,
  /// including every routine created before schema v6.
  /// Phase 2: group routines sharing this value under a collapsible folder.
  TextColumn get sourceProgramName => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
