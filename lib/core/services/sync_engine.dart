import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../database/database.dart';
import '../providers/database_provider.dart';
import '../providers/supabase_client_provider.dart';
import 'sync_codec.dart';
import 'sync_entitlement_gate.dart';
import 'sync_failure.dart';
import 'sync_remote.dart';

enum SyncPhase { idle, syncing, synced, offline, error, paused }

/// Snapshot of the engine's state for the UI.
@immutable
class SyncStatus {
  final SyncPhase phase;
  final DateTime? lastSyncedAt;
  final int quarantinedCount;

  const SyncStatus(
    this.phase, {
    this.lastSyncedAt,
    this.quarantinedCount = 0,
  });

  SyncStatus copyWith({
    SyncPhase? phase,
    DateTime? lastSyncedAt,
    int? quarantinedCount,
  }) =>
      SyncStatus(
        phase ?? this.phase,
        lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
        quarantinedCount: quarantinedCount ?? this.quarantinedCount,
      );
}

/// "Local source of truth, cloud mirror."
class SyncEngine {
  SyncEngine({
    required AppDatabase db,
    required SyncRemote remote,
    required SyncEntitlementGate gate,
    Future<SharedPreferences> Function()? prefs,
  })  : _db = db,
        _remote = remote,
        _gate = gate,
        _prefs = prefs ?? SharedPreferences.getInstance;

  final AppDatabase _db;
  final SyncRemote _remote;
  final SyncEntitlementGate _gate;
  final Future<SharedPreferences> Function() _prefs;

  static const debounce = Duration(seconds: 5);
  static const _batchSize = 200;
  static const _netTimeout = Duration(seconds: 20);
  static const _lastSyncedKey = 'sync_last_synced_ms';

  SyncStatus _status = const SyncStatus(SyncPhase.idle);
  final StreamController<SyncStatus> _statusController =
      StreamController<SyncStatus>.broadcast();

  SyncStatus get status => _status;

  Stream<SyncStatus> get statusStream async* {
    yield _status;
    yield* _statusController.stream;
  }

  void _setStatus(SyncStatus next) {
    _status = next;
    if (!_statusController.isClosed) _statusController.add(next);
  }

  /// Reports a sync failure that is NOT simply "the network is unavailable".
  ///
  /// Timeouts are excluded on purpose. In a local-first app the user is
  /// routinely offline — in a gym basement, on a plane, on airplane mode —
  /// and capturing that would flood the issue stream and hide the failures
  /// that actually indicate a defect.
  static void _reportSyncFailure(
    Object error,
    StackTrace stackTrace, {
    required String operation,
    String? reason,
  }) {
    if (error is TimeoutException) return;
    debugPrint('[SyncEngine] $operation failed: $error');
    unawaited(Sentry.captureException(
      error,
      stackTrace: stackTrace,
      withScope: (scope) {
        scope.setTag('sync.operation', operation);
        if (reason != null) scope.setTag('sync.reason', reason);
      },
    ));
  }

  static const _kWeeklyGoal = 'weekly_goal_days';
  static const _kUnitOverrides = 'exercise_unit_overrides';

  Timer? _debounceTimer;
  bool _running = false;
  StreamSubscription<int>? _outboxSub;
  StreamSubscription<List<ConnectivityResult>>? _connSub;
  int _lastPending = 0;

  String? _startedForUser;
  bool _isSyncAllowed = false;

  Future<bool> _resolveGate({required bool isPremium}) async {
    final state = await _gate.resolve(isPremium: isPremium);
    _isSyncAllowed = state.isSyncAllowed;
    return _isSyncAllowed;
  }

  bool get isSyncAllowed => _isSyncAllowed;

  Future<void> initSession(String userId, {bool isPremium = false}) async {
    if (_startedForUser == userId) return;
    _startedForUser = userId;

    final allowed = await _resolveGate(isPremium: isPremium);
    if (!allowed) {
      _setStatus(const SyncStatus(SyncPhase.paused));
      return;
    }

    startAutoSync(userId);
    startConnectivityWatch(userId);
    unawaited(pull(userId));
    unawaited(loadLastSynced());
  }

  void resetSession() {
    _startedForUser = null;
    _isSyncAllowed = false;
    _debounceTimer?.cancel();
    _outboxSub?.cancel();
    _connSub?.cancel();
  }

  Future<void> resumeSync(String userId, {required bool isPremium}) async {
    final allowed = await _resolveGate(isPremium: isPremium);
    if (!allowed) return;

    startAutoSync(userId);
    startConnectivityWatch(userId);
    unawaited(pull(userId));
    unawaited(loadLastSynced());
    _setStatus(const SyncStatus(SyncPhase.idle));
  }

  void pauseSync(String userId) {
    _isSyncAllowed = false;
    _debounceTimer?.cancel();
    _outboxSub?.cancel();
    _connSub?.cancel();
    _setStatus(const SyncStatus(SyncPhase.paused));
  }

  // ── Enqueue ────────────────────────────────────────────────────

  Future<void> enqueueSession(String userId, String sessionId) async {
    if (!_isSyncAllowed) return;
    final data = await _db.workoutsDao.exportSessionJson(sessionId);
    if (data == null) return;
    await _db.syncOutboxDao.enqueue(
      entityType: 'session',
      entityId: sessionId,
      userId: userId,
      payload: SyncCodec.encode(
        data,
        entityType: 'session',
        entityId: sessionId,
      ),
    );
    scheduleSync(userId);
  }

  Future<void> enqueuePreferences(String userId) async {
    if (!_isSyncAllowed) return;
    final profile = await _db.userDao.getUserOrNull(userId);
    final prefs = await _prefs();
    final data = <String, dynamic>{
      'weightUnit': profile?.weightUnit,
      'defaultRestSeconds': profile?.defaultRestSeconds,
      'weeklyGoalDays': prefs.getInt(_kWeeklyGoal),
      'exerciseUnitOverrides': prefs.getString(_kUnitOverrides),
    };
    await _db.syncOutboxDao.enqueue(
      entityType: 'preferences',
      entityId: userId,
      userId: userId,
      payload: SyncCodec.encode(
        data,
        entityType: 'preferences',
        entityId: userId,
      ),
    );
  }

  Future<void> _applyPreferences(String userId, Map<String, dynamic> d) async {
    final weightUnit = d['weightUnit'] as String?;
    final rest = d['defaultRestSeconds'] as int?;
    if (weightUnit != null) await _db.userDao.setWeightUnit(userId, weightUnit);
    if (rest != null) await _db.userDao.setDefaultRestSeconds(userId, rest);
    final prefs = await _prefs();
    final goal = d['weeklyGoalDays'] as int?;
    if (goal != null) await prefs.setInt(_kWeeklyGoal, goal);
    final overrides = d['exerciseUnitOverrides'] as String?;
    if (overrides != null) await prefs.setString(_kUnitOverrides, overrides);
  }

  // ── Triggers ──────────────────────────────────────────────────

  void scheduleSync(String userId) {
    if (!_isSyncAllowed) return;
    _debounceTimer?.cancel();
    _debounceTimer = Timer(debounce, () => syncNow(userId, reason: 'debounce'));
  }

  Future<void> syncNow(String userId, {String reason = 'manual'}) async {
    if (!_isSyncAllowed) return;
    if (_running) return;
    _debounceTimer?.cancel();
    _running = true;
    _setStatus(_status.copyWith(phase: SyncPhase.syncing));
    try {
      while (true) {
        final batch =
            await _db.syncOutboxDao.nextBatch(userId, limit: _batchSize);
        if (batch.isEmpty) break;

        // A6: send the revision this device last saw acknowledged for each
        // entity — NOT a hardcoded 1. Sending 1 unconditionally meant every
        // push after an entity's first successful sync (server revision >=
        // 2) was misdetected as a stale conflict below and silently dropped.
        final objects = <SyncObject>[];
        for (final row in batch) {
          final revision = await _db.syncOutboxDao
              .getRevision(userId, row.entityType, row.entityId);
          objects.add(SyncObject(
            id: '${row.entityType}:${row.entityId}',
            userId: row.userId,
            entityType: row.entityType,
            entityId: row.entityId,
            revision: revision,
            operationId: 'op_${row.id}_${row.updatedAtMs}',
            updatedAtMs: row.updatedAtMs,
            deleted: row.op == 'delete',
            payload: row.payload,
          ));
        }

        final results = await _remote.pushBatch(objects).timeout(_netTimeout);
        final ackedIds = <int>[];

        for (var i = 0; i < batch.length; i++) {
          final row = batch[i];
          final res = i < results.length ? results[i] : null;

          if (res == null ||
              res.status == PushResultStatus.accepted ||
              res.status == PushResultStatus.duplicateOperation) {
            if (res?.serverRevision != null) {
              await _db.syncOutboxDao.setRevision(
                  userId, row.entityType, row.entityId, res!.serverRevision!);
            }
            ackedIds.add(row.id);
          } else if (res.status == PushResultStatus.conflict) {
            if (res.serverObject != null &&
                res.serverObject!.userId != userId) {
              await quarantineObject(
                userId: userId,
                entityType: row.entityType,
                entityId: row.entityId,
                reason: SyncFailureReason.ownershipMismatch,
                diagnostic:
                    'Ownership mismatch for ${row.entityType}:${row.entityId}',
              );
            } else if (res.serverObject != null) {
              // Genuine same-owner conflict: the server has a newer copy.
              // Adopt it locally instead of silently discarding the local
              // edit, and record the server's revision so the *next* local
              // edit to this entity pushes with the correct number.
              await _importObject(userId, res.serverObject!);
              await _db.syncOutboxDao.setRevision(userId, row.entityType,
                  row.entityId, res.serverObject!.revision);
              ackedIds.add(row.id);
            }
            // No serverObject to adopt: leave the row queued for retry next
            // cycle rather than guessing.
          }
        }

        await _db.syncOutboxDao.deleteByIds(ackedIds);

        if (batch.length < _batchSize) break;
      }

      final now = DateTime.now();
      await _persistLastSynced(now);
      final count = await _db.syncOutboxDao.quarantinedCount(userId);
      _setStatus(SyncStatus(SyncPhase.synced,
          lastSyncedAt: now, quarantinedCount: count));
    } catch (e, st) {
      // The user-visible outcome stays "offline": the local database is
      // untouched and authoritative, so there is nothing for them to act on.
      // The report is for us.
      _reportSyncFailure(e, st, operation: 'push', reason: reason);
      _setStatus(_status.copyWith(phase: SyncPhase.offline));
    } finally {
      _running = false;
    }
  }

  /// Quarantine bad/corrupt object locally and remove from outbox.
  Future<void> quarantineObject({
    required String userId,
    required String entityType,
    required String entityId,
    required SyncFailureReason reason,
    required String diagnostic,
  }) async {
    final objectId = '$entityType:$entityId';
    final now = DateTime.now();
    // Privacy-safe log: entityType:entityId and reason name ONLY (no payloads/emails/tokens)
    debugPrint(
        '[SyncEngine] Quarantined object $objectId (reason: ${reason.name})');

    final record = SyncFailureRecord(
      objectId: objectId,
      entityType: entityType,
      entityId: entityId,
      userId: userId,
      reason: reason,
      attempts: 1,
      firstSeenAt: now,
      lastSeenAt: now,
      sanitizedDiagnostic: diagnostic,
    );

    await _db.syncOutboxDao.saveQuarantineRecord(record);
    await _db.syncOutboxDao.deleteByEntity(userId, entityType, entityId);
  }

  /// Decode and apply one remote object to the local DB, quarantining it on
  /// any failure. Shared by pull() and syncNow()'s same-owner conflict path,
  /// which also needs to adopt a server-side object.
  Future<void> _importObject(String userId, SyncObject o) async {
    if (o.deleted || o.payload.isEmpty) return;
    try {
      final decoded = SyncCodec.decode(o.payload);
      final data = decoded.body;

      switch (o.entityType) {
        case 'session':
          await _db.workoutsDao.importSessionJson(data);
          break;
        case 'routine':
          await _db.routinesDao.importRoutineJson(data);
          break;
        case 'preferences':
          await _applyPreferences(userId, data);
          break;
        default:
          await quarantineObject(
            userId: userId,
            entityType: o.entityType,
            entityId: o.entityId,
            reason: SyncFailureReason.invalidPayload,
            diagnostic: 'Unknown entity type ${o.entityType}',
          );
      }
    } on FormatException catch (e) {
      await quarantineObject(
        userId: userId,
        entityType: o.entityType,
        entityId: o.entityId,
        reason: SyncFailureReason.decodeFailure,
        diagnostic: 'Decode failure: ${e.message}',
      );
    } on UnsupportedError catch (e) {
      await quarantineObject(
        userId: userId,
        entityType: o.entityType,
        entityId: o.entityId,
        reason: SyncFailureReason.unsupportedVersion,
        diagnostic: 'Unsupported version: ${e.message}',
      );
    } catch (e) {
      await quarantineObject(
        userId: userId,
        entityType: o.entityType,
        entityId: o.entityId,
        reason: SyncFailureReason.localConstraintFailure,
        diagnostic: 'Local DB constraint failure: $e',
      );
    }
  }

  /// Restore from the cloud. Rehydrates local DB with per-object isolation & quarantine.
  Future<void> pull(String userId) async {
    try {
      final objects = await _remote.pull(userId).timeout(_netTimeout);
      for (final o in objects) {
        if (o.userId != userId) {
          await quarantineObject(
            userId: userId,
            entityType: o.entityType,
            entityId: o.entityId,
            reason: SyncFailureReason.ownershipMismatch,
            diagnostic: 'Pull ownership mismatch',
          );
          continue;
        }

        await _importObject(userId, o);

        // A6: keep local revision tracking in step with the cloud for every
        // object this device pulls, so the next local edit to it pushes the
        // correct revision instead of falling back to the default 0.
        if (!o.deleted && o.payload.isNotEmpty) {
          await _db.syncOutboxDao
              .setRevision(userId, o.entityType, o.entityId, o.revision);
        }
      }

      // A5: quarantineObject() may have written sync_failures rows on any of
      // the branches above. syncNow() refreshes quarantinedCount after every
      // push; nothing here did the same for pull, so a session with no local
      // edits since the last push could quarantine objects during a pull and
      // never move SyncStatus.quarantinedCount off its previous value. The
      // live quarantinedSyncCountProvider is unaffected (it watches the DB
      // directly) — this refreshes the other, non-reactive channel.
      final count = await _db.syncOutboxDao.quarantinedCount(userId);
      _setStatus(_status.copyWith(quarantinedCount: count));
    } catch (e, st) {
      // Transient network failure is expected and not quarantined. Anything
      // else here is a defect in the transport or the server contract and
      // must not vanish.
      _reportSyncFailure(e, st, operation: 'pull');
    }
  }

  Future<void> loadLastSynced() async {
    final prefs = await _prefs();
    final ms = prefs.getInt(_lastSyncedKey);
    if (ms != null) {
      _setStatus(_status.copyWith(
          lastSyncedAt: DateTime.fromMillisecondsSinceEpoch(ms)));
    }
  }

  Future<void> _persistLastSynced(DateTime when) async {
    final prefs = await _prefs();
    await prefs.setInt(_lastSyncedKey, when.millisecondsSinceEpoch);
  }

  void startAutoSync(String userId) {
    if (!_isSyncAllowed) return;
    _outboxSub?.cancel();
    _lastPending = 0;
    _outboxSub = _db.syncOutboxDao.watchPendingCount(userId).listen((count) {
      if (count > _lastPending) scheduleSync(userId);
      _lastPending = count;
    });
  }

  void startConnectivityWatch(String userId) {
    if (!_isSyncAllowed) return;
    _connSub?.cancel();
    _connSub = Connectivity().onConnectivityChanged.listen((results) {
      final online = results.any((r) => r != ConnectivityResult.none);
      if (online) syncNow(userId, reason: 'connectivity');
    });
  }

  void dispose() {
    _debounceTimer?.cancel();
    _outboxSub?.cancel();
    _connSub?.cancel();
    _statusController.close();
  }
}

// ── Providers ────────────────────────────────────────────────────

/// The Supabase transport.
///
/// This provider is memoised, so it must NOT resolve the Supabase client
/// here — during startup that would capture "unavailable" permanently. It
/// hands the remote a resolver instead; see supabase_client_provider.dart.
final syncRemoteProvider = Provider<SyncRemote>(
  (ref) => SupabaseSyncRemote(ref.read(supabaseClientProvider)),
);

final syncEngineProvider = Provider<SyncEngine>((ref) {
  final engine = SyncEngine(
    db: ref.read(databaseProvider),
    remote: ref.read(syncRemoteProvider),
    gate: ref.read(syncEntitlementGateProvider),
  );
  ref.onDispose(engine.dispose);
  return engine;
});

final pendingSyncCountProvider = StreamProvider.family<int, String>(
  (ref, userId) =>
      ref.watch(databaseProvider).syncOutboxDao.watchPendingCount(userId),
);

final quarantinedSyncCountProvider = StreamProvider.family<int, String>(
  (ref, userId) =>
      ref.watch(databaseProvider).syncOutboxDao.watchQuarantinedCount(userId),
);
