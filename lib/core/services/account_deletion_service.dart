import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../database/database.dart';
import '../providers/database_provider.dart';
import 'workout_draft_store.dart';

/// Outcome of an account deletion attempt. The flow ALWAYS wipes local data
/// and signs the user out; [cloudPurged] / [authUserDeleted] report how
/// completely the backend side succeeded so the UI can be honest.
@immutable
class AccountDeletionOutcome {
  /// The user's cloud DATA (profile row + synced workout/routine payloads) was
  /// removed.
  final bool cloudPurged;

  /// The Supabase auth identity itself was deleted (requires the server-side
  /// Edge Function — the client cannot delete its own `auth.users` row).
  final bool authUserDeleted;

  /// Local DB + preferences + secure storage were wiped and the session ended.
  final bool localWiped;

  /// Diagnostic note (never shown verbatim to users).
  final String? note;

  const AccountDeletionOutcome({
    required this.cloudPurged,
    required this.authUserDeleted,
    required this.localWiped,
    this.note,
  });
}

/// Orchestrates irreversible account deletion across the local-first stack.
///
/// Sequence (cloud calls first, while the session is still valid):
///   1. Edge Function `delete-account` — purges `sync_objects` + `profiles`
///      AND the `auth.users` identity with the service role (complete path).
///   2. Fallback if the function is unreachable: delete the user's OWN rows
///      directly via PostgREST (RLS own-row). Data is gone; the empty auth
///      identity may linger until the function runs — surfaced honestly.
///   3. Sign out (invalidate the session).
///   4. Wipe the local Drift DB, clear SharedPreferences + secure storage,
///      and re-seed the bundled exercise catalog.
///
/// There is deliberately NO soft-delete / deactivate path.
class AccountDeletionService {
  AccountDeletionService(this._db, this._client);

  final AppDatabase _db;
  final SupabaseClient _client;

  static const _timeout = Duration(seconds: 12);
  static const _functionName = 'delete-account';

  Future<AccountDeletionOutcome> deleteAccount() async {
    final user = _client.auth.currentUser;

    // No session: nothing to purge server-side, but still wipe local data
    // defensively so "delete" always leaves a clean device.
    if (user == null) {
      final wiped = await _wipeLocalAndSignOut();
      return AccountDeletionOutcome(
        cloudPurged: false,
        authUserDeleted: false,
        localWiped: wiped,
        note: 'No active session — local data wiped only.',
      );
    }

    final uid = user.id;
    var cloudPurged = false;
    var authUserDeleted = false;
    String? note;

    // 1 ── Preferred: server-side Edge Function (service role).
    try {
      final res =
          await _client.functions.invoke(_functionName).timeout(_timeout);
      if (res.status == 200) {
        cloudPurged = true;
        authUserDeleted = true;
      } else {
        note = 'delete-account returned HTTP ${res.status}';
      }
    } catch (e) {
      note = 'delete-account unavailable: $e';
    }

    // 2 ── Fallback: delete the caller's own rows directly (RLS own-row).
    //     The auth identity can't be removed client-side, but every byte of
    //     personal DATA is purged either way.
    if (!cloudPurged) {
      try {
        await _client
            .from('sync_objects')
            .delete()
            .eq('user_id', uid)
            .timeout(_timeout);
        await _client.from('profiles').delete().eq('id', uid).timeout(_timeout);
        cloudPurged = true; // data gone; authUserDeleted stays false
      } catch (e) {
        note = '${note ?? ''} | direct purge failed: $e';
      }
    }

    // 3 + 4 ── Always sign out and wipe local, regardless of cloud outcome.
    final localWiped = await _wipeLocalAndSignOut();

    if (kDebugMode) {
      debugPrint('[AccountDeletion] cloud=$cloudPurged auth=$authUserDeleted '
          'local=$localWiped note=$note');
      if (!authUserDeleted) {
        debugPrint('[AccountDeletion] WARNING: auth.users identity survived — '
            're-login will reuse the same uid unless the Edge Function deletes it.');
      }
    }

    return AccountDeletionOutcome(
      cloudPurged: cloudPurged,
      authUserDeleted: authUserDeleted,
      localWiped: localWiped,
      note: note,
    );
  }

  /// Signs out, wipes the local DB + all on-device caches, then re-seeds the
  /// bundled catalog. Returns true on success.
  Future<bool> _wipeLocalAndSignOut() async {
    try {
      // End the session first so the auth-state stream drives the redirect to
      // /auth (no way back to a dead session).
      try {
        await _client.auth.signOut();
      } catch (_) {
        // Already signed out / offline — proceed with the local wipe anyway.
      }

      await WorkoutDraftStore().clear();
      await _db.wipeAllData();

      // Clears settings, weekly goal, unit overrides, the local sync queue
      // ids, AND the hydration flag (so the catalog re-seeds below).
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      // Belt-and-suspenders: drop any tokens a plugin parked in the keystore.
      try {
        await const FlutterSecureStorage().deleteAll();
      } catch (_) {}

      // Re-seed the shipped exercise catalog so a subsequent sign-in finds a
      // populated library (hydration is guarded by the flag we just cleared).
      try {
        await _db.exercisesDao.hydrateFromJson();
      } catch (_) {}

      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('[AccountDeletion] local wipe failed: $e');
      return false;
    }
  }
}

final accountDeletionServiceProvider = Provider<AccountDeletionService>((ref) {
  return AccountDeletionService(
    ref.watch(databaseProvider),
    Supabase.instance.client,
  );
});
