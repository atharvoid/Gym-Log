import 'package:drift/drift.dart';
import '../database.dart';
import '../tables/user_profiles_table.dart';

part 'user_dao.g.dart';

@DriftAccessor(tables: [UserProfiles])
class UserDao extends DatabaseAccessor<AppDatabase> with _$UserDaoMixin {
  UserDao(super.db);

  Future<UserProfile> getUser(String id) {
    return (select(userProfiles)..where((t) => t.id.equals(id))).getSingle();
  }

  Future<void> insertUser(UserProfilesCompanion user) {
    return into(userProfiles).insert(user);
  }

  Future<void> updateUser(UserProfilesCompanion user) {
    return (update(userProfiles)).replace(user);
  }

  Future<void> deleteUser(String id) {
    return (delete(userProfiles)..where((t) => t.id.equals(id))).go();
  }
}
