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

  /// A6 re-run: hard ceiling on how many batches one syncNow() will drain.
  ///
  /// The loop below terminates on its own in every case we can reason about,
  /// but every pass is real network I/O. A bound means a server that keeps
  /// moving under us degrades into "finish on the next trigger" rather than
  /// an unbounded push loop on a phone in someone's gym bag.
  static const _maxDrainPasses = 50;

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
    if (kDebugMode) debugPrint('[SyncEngine] $operation failed: $error');
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

  // ── Enqueue ─────────────────────────────

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

  // ── Triggers ─────────────────────────────

  void scheduleSync(String userId, {String reason = 'debounce'}) {
    if (!_isSyncAllowed) return;
    _debounceTimer?.cancel();
    _debounceTimer = Timer(debounce, () => syncNow(userId, reason: reason));
  }

  Future<void> syncNow(String userId, {String reason = 'manual'}) async {
    if (!_isSyncAllowed) return;
    if (_running) return;
    _debounceTimer?.cancel();
    _running = true;
    _setStatus(_status.copyWith(phase: SyncPhase.syncing));
    try {
      var passes = 0;
      while (true) {
        // A6 re-run: bound the drain. The loop used to be `while (true)` with
        // the only exits being an empty batch or a short one — so a full
        // batch in which nothing could be acked (see the ownership-mismatch
        // case below, which matched no branch at all) re-pushed the same 200
        // objects over the network forever inside a single syncNow().
        if (passes++ >= _maxDrainPasses) break;

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

        // A6 re-run: "progress" means a row left the queue or its recorded
        // revision advanced. A pass with neither will behave identically next
        // time, so it must stop rather than retry.
        var progressed = false;

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
          } else if (res.status == PushResultStatus.ownershipMismatch) {
            // A6 re-run: the transport reports this as its own status now.
            // It used to arrive as `conflict` with a null serverObject, and
            // the quarantine branch tested `serverObject!.userId != userId`
            // — a condition the transport could not satisfy. The row was
            // therefore never quarantined, never acked and never deleted: it
            // returned at the head of every FIFO batch indefinitely.
            await quarantineObject(
              userId: userId,
              entityType: row.entityType,
              entityId: row.entityId,
              reason: SyncFailureReason.ownershipMismatch,
              diagnostic:
                  'Ownership mismatch for ${row.entityType}:${row.entityId}',
            );
            // quarantineObject() removes the outbox row itself.
            progressed = true;
          } else if (res.status == PushResultStatus.conflict) {
            final server = res.serverObject;
            if (server == null) {
              // Nothing to adopt and nothing to learn. Leave the row queued
              // rather than guessing; the no-progress break below keeps this
              // from spinning.
              continue;
            }

            if (row.updatedAtMs > server.updatedAtMs) {
              // A6 re-run: the local edit is genuinely newer in wall-clock
              // terms. Adopting the server copy here — which is what a
              // revision-only rule does — destroys a newer user edit purely
              // because this device had not pulled recently. Record the
              // server's revision and leave the row queued so the next pass
              // re-pushes the same payload with a revision the server will
              // accept.
              await _db.syncOutboxDao.setRevision(
                  userId, row.entityType, row.entityId, server.revision);
              progressed = true;
            } else {
              // The server copy is the newer one. Adopt it locally instead
              // of silently discarding the local edit, and record the
              // server's revision so the *next* local edit to this entity
              // pushes with the correct number.
              await _importObject(userId, server);
              await _db.syncOutboxDao.setRevision(
                  userId, row.entityType, row.entityId, server.revision);
              ackedIds.add(row.id);
            }
          }
        }

        await _db.syncOutboxDao.deleteByIds(ackedIds);

        // A6 re-run: a pass that changed nothing will change nothing next
        // time either. Stop and leave the rows for a later trigger.
        if (ackedIds.isEmpty && !progressed) break;
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
    // Privacy-safe log: entityType:entityId and reason name ONLY (no
    // payloads/emails/tokens). Still gated behind kDebugMode (C38) because
    // "privacy-safe content" and "safe to ship to a production device log"
    // are different bars — this keeps both.
    if (kDebugMode) {
      debugPrint(
          '[SyncEngine] Quarantined object $objectId (reason: ${reason.name})');
    }

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
      // C35: this used to call syncNow() directly on every transition to
      // online, bypassing the same 5s debounce that already protects the
      // outbox-triggered path above. onConnectivityChanged fires on every
      // flap of a marginal connection (elevator, subway, a weak signal
      // handing off between Wi-Fi and cellular), and each direct call was a
      // real batch fetch/push against the network with its own 20s
      // timeout — a burst of flaps could queue up repeated full sync
      // attempts back to back with nothing new to send in between. Routing
      // through scheduleSync() coalesces a burst into a single attempt once
      // the connection settles.
      if (online) scheduleSync(userId, reason: 'connectivity');
    });
  }

  void dispose() {
    _debounceTimer?.cancel();
    _outboxSub?.cancel();
    _connSub?.cancel();
    _statusController.close();
  }
}

// ── Providers ─────────────────────────────

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
