# GymLog Sync — "local source of truth, cloud mirror"

## Principles
- **Local-first.** Every write commits to SQLite (Drift) immediately and the UI
  reads only local state. The app is fully functional offline.
- **Cloud is a mirror, not a dependency.** After a local commit, a compressed
  snapshot is queued and uploaded in the background. The network never blocks
  the user and a failure never loses data.
- **Free-tier conscious.** Batched upserts, gzip-compressed payloads, one row
  per entity, and **no realtime subscriptions** — high-frequency workout data is
  pulled on demand only.

## Data flow

```
write ─▶ SQLite commit ─▶ outbox.enqueue(compressed snapshot) ─▶ debounce(5s)
                                                                     │
 explicit triggers (post-workout, app background, Sync Now) ────────┤
                                                                     ▼
                                          SyncEngine.syncNow ─▶ drain outbox
                                          in batches ─▶ Supabase upsert ─▶ delete
                                          acked rows.  Failure ⇒ rows stay queued.
```

- **Outbox** (`sync_outbox` table): durable local queue. One row per entity
  snapshot; a new edit to the same entity *replaces* its queued row (coalescing
  → one upload, naturally last-write-wins locally). Survives app restarts ⇒
  offline devices queue indefinitely.
- **Debounce:** uploads fire after **5s of write inactivity**, or immediately on
  explicit triggers.
- **Triggers:** post-workout (finish), app backgrounding (`AppLifecycleListener`),
  Settings **"Sync Now"**, and a debounced arm on resume.

## Backend (`docs/supabase/sync_objects.sql`)
A single table `sync_objects(id, user_id, entity_type, entity_id, updated_at,
deleted, payload)`:
- **RLS:** `auth.uid() = user_id` for select/insert/update — users touch only
  their own rows.
- **Conflict resolution:** server-side **last-write-wins** by `updated_at`,
  enforced by a `BEFORE UPDATE` trigger that ignores stale writes.
- **Payload:** opaque gzip+base64 of the entity JSON (see `SyncCodec`). New
  entity types need **no schema change**.

## Restore (reinstall / new device)
On login the splash kicks off `SyncEngine.pull()` in the background: it fetches
the user's `sync_objects` and rehydrates local storage. Because the queue is
durable and the cloud is authoritative on pull, a user can uninstall and
reinstall years later and recover their history.

## Offline / connectivity
Writes queue indefinitely. Retries happen on every trigger (next write's
debounce, post-workout, backgrounding, resume, manual). A dedicated
connectivity-event trigger (`connectivity_plus`) is a planned enhancement; the
resume + debounce triggers already cover the common reconnect path.

## Scope shipped vs. planned
- **Shipped & tested (fake-remote unit tests):** the full engine — outbox,
  debounce, batched drain, offline requeue/retry, LWW, pull-restore, status —
  wired for **workout sessions** (the irreplaceable history; exercise stats are
  derived from these).
- **Same-pattern extensions:** routines and any future body-measurements reuse
  the identical path (add an `export/import` pair + an `enqueue` call). User
  **preferences** already sync via `ProfileSyncService` (display name + profile).
- **Device/Supabase-only verification:** live batched network behavior, the
  app-lifecycle flush, and the server LWW trigger require a provisioned project
  and a device; the SQL + client are shipped for that final check.
