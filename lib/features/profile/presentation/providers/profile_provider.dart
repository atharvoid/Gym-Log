import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gymlog/core/database/database.dart';
import 'package:gymlog/core/providers/database_provider.dart';
import 'package:gymlog/features/auth/presentation/providers/auth_provider.dart';

/// Live count of completed workout sessions for the current user.
final workoutCountProvider = StreamProvider<int>((ref) {
  final user = ref.watch(authProvider);
  if (user == null) return Stream.value(0);
  final db = ref.watch(databaseProvider);
  return db.workoutsDao.watchWorkoutCountForUser(user.id);
});

/// Live profile row for the current user from the local SQLite DB.
final currentUserProfileProvider = StreamProvider<UserProfile?>((ref) {
  final user = ref.watch(authProvider);
  if (user == null) return Stream.value(null);
  final db = ref.watch(databaseProvider);
  return db.userDao.watchUser(user.id);
});
