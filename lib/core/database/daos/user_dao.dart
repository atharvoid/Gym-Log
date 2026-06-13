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

  /// Inserts the profile if absent, otherwise updates ONLY identity fields
  /// (displayName, email) — preferences like weightUnit, rest timer and
  /// premium status are preserved. This is the local mirror of the remote
  /// profile, written on onboarding and on every login-time hydration.
  Future<void> upsertProfile({
    required String id,
    required String email,
    required String displayName,
  }) async {
    final existing = await getUserOrNull(id);
    if (existing == null) {
      await into(userProfiles).insert(UserProfilesCompanion.insert(
        id: id,
        email: email,
        displayName: displayName,
        createdAt: DateTime.now(),
      ));
    } else {
      await (update(userProfiles)..where((t) => t.id.equals(id))).write(
        UserProfilesCompanion(
          displayName: Value(displayName),
          email: Value(email),
        ),
      );
    }
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

  /// Global weight-unit preference ('kg' | 'lbs'). Display-only — stored
  /// workout data remains kilograms forever.
  Future<void> setWeightUnit(String id, String unit) {
    return (update(userProfiles)..where((t) => t.id.equals(id)))
        .write(UserProfilesCompanion(weightUnit: Value(unit)));
  }

  /// Default rest-timer duration between sets.
  Future<void> setDefaultRestSeconds(String id, int seconds) {
    return (update(userProfiles)..where((t) => t.id.equals(id)))
        .write(UserProfilesCompanion(defaultRestSeconds: Value(seconds)));
  }
}
