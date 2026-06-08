import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/database/database.dart';
import '../../../../core/providers/database_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

final recentWorkoutsProvider = FutureProvider<List<WorkoutSession>>((ref) async {
  final user = ref.watch(authProvider);
  if (user == null) return [];
  final db = ref.watch(databaseProvider);
  final sessions = await db.workoutsDao.getSessionsForUser(user.id);
  // Sort by startedAt DESC and take 5
  sessions.sort((a, b) => b.startedAt.compareTo(a.startedAt));
  return sessions.take(5).toList();
});
