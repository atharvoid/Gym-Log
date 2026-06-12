# GymLog Cloud Sync — Design (pre-implementation)

> Status: **designed, not yet implemented.** Workouts are local-only today
> (`workout_sessions.synced` is reserved). This document is the agreed
> blueprint so the implementation PR is mechanical, reviewable, and testable.
> Nothing here ships until the Supabase schema below is deployed and the
> round-trip is verified on-device.

## Goals

1. Local-first stays true: every feature works offline, forever. Sync is a
   background convenience, never a gate.
2. Free-tier friendly: batched pushes (10-minute cadence + critical events),
   no realtime channels, no per-keystroke writes.
3. Loss-proof: deletes use tombstones; nothing is physically removed until
   the server acknowledges. Retries are idempotent.

## Local schema changes (Drift `schemaVersion 1 → 2`)

Add to `workout_sessions`, `workout_exercises`, `workout_sets`, `routines`,
`routine_days`, `routine_exercises`:

| Column | Type | Default | Purpose |
|---|---|---|---|
| `sync_status` | text | `'pending'` | `pending` → `synced` → (`failed` retries as `pending`) |
| `updated_at` | int (unix ms) | now | Last-writer-wins conflict input |
| `deleted_at` | int nullable | null | Tombstone — row hidden from all queries when set |

Migration: `onUpgrade` uses `m.addColumn(...)` per table; existing rows
backfill `sync_status='pending'`, `updated_at=strftime('%s','now')*1000`.
All read queries gain `WHERE deleted_at IS NULL` (single shared helper).
The legacy `workout_sessions.synced` boolean is kept (ignored) until v3.

## State machine

```
write/edit row      → sync_status = 'pending', updated_at = now
delete row          → deleted_at = now, sync_status = 'pending'   (no DELETE)
push acknowledged   → sync_status = 'synced'; tombstoned rows physically purged
push failed         → sync_status stays 'pending' (exponential backoff, max 1h)
```

## SyncService (lib/core/services/sync_service.dart)

- `Timer.periodic(10 min)` while app foregrounded + one shot on resume and
  after `finishWorkout` / routine save / delete (the "critical events").
- **Push:** collect ≤500 pending rows per table, parents before children
  (sessions → exercises → sets), `upsert` to Supabase with `onConflict: id`.
  Row UUIDs are the idempotency keys — retries can never duplicate.
- **Pull (launch + resume):** `select * where user_id = :uid and updated_at >
  :lastPulledAt`; apply with last-writer-wins on `updated_at` (server copy
  wins ties). Remote tombstones tombstone locally.
- Any network/auth failure → silent skip; next tick retries. Zero UI impact.
- Kill switch: `Env.syncEnabled` (`--dart-define SYNC_ENABLED=true`) so the
  feature ships dark and can be enabled per-build.

## Supabase schema (deploy before enabling)

```sql
create table public.workout_sessions (
  id uuid primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  routine_id uuid,
  name text,
  started_at timestamptz not null,
  ended_at timestamptz,
  notes text not null default '',
  total_volume_kg double precision not null default 0,
  updated_at bigint not null,
  deleted_at bigint
);
-- workout_exercises / workout_sets / routines / routine_days /
-- routine_exercises follow the same pattern (mirror local columns + the
-- three sync columns; children carry parent FKs with on delete cascade).

alter table public.workout_sessions enable row level security;
create policy "own rows" on public.workout_sessions
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
-- identical policy on every synced table.

create index ws_user_updated on public.workout_sessions (user_id, updated_at);
```

## Test plan (required before enabling)

1. Unit: state machine transitions (pending→synced, failure retry, tombstone
   purge only after ack) against a fake Supabase client.
2. Migration test: v1 database opens at v2 with backfilled columns and zero
   data loss (drift `schema_test` golden files).
3. Integration (manual, device): airplane-mode workout → reconnect → row
   appears in Supabase; delete on device A → disappears on device B;
   clock-skewed edits resolve by `updated_at`.

## Explicitly out of scope (v1 of sync)

Realtime collaboration, partial-field merge (row-level LWW only), syncing
the exercise library (it is seeded from the bundled JSON on every install),
and SharedPreferences preferences (exercise unit overrides move into
`user_profiles` in v3).
