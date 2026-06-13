import 'package:drift/drift.dart';
import '../database.dart';
import '../tables/sync_outbox_table.dart';

part 'sync_outbox_dao.g.dart';

/// Access to the local sync queue. Pure queue mechanics — no network here.
@DriftAccessor(tables: [SyncOutbox])
class SyncOutboxDao extends DatabaseAccessor<AppDatabase>
    with _$SyncOutboxDaoMixin {
  SyncOutboxDao(super.db);

  /// Append (or coalesce) an entity snapshot to the queue. If an undrained
  /// row already exists for the same entity, it is replaced — multiple edits
  /// to one session collapse into a single upload (free-tier friendly, and
  /// naturally last-write-wins locally).
  Future<void> enqueue({
    required String entityType,
    required String entityId,
    required String userId,
    required String payload,
    String op = 'upsert',
    DateTime? updatedAt,
  }) async {
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    await transaction(() async {
      await (delete(syncOutbox)
            ..where((t) =>
                t.entityType.equals(entityType) & t.entityId.equals(entityId)))
          .go();
      await into(syncOutbox).insert(SyncOutboxCompanion.insert(
        entityType: entityType,
        entityId: entityId,
        userId: userId,
        op: Value(op),
        payload: Value(payload),
        updatedAtMs: (updatedAt ?? DateTime.now()).millisecondsSinceEpoch,
        createdAtMs: nowMs,
      ));
    });
  }

  /// Oldest [limit] queued rows for [userId] — drain in FIFO order.
  Future<List<SyncOutboxRow>> nextBatch(String userId, {int limit = 200}) {
    return (select(syncOutbox)
          ..where((t) => t.userId.equals(userId))
          ..orderBy([(t) => OrderingTerm.asc(t.createdAtMs)])
          ..limit(limit))
        .get();
  }

  /// Remove rows the backend has acknowledged.
  Future<void> deleteByIds(List<int> ids) async {
    if (ids.isEmpty) return;
    await (delete(syncOutbox)..where((t) => t.id.isIn(ids))).go();
  }

  Future<int> pendingCount(String userId) async {
    final c = syncOutbox.id.count();
    final q = selectOnly(syncOutbox)
      ..addColumns([c])
      ..where(syncOutbox.userId.equals(userId));
    return q.getSingle().then((r) => r.read(c) ?? 0);
  }

  /// Live pending count for the Settings badge.
  Stream<int> watchPendingCount(String userId) {
    final c = syncOutbox.id.count();
    final q = selectOnly(syncOutbox)
      ..addColumns([c])
      ..where(syncOutbox.userId.equals(userId));
    return q.watchSingle().map((r) => r.read(c) ?? 0);
  }
}
