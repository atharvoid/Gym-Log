import 'package:drift/drift.dart';

@DataClassName('UserProfile')
class UserProfiles extends Table {
  TextColumn get id => text()();
  TextColumn get email => text()();
  TextColumn get displayName => text()();
  BoolColumn get isPremium => boolean().withDefault(const Constant(false))();
  DateTimeColumn get premiumExpiry => dateTime().nullable()();
  TextColumn get weightUnit => text().withDefault(const Constant('kg'))();
  IntColumn get defaultRestSeconds => integer().withDefault(const Constant(90))();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
