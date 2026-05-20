import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gymlog/core/database/database.dart';
import 'package:gymlog/core/providers/database_provider.dart';
import 'package:gymlog/features/auth/presentation/providers/auth_provider.dart';

final recentWorkoutsProvider = FutureProvider<List<WorkoutSession>>((ref) async {
  final user = ref.watch(authProvider);
  if (user == null) return [];
  final db = ref.watch(databaseProvider);
  final sessions = await db.workoutsDao.getSessionsForUser(user.id);
  sessions.sort((a, b) => b.startedAt.compareTo(a.startedAt));
  return sessions.take(5).toList();
});
