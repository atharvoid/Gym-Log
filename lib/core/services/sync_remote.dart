import 'package:supabase_flutter/supabase_flutter.dart';

import '../providers/supabase_client_provider.dart';

enum PushResultStatus {
  accepted,
  conflict,
  duplicateOperation,

  /// The server row with this id belongs to a different user.
  ///
  /// A6 re-run: this used to be reported as [conflict] with a null
  /// serverObject, which made SyncEngine's quarantine branch unreachable.
  /// It is a distinct outcome from a revision conflict. there is nothing to
  /// merge and nothing to retry. so it gets a distinct status.
  ownershipMismatch,
}

class PushResult {
  final String id;
  final PushResultStatus status;
  final int? serverRevision;
  final SyncObject? serverObject;

  const PushResult({
    required this.id,
    required this.status,
    this.serverRevision,
    this.serverObject,
  });
}

/// One synced object as it lives on the backend.
class SyncObject {
  /// Globally unique row id: "<entityType>:<entityId>".
  final String id;
  final String userId;
  final String entityType;
  final String entityId;
  final int revision;
  final String operationId;
  final int updatedAtMs;
  final bool deleted;
  final String payload;

  const SyncObject({
    required this.id,
    required this.userId,
    required this.entityType,
    required this.entityId,
    required this.revision,
    required this.operationId,
    required this.updatedAtMs,
    required this.deleted,
    required this.payload,
  });
}

/// Backend transport for the sync engine.
abstract class SyncRemote {
  /// Upsert a batch of objects with monotonic revision & operation tracking.
  Future<List<PushResult>> pushBatch(List<SyncObject> objects);

  /// All of the user's objects (RLS guarantees own-rows-only).
  Future<List<SyncObject>> pull(String userId);
}

/// Supabase-backed implementation against `sync_objects` table.
///
/// Holds a [SupabaseClientResolver], NOT a client. The client is resolved on
/// every operation because this object is created inside a memoised Riverpod
/// provider: if it captured the client at construction time it would capture
/// whatever was true during startup. usually `null`. and never recover.
/// Resolving per call means the first sync after cloud init succeeds even
/// though the remote itself was built before it.
class SupabaseSyncRemote implements SyncRemote {
  SupabaseSyncRemote(this._resolveClient);

  final SupabaseClientResolver _resolveClient;
  static const _table = 'sync_objects';

  /// The live client, or a clear failure.
  ///
  /// Throwing here rather than silently no-opping is deliberate: a sync that
  /// quietly does nothing looks identical to a sync that succeeded, and the
  /// user would believe their data is backed up when it is not. The engine
  /// catches this and reports SyncPhase.offline, which is honest.
  SupabaseClient get _client {
    final client = _resolveClient();
    if (client == null) {
      throw StateError(
          'Cloud sync is unavailable. Supabase is not initialised.');
    }
    return client;
  }

  @override
  Future<List<PushResult>> pushBatch(List<SyncObject> objects) async {
    if (objects.isEmpty) return const [];
    final client = _client;

    // A6: one bulk lookup for the whole batch instead of one `select` per
    // object. up to 200 serial round trips collapsed into 1.
    final ids = [for (final o in objects) o.id];
    final existingRows = await client
        .from(_table)
        .select(
            'id, user_id, revision, operation_id, updated_at, deleted, payload')
        .inFilter('id', ids);
    final existingById = <String, Map<String, dynamic>>{
      for (final r in (existingRows as List).cast<Map<String, dynamic>>())
        r['id'] as String: r,
    };

    final resultsById = <String, PushResult>{};
    final toUpsert = <Map<String, dynamic>>[];
    final nextRevisionById = <String, int>{};

    for (final o in objects) {
      final existing = existingById[o.id];

      if (existing != null) {
        final serverUserId = existing['user_id'] as String?;
        if (serverUserId != null && serverUserId != o.userId) {
          // A6 re-run: report this as its own status. Returning `conflict`
          // with no serverObject left SyncEngine with no branch that could
          // fire, so the row was neither quarantined nor acked and came back
          // at the head of every subsequent batch.
          resultsById[o.id] = PushResult(
            id: o.id,
            status: PushResultStatus.ownershipMismatch,
            serverRevision: (existing['revision'] as num?)?.toInt() ?? 1,
          );
          continue;
        }

        final serverOpId = existing['operation_id'] as String?;
        if (serverOpId != null &&
            serverOpId.isNotEmpty &&
            serverOpId == o.operationId) {
          resultsById[o.id] = PushResult(
            id: o.id,
            status: PushResultStatus.duplicateOperation,
            serverRevision: (existing['revision'] as num?)?.toInt() ?? 1,
          );
          continue;
        }

        final serverRevision = (existing['revision'] as num?)?.toInt() ?? 1;
        if (o.revision < serverRevision) {
          final serverObj = SyncObject(
            id: existing['id'] as String,
            userId: existing['user_id'] as String,
            entityType: o.entityType,
            entityId: o.entityId,
            revision: serverRevision,
            operationId: (existing['operation_id'] as String?) ?? '',
            updatedAtMs: DateTime.parse(existing['updated_at'] as String)
                .millisecondsSinceEpoch,
            deleted: (existing['deleted'] as bool?) ?? false,
            payload: (existing['payload'] as String?) ?? '',
          );
          resultsById[o.id] = PushResult(
            id: o.id,
            status: PushResultStatus.conflict,
            serverRevision: serverRevision,
            serverObject: serverObj,
          );
          continue;
        }
      }

      final nextRevision = o.revision + 1;
      nextRevisionById[o.id] = nextRevision;
      toUpsert.add({
        'id': o.id,
        'user_id': o.userId,
        'entity_type': o.entityType,
        'entity_id': o.entityId,
        'revision': nextRevision,
        'operation_id': o.operationId,
        'updated_at':
            DateTime.fromMillisecondsSinceEpoch(o.updatedAtMs, isUtc: true)
                .toIso8601String(),
        'deleted': o.deleted,
        'payload': o.payload,
      });
    }

    if (toUpsert.isNotEmpty) {
      // A6: one bulk upsert for every accepted object in the batch instead of
      // one `upsert` call per object.
      await client.from(_table).upsert(toUpsert);
      for (final id in nextRevisionById.keys) {
        resultsById[id] = PushResult(
          id: id,
          status: PushResultStatus.accepted,
          serverRevision: nextRevisionById[id],
        );
      }
    }

    // Preserve the caller's original ordering: SyncEngine pairs
    // results[i] with the batch's row at the same index.
    return [for (final o in objects) resultsById[o.id]!];
  }

  @override
  Future<List<SyncObject>> pull(String userId) async {
    final client = _client;
    final rows = await client
        .from(_table)
        .select(
            'id, user_id, entity_type, entity_id, revision, operation_id, updated_at, deleted, payload')
        .eq('user_id', userId)
        .order('updated_at');
    return [
      for (final r in (rows as List).cast<Map<String, dynamic>>())
        SyncObject(
          id: r['id'] as String,
          userId: r['user_id'] as String,
          entityType: r['entity_type'] as String,
          entityId: r['entity_id'] as String,
          revision: (r['revision'] as num?)?.toInt() ?? 1,
          operationId: (r['operation_id'] as String?) ?? '',
          updatedAtMs:
              DateTime.parse(r['updated_at'] as String).millisecondsSinceEpoch,
          deleted: (r['deleted'] as bool?) ?? false,
          payload: (r['payload'] as String?) ?? '',
        )
    ];
  }
}
