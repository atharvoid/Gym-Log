import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gymlog/core/providers/database_provider.dart';
import 'package:gymlog/core/database/daos/workouts_dao.dart';
import 'package:gymlog/core/services/sync_engine.dart';
import 'package:gymlog/features/auth/presentation/providers/auth_provider.dart';

class WorkoutActionsNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;

  WorkoutActionsNotifier(this._ref) : super(const AsyncValue.data(null));

  /// Cascades through sets → exercises → session inside the DAO transaction.
  /// The home feed reloads itself via its Drift revision stream.
  ///
  /// A deletion tombstone is written to [sync_outbox] **before** the local
  /// rows are removed so that:
  ///   1. The deletion reaches Supabase on the next sync push.
  ///   2. After a reinstall, `pull()` skips this session because
  ///      `sync_objects.deleted = true`.
  ///   3. If the app crashes between the tombstone write and the local delete,
  ///      the outbox row survives and retries the cloud deletion — the local
  ///      row is simply re-deleted next launch (idempotent).
  Future<void> deleteSession(String sessionId) async {
    state = const AsyncValue.loading();
    try {
      final db = _ref.read(databaseProvider);
      final user = _ref.read(authProvider);

      // Write tombstone BEFORE the local delete.
      if (user != null) {
        await db.syncOutboxDao.enqueue(
          entityType: 'session',
          entityId: sessionId,
          userId: user.id,
          payload: '', // empty payload signals deletion
          op: 'delete',
        );
        // Kick off an immediate flush so the tombstone reaches Supabase fast.
        unawaited(
          _ref
              .read(syncEngineProvider)
              .syncNow(user.id, reason: 'workout_deleted'),
        );
      }

      await db.workoutsDao.deleteSession(sessionId);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> saveWorkoutAsRoutine(
      HydratedWorkout workout, String routineName) async {
    state = const AsyncValue.loading();
    try {
      final db = _ref.read(databaseProvider);
      await db.routinesDao.saveWorkoutAsRoutine(
          workout.session.userId, routineName, workout.exercises);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final workoutActionsProvider =
    StateNotifierProvider<WorkoutActionsNotifier, AsyncValue<void>>((ref) {
  return WorkoutActionsNotifier(ref);
});
