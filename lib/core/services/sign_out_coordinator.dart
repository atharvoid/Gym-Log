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

/// Result of a sign-out execution. A cloud sign-out failure means the user is
/// signed out on this device but the cloud session (Supabase/RevenueCat) may
/// still be live — the caller must surface this instead of implying a clean
/// sign-out.
enum SignOutOutcome {
  complete,
  cloudSignOutFailed,
}

class SignOutCoordinator {
  final Ref _ref;
  final AppDatabase _db;
  final SyncEngine _syncEngine;
  final WorkoutDraftStore _draftStore;
  final AuthRepository _authRepo;
  final Future<void> Function() _logoutPurchases;

  SignOutCoordinator({
    required Ref ref,
    required AppDatabase db,
    required SyncEngine syncEngine,
    required WorkoutDraftStore draftStore,
    required AuthRepository authRepo,
    Future<void> Function()? logoutPurchases,
  })  : _ref = ref,
        _db = db,
        _syncEngine = syncEngine,
        _draftStore = draftStore,
        _authRepo = authRepo,
        // Injectable so tests can observe sign-out outcomes without a live
        // RevenueCat session; defaults to the real SDK call.
        _logoutPurchases = logoutPurchases ?? Purchases.logOut;

  /// Check if there is unsynced work for [userId].
  Future<SignOutResult> prepare(String userId) async {
    final count = await _db.syncOutboxDao.pendingCount(userId);
    if (count > 0) {
      return SignOutResult.unsyncedWork;
    }
    return SignOutResult.ready;
  }

  /// Execute the chosen strategy.
  ///
  /// Returns [SignOutOutcome.cloudSignOutFailed] when the local sign-out
  /// succeeded but a cloud session (RevenueCat or Supabase) could not be
  /// closed — the caller must tell the user, because a device-only sign-out
  /// with a live cloud session is not the clean sign-out they asked for.
  Future<SignOutOutcome> execute(SignOutStrategy strategy) async {
    final user = _ref.read(authProvider);
    if (user == null) return SignOutOutcome.complete;
    final userId = user.id;

    if (strategy == SignOutStrategy.keepSignedIn) {
      return SignOutOutcome.complete;
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
    var cloudFailed = false;
    try {
      await _logoutPurchases();
    } catch (_) {
      cloudFailed = true;
    }

    // 7. Supabase signOut.
    try {
      await _authRepo.signOut();
    } catch (_) {
      cloudFailed = true;
    }

    // 8. Clear account-specific preferences.
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('weekly_goal_days');
    await prefs.remove('exercise_unit_overrides');
    await prefs.remove('sync_last_synced_ms');

    return cloudFailed
        ? SignOutOutcome.cloudSignOutFailed
        : SignOutOutcome.complete;
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
