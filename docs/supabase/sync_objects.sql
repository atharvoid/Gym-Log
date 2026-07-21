-- ════════════════════════════════════════════════════════════════════════
--  GymLog · cloud mirror (sync_objects v2)
--  Run once in the Supabase SQL editor.
--
--  Design: one row per synced entity (workout session, routine, preferences).
--  Monotonic per-entity revisions and operation IDs replace wall-clock-only LWW.
--  Quarantine persistence on client handles deterministic failure modes.
-- ════════════════════════════════════════════════════════════════════════

create table if not exists public.sync_objects (
  id           text        primary key,          -- "<entity_type>:<entity_id>"
  user_id      uuid        not null references auth.users (id) on delete cascade,
  entity_type  text        not null,
  entity_id    text        not null,
  revision     bigint      not null default 1,
  operation_id text        not null default '',
  updated_at   timestamptz not null default now(),
  device_id    text        not null default '',
  deleted      boolean     not null default false,
  payload      text        not null default ''   -- gzip + base64 of entity JSON
);

create index if not exists idx_sync_objects_user_type
  on public.sync_objects (user_id, entity_type);

create index if not exists idx_sync_objects_user_updated
  on public.sync_objects (user_id, updated_at desc);

-- Row-Level Security: a user only ever sees and writes their own rows.
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

-- Monotonic revision check: rejects stale base revisions (revision < old.revision).
create or replace function public.sync_objects_revision_check()
returns trigger language plpgsql as $$
begin
  if new.revision < old.revision then
    raise exception 'Conflict: base revision % is older than server revision %', new.revision, old.revision;
  end if;
  return new;
end;
$$;

drop trigger if exists trg_sync_objects_revision on public.sync_objects;
create trigger trg_sync_objects_revision
  before update on public.sync_objects
  for each row execute function public.sync_objects_revision_check();
