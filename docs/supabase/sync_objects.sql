-- ════════════════════════════════════════════════════════════════════════
--  GymLog · cloud mirror (sync_objects)
--  Run once in the Supabase SQL editor.
--
--  Design: one row per synced entity (workout session, …). The body is an
--  opaque, gzip+base64 `payload` produced on-device — so adding new entity
--  types never requires a schema change, RLS stays trivial, and rows stay
--  small for the free tier. Conflict resolution is last-write-wins by
--  `updated_at`, enforced server-side by the trigger below.
-- ════════════════════════════════════════════════════════════════════════

create table if not exists public.sync_objects (
  id          text        primary key,          -- "<entity_type>:<entity_id>"
  user_id     uuid        not null references auth.users (id) on delete cascade,
  entity_type text        not null,
  entity_id   text        not null,
  updated_at  timestamptz not null default now(),
  deleted     boolean     not null default false,
  payload     text        not null default ''   -- gzip + base64 of entity JSON
);

create index if not exists idx_sync_objects_user_type
  on public.sync_objects (user_id, entity_type);

-- Covers the pull query: WHERE user_id = $1 ORDER BY updated_at DESC.
-- Without this the planner does a sequential scan + sort for every login pull.
create index if not exists idx_sync_objects_user_updated
  on public.sync_objects (user_id, updated_at desc);

-- Row-Level Security: a user only ever sees and writes their own rows.
-- PostgREST runs with the caller's JWT, so auth.uid() is them.
alter table public.sync_objects enable row level security;

drop policy if exists "sync_select_own" on public.sync_objects;
create policy "sync_select_own" on public.sync_objects
  for select using (auth.uid() = user_id);

drop policy if exists "sync_insert_own" on public.sync_objects;
create policy "sync_insert_own" on public.sync_objects
  for insert with check (auth.uid() = user_id);

drop policy if exists "sync_update_own" on public.sync_objects;
create policy "sync_update_own" on public.sync_objects
  for update using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- LAST-WRITE-WINS: on a conflicting upsert, keep whichever row has the newer
-- updated_at. A stale write (older timestamp) is silently ignored — the
-- existing newer values are preserved. This makes multi-device sync safe
-- regardless of upload order.
create or replace function public.sync_objects_lww()
returns trigger language plpgsql as $$
begin
  if new.updated_at < old.updated_at then
    return old; -- incoming write is stale → keep what we have
  end if;
  return new;
end;
$$;

drop trigger if exists trg_sync_objects_lww on public.sync_objects;
create trigger trg_sync_objects_lww
  before update on public.sync_objects
  for each row execute function public.sync_objects_lww();

-- NOTE: No realtime publication is enabled for this table — high-frequency
-- workout writes are pulled on demand (login / Sync Now), never streamed,
-- to stay within free-tier limits.
