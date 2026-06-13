import 'package:supabase_flutter/supabase_flutter.dart';

/// One synced object as it lives on the backend. The body is an opaque,
/// compressed [payload] (see SyncCodec) plus the metadata the server needs
/// for ownership (userId) and last-write-wins conflict resolution
/// (updatedAtMs → updated_at).
class SyncObject {
  /// Globally unique row id: "<entityType>:<entityId>".
  final String id;
  final String userId;
  final String entityType;
  final String entityId;
  final int updatedAtMs;
  final bool deleted;
  final String payload;

  const SyncObject({
    required this.id,
    required this.userId,
    required this.entityType,
    required this.entityId,
    required this.updatedAtMs,
    required this.deleted,
    required this.payload,
  });
}

/// Backend transport for the sync engine. Implementations may throw on any
/// failure (offline, server error); the engine catches and re-queues.
abstract class SyncRemote {
  /// Upsert a batch of objects in ONE request (free-tier friendly). The
  /// server applies last-write-wins by updated_at.
  Future<void> pushBatch(List<SyncObject> objects);

  /// All of the user's objects (RLS guarantees own-rows-only), newest first.
  Future<List<SyncObject>> pull(String userId);
}

/// Supabase-backed implementation against the single `sync_objects` table.
/// See docs/supabase/sync_objects.sql. Deliberately NO realtime subscription —
/// high-frequency workout writes pull on demand only, per free-tier guidance.
class SupabaseSyncRemote implements SyncRemote {
  SupabaseSyncRemote(this._client);

  final SupabaseClient _client;
  static const _table = 'sync_objects';

  @override
  Future<void> pushBatch(List<SyncObject> objects) async {
    if (objects.isEmpty) return;
    final rows = [
      for (final o in objects)
        {
          'id': o.id,
          'user_id': o.userId,
          'entity_type': o.entityType,
          'entity_id': o.entityId,
          'updated_at':
              DateTime.fromMillisecondsSinceEpoch(o.updatedAtMs, isUtc: true)
                  .toIso8601String(),
          'deleted': o.deleted,
          'payload': o.payload,
        }
    ];
    await _client.from(_table).upsert(rows);
  }

  @override
  Future<List<SyncObject>> pull(String userId) async {
    final rows = await _client
        .from(_table)
        .select('id, user_id, entity_type, entity_id, updated_at, deleted, payload')
        .eq('user_id', userId)
        .order('updated_at');
    return [
      for (final r in (rows as List).cast<Map<String, dynamic>>())
        SyncObject(
          id: r['id'] as String,
          userId: r['user_id'] as String,
          entityType: r['entity_type'] as String,
          entityId: r['entity_id'] as String,
          updatedAtMs:
              DateTime.parse(r['updated_at'] as String).millisecondsSinceEpoch,
          deleted: (r['deleted'] as bool?) ?? false,
          payload: (r['payload'] as String?) ?? '',
        )
    ];
  }
}
