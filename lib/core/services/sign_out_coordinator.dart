import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../database/database.dart';
import '../providers/database_provider.dart';
import 'sync_engine.dart';
import 'workout_draft_store.dart';
import '../../features/auth/data/auth_repository.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/workout/presentation/providers/active_workout_provider.dart';

enum SignOutResult {
  unsyncedWork,
  ready,
}

enum SignOutStrategy {
  keepSignedIn,
  signOutAfterSync,
  exportAndSignOut,
  forceSignOut,
}

class SignOutCoordinator {
  final Ref _ref;
  final AppDatabase _db;
  final SyncEngine _syncEngine;
  final WorkoutDraftStore _draftStore;
  final AuthRepository _authRepo;

  SignOutCoordinator({
    required Ref ref,
    required AppDatabase db,
    required SyncEngine syncEngine,
    required WorkoutDraftStore draftStore,
    required AuthRepository authRepo,
  })  : _ref = ref,
        _db = db,
        _syncEngine = syncEngine,
        _draftStore = draftStore,
        _authRepo = authRepo;

  /// Check if there is unsynced work for [userId].
  Future<SignOutResult> prepare(String userId) async {
    final count = await _db.syncOutboxDao.pendingCount(userId);
    if (count > 0) {
      return SignOutResult.unsyncedWork;
    }
    return SignOutResult.ready;
  }

  /// Execute the chosen strategy.
  Future<void> execute(SignOutStrategy strategy) async {
    final user = _ref.read(authProvider);
    if (user == null) return;
    final userId = user.id;

    if (strategy == SignOutStrategy.keepSignedIn) {
      return;
    }

    // 1. Stop auto-sync for current user.
    _syncEngine.pauseSync(userId);

    // 2. Flush or classify pending outbox.
    if (strategy == SignOutStrategy.signOutAfterSync) {
      try {
        await _syncEngine.syncNow(userId).timeout(const Duration(seconds: 10));
      } catch (_) {
        // Fallback to bypass/offline forceSignOut on failure/timeout
      }
    }

    // 4. Clear active workout/draft.
    _ref.read(activeWorkoutProvider.notifier).discardWorkout();
    await _draftStore.clear();

    // 5. Clear account-scoped provider caches.
    _ref.invalidate(authProvider);
    _ref.invalidate(authStateProvider);

    // 6. RevenueCat logOut.
    try {
      await Purchases.logOut();
    } catch (_) {}

    // 7. Supabase signOut.
    try {
      await _authRepo.signOut();
    } catch (_) {}

    // 8. Clear account-specific preferences.
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('weekly_goal_days');
    await prefs.remove('exercise_unit_overrides');
    await prefs.remove('sync_last_synced_ms');
  }
}

final signOutCoordinatorProvider = Provider<SignOutCoordinator>((ref) {
  return SignOutCoordinator(
    ref: ref,
    db: ref.read(databaseProvider),
    syncEngine: ref.read(syncEngineProvider),
    draftStore: ref.read(workoutDraftStoreProvider),
    authRepo: ref.read(authRepositoryProvider),
  );
});
