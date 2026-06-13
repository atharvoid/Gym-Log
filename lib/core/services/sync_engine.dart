import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../database/database.dart';
import '../providers/database_provider.dart';
import 'sync_codec.dart';
import 'sync_remote.dart';

enum SyncPhase { idle, syncing, synced, offline, error }

/// Snapshot of the engine's state for the UI.
@immutable
class SyncStatus {
  final SyncPhase phase;
  final DateTime? lastSyncedAt;

  const SyncStatus(this.phase, {this.lastSyncedAt});

  SyncStatus copyWith({SyncPhase? phase, DateTime? lastSyncedAt}) =>
      SyncStatus(phase ?? this.phase,
          lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt);
}

/// "Local source of truth, cloud mirror."
///
/// Writes commit to SQLite first, then [enqueueSession] appends a compressed
/// snapshot to the local outbox and arms a debounce. The engine drains the
/// outbox to Supabase in batches — after 5s of write inactivity, or
/// immediately on explicit triggers (post-workout, backgrounding, "Sync
/// Now"). Failures leave rows queued (offline-safe, retried later); nothing
/// is ever lost. [pull] restores everything after a reinstall.
class SyncEngine {
  SyncEngine({
    required AppDatabase db,
    required SyncRemote remote,
    Future<SharedPreferences> Function()? prefs,
  })  : _db = db,
        _remote = remote,
        _prefs = prefs ?? SharedPreferences.getInstance;

  final AppDatabase _db;
  final SyncRemote _remote;
  final Future<SharedPreferences> Function() _prefs;

  /// Debounce window: upload after this much write-inactivity.
  static const debounce = Duration(seconds: 5);
  static const _batchSize = 200;
  static const _netTimeout = Duration(seconds: 20);
  static const _lastSyncedKey = 'sync_last_synced_ms';

  /// Live state for the Settings UI. ValueListenable → ValueListenableBuilder.
  final ValueNotifier<SyncStatus> status =
      ValueNotifier(const SyncStatus(SyncPhase.idle));

  Timer? _debounceTimer;
  bool _running = false;

  // ── Enqueue (called right after a local commit) ────────────────────────────

  /// Snapshot a finished session into the outbox and arm the debounce. The
  /// network is never touched here — the local write already succeeded.
  Future<void> enqueueSession(String userId, String sessionId) async {
    final data = await _db.workoutsDao.exportSessionJson(sessionId);
    if (data == null) return;
    await _db.syncOutboxDao.enqueue(
      entityType: 'session',
      entityId: sessionId,
      userId: userId,
      payload: SyncCodec.encode(data),
    );
    scheduleSync(userId);
  }

  // ── Triggers ───────────────────────────────────────────────────────────────

  /// Debounced trigger — resets the 5s timer on each write.
  void scheduleSync(String userId) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(debounce, () => syncNow(userId, reason: 'debounce'));
  }

  /// Immediate trigger — post-workout, app backgrounding, connectivity
  /// restore, or the Settings "Sync Now" button. Coalesces concurrent calls.
  Future<void> syncNow(String userId, {String reason = 'manual'}) async {
    if (_running) return;
    _debounceTimer?.cancel();
    _running = true;
    status.value = status.value.copyWith(phase: SyncPhase.syncing);
    try {
      while (true) {
        final batch = await _db.syncOutboxDao.nextBatch(userId, limit: _batchSize);
        if (batch.isEmpty) break;

        final objects = [
          for (final row in batch)
            SyncObject(
              id: '${row.entityType}:${row.entityId}',
              userId: row.userId,
              entityType: row.entityType,
              entityId: row.entityId,
              updatedAtMs: row.updatedAtMs,
              deleted: row.op == 'delete',
              payload: row.payload,
            )
        ];

        await _remote.pushBatch(objects).timeout(_netTimeout);
        await _db.syncOutboxDao.deleteByIds(batch.map((r) => r.id).toList());

        if (batch.length < _batchSize) break; // drained
      }

      final now = DateTime.now();
      await _persistLastSynced(now);
      status.value = SyncStatus(SyncPhase.synced, lastSyncedAt: now);
    } catch (_) {
      // Offline or server error — rows stay queued, retried on the next
      // trigger. Never surfaced as a blocking failure.
      status.value = status.value.copyWith(phase: SyncPhase.offline);
    } finally {
      _running = false;
    }
  }

  /// Restore from the cloud (e.g. after reinstall). Pulls the user's objects
  /// and rehydrates local storage. Remote is authoritative here (the server
  /// already merged via last-write-wins). Best-effort; never throws.
  Future<void> pull(String userId) async {
    try {
      final objects = await _remote.pull(userId).timeout(_netTimeout);
      for (final o in objects) {
        if (o.deleted || o.payload.isEmpty) continue;
        if (o.entityType == 'session') {
          await _db.workoutsDao.importSessionJson(SyncCodec.decode(o.payload));
        }
      }
    } catch (_) {
      // Offline / not provisioned — nothing to restore right now.
    }
  }

  Future<void> loadLastSynced() async {
    final prefs = await _prefs();
    final ms = prefs.getInt(_lastSyncedKey);
    if (ms != null) {
      status.value = status.value
          .copyWith(lastSyncedAt: DateTime.fromMillisecondsSinceEpoch(ms));
    }
  }

  Future<void> _persistLastSynced(DateTime when) async {
    final prefs = await _prefs();
    await prefs.setInt(_lastSyncedKey, when.millisecondsSinceEpoch);
  }

  void dispose() {
    _debounceTimer?.cancel();
    status.dispose();
  }
}

// ── Providers ────────────────────────────────────────────────────────────────

final syncRemoteProvider = Provider<SyncRemote>(
  (ref) => SupabaseSyncRemote(Supabase.instance.client),
);

final syncEngineProvider = Provider<SyncEngine>((ref) {
  final engine = SyncEngine(
    db: ref.read(databaseProvider),
    remote: ref.read(syncRemoteProvider),
  );
  ref.onDispose(engine.dispose);
  return engine;
});

/// Live count of un-synced changes, for the Settings badge.
final pendingSyncCountProvider = StreamProvider.family<int, String>(
  (ref, userId) =>
      ref.watch(databaseProvider).syncOutboxDao.watchPendingCount(userId),
);
