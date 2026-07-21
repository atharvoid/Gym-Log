import 'package:drift/drift.dart';
import '../../services/sync_failure.dart';
import '../database.dart';
import '../tables/sync_outbox_table.dart';

part 'sync_outbox_dao.g.dart';

/// Access to the local sync queue and quarantine persistence.
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
                t.userId.equals(userId) &
                t.entityType.equals(entityType) &
                t.entityId.equals(entityId)))
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

  /// Delete queued outbox row for a specific entity ID.
  Future<void> deleteByEntity(
      String userId, String entityType, String entityId) async {
    await (delete(syncOutbox)
          ..where((t) =>
              t.userId.equals(userId) &
              t.entityType.equals(entityType) &
              t.entityId.equals(entityId)))
        .go();
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

  // ── Quarantine Persistence ──────────────────────────────────────────────────

  Future<void> saveQuarantineRecord(SyncFailureRecord record) async {
    await customStatement('''
      INSERT INTO sync_failures (
        object_id, user_id, entity_type, entity_id, reason, attempts, first_seen_at_ms, last_seen_at_ms, sanitized_diagnostic
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
      ON CONFLICT(object_id, user_id) DO UPDATE SET
        attempts = attempts + 1,
        last_seen_at_ms = excluded.last_seen_at_ms,
        reason = excluded.reason,
        sanitized_diagnostic = excluded.sanitized_diagnostic
    ''', [
      record.objectId,
      record.userId,
      record.entityType,
      record.entityId,
      record.reason.name,
      record.attempts,
      record.firstSeenAt.millisecondsSinceEpoch,
      record.lastSeenAt.millisecondsSinceEpoch,
      record.sanitizedDiagnostic,
    ]);
  }

  Future<List<SyncFailureRecord>> getQuarantinedRecords(String userId) async {
    final rows = await customSelect(
      'SELECT object_id, user_id, entity_type, entity_id, reason, attempts, first_seen_at_ms, last_seen_at_ms, sanitized_diagnostic '
      'FROM sync_failures WHERE user_id = ? ORDER BY last_seen_at_ms DESC',
      variables: [Variable.withString(userId)],
    ).get();

    return [
      for (final r in rows)
        SyncFailureRecord(
          objectId: r.read<String>('object_id'),
          userId: r.read<String>('user_id'),
          entityType: r.read<String>('entity_type'),
          entityId: r.read<String>('entity_id'),
          reason: SyncFailureReason.values.firstWhere(
            (e) => e.name == r.read<String>('reason'),
            orElse: () => SyncFailureReason.invalidPayload,
          ),
          attempts: r.read<int>('attempts'),
          firstSeenAt: DateTime.fromMillisecondsSinceEpoch(
              r.read<int>('first_seen_at_ms')),
          lastSeenAt: DateTime.fromMillisecondsSinceEpoch(
              r.read<int>('last_seen_at_ms')),
          sanitizedDiagnostic: r.read<String>('sanitized_diagnostic'),
        )
    ];
  }

  Future<int> quarantinedCount(String userId) async {
    final rows = await customSelect(
      'SELECT COUNT(*) AS c FROM sync_failures WHERE user_id = ?',
      variables: [Variable.withString(userId)],
    ).get();
    if (rows.isEmpty) return 0;
    return rows.first.read<int>('c');
  }

  Stream<int> watchQuarantinedCount(String userId) {
    return customSelect(
      'SELECT COUNT(*) AS c FROM sync_failures WHERE user_id = ?',
      variables: [Variable.withString(userId)],
      readsFrom: {syncOutbox}, // trigger re-evaluate when outbox changes
    ).watch().map((rows) => rows.isEmpty ? 0 : rows.first.read<int>('c'));
  }

  Future<void> removeQuarantinedRecord(String objectId, String userId) async {
    await customStatement(
      'DELETE FROM sync_failures WHERE object_id = ? AND user_id = ?',
      [objectId, userId],
    );
  }
}
