import 'package:drift/drift.dart';

/// The local-first sync queue. Every cloud-relevant write appends one row
/// here; the [SyncEngine] drains it in debounced batches and deletes rows
/// once the backend acknowledges them. Rows survive app restarts, so an
/// offline device queues indefinitely and flushes when it can.
///
/// One row == one entity snapshot to upsert (or a tombstone to delete). The
/// payload is the gzip+base64 of the entity's JSON, keeping the queue (and
/// the eventual network request) compact for the free tier.
@DataClassName('SyncOutboxRow')
class SyncOutbox extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// 'session' | 'routine' — the kind of entity this row carries.
  TextColumn get entityType => text()();

  /// The entity's primary key (workout session id, routine id, …).
  TextColumn get entityId => text()();

  /// Owner — every synced object is scoped to one user (RLS server-side).
  TextColumn get userId => text()();

  /// 'upsert' | 'delete'. Deletes carry an empty payload + a tombstone.
  TextColumn get op => text().withDefault(const Constant('upsert'))();

  /// gzip + base64 of the entity JSON. Empty for deletes.
  TextColumn get payload => text().withDefault(const Constant(''))();

  /// Logical version for last-write-wins (epoch millis at enqueue time).
  IntColumn get updatedAtMs => integer()();

  /// When this queue row was created (epoch millis) — drain oldest first.
  IntColumn get createdAtMs => integer()();
  // Primary key is `id` implicitly via autoIncrement().
}
