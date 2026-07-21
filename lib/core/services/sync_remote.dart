import 'package:supabase_flutter/supabase_flutter.dart';

enum PushResultStatus {
  accepted,
  conflict,
  duplicateOperation,
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
class SupabaseSyncRemote implements SyncRemote {
  SupabaseSyncRemote(this._client);

  final SupabaseClient _client;
  static const _table = 'sync_objects';

  @override
  Future<List<PushResult>> pushBatch(List<SyncObject> objects) async {
    if (objects.isEmpty) return const [];
    final results = <PushResult>[];
    for (final o in objects) {
      try {
        final existing = await _client
            .from(_table)
            .select(
                'id, user_id, revision, operation_id, updated_at, deleted, payload')
            .eq('id', o.id)
            .maybeSingle();

        if (existing != null) {
          final serverUserId = existing['user_id'] as String?;
          if (serverUserId != null && serverUserId != o.userId) {
            results.add(PushResult(
              id: o.id,
              status: PushResultStatus.conflict,
              serverRevision: (existing['revision'] as num?)?.toInt() ?? 1,
            ));
            continue;
          }

          final serverOpId = existing['operation_id'] as String?;
          if (serverOpId != null &&
              serverOpId.isNotEmpty &&
              serverOpId == o.operationId) {
            results.add(PushResult(
              id: o.id,
              status: PushResultStatus.duplicateOperation,
              serverRevision: (existing['revision'] as num?)?.toInt() ?? 1,
            ));
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
            results.add(PushResult(
              id: o.id,
              status: PushResultStatus.conflict,
              serverRevision: serverRevision,
              serverObject: serverObj,
            ));
            continue;
          }
        }

        final nextRevision = o.revision + 1;
        await _client.from(_table).upsert({
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

        results.add(PushResult(
          id: o.id,
          status: PushResultStatus.accepted,
          serverRevision: nextRevision,
        ));
      } catch (_) {
        rethrow;
      }
    }
    return results;
  }

  @override
  Future<List<SyncObject>> pull(String userId) async {
    final rows = await _client
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
