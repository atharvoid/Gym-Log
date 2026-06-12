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

  /// Returns null instead of throwing when user has no local profile yet.
  Future<UserProfile?> getUserOrNull(String id) async {
    final results =
        await (select(userProfiles)..where((t) => t.id.equals(id))).get();
    return results.isEmpty ? null : results.first;
  }

  /// Reactive stream of the user profile — updates instantly on DB writes.
  Stream<UserProfile?> watchUser(String id) {
    return (select(userProfiles)..where((t) => t.id.equals(id)))
        .watchSingleOrNull();
  }

  /// Targeted premium-entitlement write. Used by PremiumService to mirror
  /// RevenueCat customer info into the local offline cache.
  Future<void> setPremiumStatus(
    String id, {
    required bool isPremium,
    DateTime? premiumExpiry,
  }) {
    return (update(userProfiles)..where((t) => t.id.equals(id)))
        .write(UserProfilesCompanion(
      isPremium: Value(isPremium),
      premiumExpiry: Value(premiumExpiry),
    ));
  }
}
