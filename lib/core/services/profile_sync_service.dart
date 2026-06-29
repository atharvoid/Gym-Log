import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../database/database.dart';
import '../providers/database_provider.dart';
import '../../features/profile/data/profile_remote.dart';

/// What the splash screen should do after resolving the signed-in user.
enum ProfileResolution {
  /// A display name is known (hydrated from remote or already local) — enter
  /// the app.
  ready,

  /// First-ever sign-in with no name anywhere — show the welcome.
  needsOnboarding,
}

/// Owns the lifecycle of a user's profile across local cache and the backend.
///
/// Principles:
///   * Local-first — the local Drift row is written immediately so the UI
///     (Settings, Profile, exports) always has a name; the network never
///     blocks the user.
///   * Backend is the cross-device source of truth — on login we fetch it and
///     hydrate local; reinstalls and other devices get the stored name.
///   * Durable intent — a failed remote write is queued in SharedPreferences
///     and retried on the next launch (and after the next successful submit),
///     silently. Nothing is ever lost or surfaced as an error to the user.
class ProfileSyncService {
  ProfileSyncService({
    required ProfileRemote remote,
    required AppDatabase db,
    Future<SharedPreferences> Function()? prefs,
  })  : _remote = remote,
        _db = db,
        _prefs = prefs ?? SharedPreferences.getInstance;

  final ProfileRemote _remote;
  final AppDatabase _db;
  final Future<SharedPreferences> Function() _prefs;

  /// Hard ceiling on any network leg so cold-start routing never hangs.
  static const _timeout = Duration(seconds: 4);

  String _pendingKey(String userId) => 'pending_profile_$userId';

  /// Onboarding submit: persist the chosen name locally at once, then push to
  /// the backend (queued + retried on failure). Returns as soon as the local
  /// write is done — the remote leg never blocks the welcome flow.
  ///
  /// When [onboardingComplete] is true, the remote profile is marked as
  /// fully onboarded, which is the authoritative gate for future logins.
  Future<bool> submitDisplayName({
    required String userId,
    required String email,
    required String name,
    bool onboardingComplete = false,
  }) async {
    final clean = name.trim();
    if (clean.isEmpty) return false;

    try {
      // 1. Local mirror — instant.
      await _db.userDao
          .upsertProfile(id: userId, email: email, displayName: clean);
    } catch (e, st) {
      debugPrint('[ProfileSyncService] Local upsert failed: $e\n$st');
    }

    // 2. Queue the remote intent, then attempt to flush it immediately.
    await _queue(userId, clean, email, onboardingComplete: onboardingComplete);
    try {
      await _flushPendingOrThrow(userId);
      return true;
    } catch (e, st) {
      debugPrint('[ProfileSyncService] Remote sync failed: $e\n$st');
      return false;
    }
  }

  /// Login-time resolution. Flushes any queued write, then makes the backend
  /// authoritative: a stored profile hydrates local and enters the app; no
  /// stored profile (and nothing local) means a first-ever user → onboarding.
  /// Any network failure falls back to local state and never blocks.
  Future<ProfileResolution> resolveOnLogin({
    required String userId,
    required String email,
  }) async {
    await _flushPending(userId);

    try {
      final remote = await _remote.fetch(userId).timeout(_timeout);

      if (remote != null && remote.displayName.trim().isNotEmpty) {
        // Backend wins — hydrate the local cache.
        await _db.userDao.upsertProfile(
          id: userId,
          email: remote.email ?? email,
          displayName: remote.displayName.trim(),
        );

        // Authoritative gate: only treat the profile as ready if the remote
        // row explicitly says onboarding is complete. A name alone (e.g. from
        // a pre-flag row, or a row left over after a partial delete) must not
        // skip onboarding.
        if (remote.onboardingComplete) {
          await _db.userDao.setOnboardingComplete(userId, complete: true);
          return ProfileResolution.ready;
        }

        // Remote has a name but is not marked complete. Trust local state if
        // it says the user already finished onboarding (migration/backfill).
        final local = await _db.userDao.getUserOrNull(userId);
        if (local != null &&
            local.onboardingComplete &&
            local.displayName.trim().isNotEmpty) {
          return ProfileResolution.ready;
        }

        return ProfileResolution.needsOnboarding;
      }

      // No remote row. If we have a local name and onboarding is complete,
      // push it up so it becomes the cross-device source of truth.
      final local = await _db.userDao.getUserOrNull(userId);
      if (local != null &&
          local.onboardingComplete &&
          local.displayName.trim().isNotEmpty) {
        await _queue(userId, local.displayName.trim(), local.email);
        await _flushPending(userId);
        return ProfileResolution.ready;
      }

      return ProfileResolution.needsOnboarding;
    } catch (_) {
      // Backend unreachable (offline, or table not provisioned yet). Trust
      // local state; if there's a name and onboarding is complete, proceed — otherwise greet them.
      final local = await _db.userDao.getUserOrNull(userId);
      return (local != null &&
              local.onboardingComplete &&
              local.displayName.trim().isNotEmpty)
          ? ProfileResolution.ready
          : ProfileResolution.needsOnboarding;
    }
  }

  /// Best-effort retry of a queued write (e.g. on app resume). Safe to call
  /// anytime; a no-op when nothing is queued.
  Future<void> retryPending(String userId) => _flushPending(userId);

  // ── internals ────────────────────────────────────────────────────────────

  Future<void> _queue(
    String userId,
    String name,
    String? email, {
    bool onboardingComplete = false,
  }) async {
    final prefs = await _prefs();
    await prefs.setString(
      _pendingKey(userId),
      jsonEncode({
        'name': name,
        'email': email,
        'onboardingComplete': onboardingComplete,
      }),
    );
  }

  Future<void> _flushPending(String userId) async {
    try {
      await _flushPendingOrThrow(userId);
    } catch (_) {
      // Keep it queued; the next launch / submit will retry.
    }
  }

  Future<void> _flushPendingOrThrow(String userId) async {
    final prefs = await _prefs();
    final raw = prefs.getString(_pendingKey(userId));
    if (raw == null) return;

    final m = jsonDecode(raw) as Map<String, dynamic>;
    await _remote
        .upsert(
          userId: userId,
          displayName: m['name'] as String,
          email: m['email'] as String?,
          onboardingComplete: m['onboardingComplete'] as bool? ?? false,
        )
        .timeout(_timeout);
    await prefs.remove(_pendingKey(userId)); // delivered — drop the queue
  }
}

/// Authenticated remote, backed by Supabase PostgREST.
final profileRemoteProvider = Provider<ProfileRemote>(
  (ref) => SupabaseProfileRemote(Supabase.instance.client),
);

/// The profile sync service, wired to the remote + local DB.
final profileSyncProvider = Provider<ProfileSyncService>(
  (ref) => ProfileSyncService(
    remote: ref.read(profileRemoteProvider),
    db: ref.read(databaseProvider),
  ),
);
