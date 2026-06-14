-- ════════════════════════════════════════════════════════════════════════
--  GymLog · account-deletion policies
--  Run once in the Supabase SQL editor (Dashboard → SQL → New query).
--
--  Two deletion paths are supported:
--    1. The `delete-account` Edge Function (service role) — the complete path,
--       removes data AND the auth.users identity. This is the primary path.
--    2. A client/web FALLBACK that deletes the user's OWN rows directly. That
--       fallback needs the DELETE row-level-security policies below.
--
--  Both `profiles` and `sync_objects` already FK auth.users(id) ON DELETE
--  CASCADE (see profiles.sql / sync_objects.sql), so deleting the auth user
--  via the Edge Function cascades to both tables automatically. The explicit
--  policies + function deletes are belt-and-suspenders.
-- ════════════════════════════════════════════════════════════════════════

-- Let a signed-in user delete their OWN profile row (client fallback path).
drop policy if exists "profiles_delete_own" on public.profiles;
create policy "profiles_delete_own"
  on public.profiles for delete
  using (auth.uid() = id);

-- Let a signed-in user delete their OWN synced objects (client fallback path).
drop policy if exists "sync_objects_delete_own" on public.sync_objects;
create policy "sync_objects_delete_own"
  on public.sync_objects for delete
  using (auth.uid() = user_id);

-- ── Verify the cascade is in place (informational) ──────────────────────────
-- These should already exist from profiles.sql / sync_objects.sql:
--   profiles.id      uuid references auth.users(id) on delete cascade
--   sync_objects.user_id uuid references auth.users(id) on delete cascade
-- If a table was created without the cascade, re-add it, e.g.:
--   alter table public.sync_objects
--     drop constraint if exists sync_objects_user_id_fkey,
--     add  constraint sync_objects_user_id_fkey
--       foreign key (user_id) references auth.users(id) on delete cascade;

-- ── OPTIONAL: no-login deletion requests ────────────────────────────────────
-- The shipped web page (docs/legal/delete-account.html) verifies ownership by
-- making the user SIGN IN, then calls the Edge Function — no manual step. If
-- you also want an email-based request queue for users who can't sign in,
-- create this table and process it out-of-band after confirming the email.
create table if not exists public.deletion_requests (
  id          uuid        primary key default gen_random_uuid(),
  email       text        not null,
  note        text,
  status      text        not null default 'pending',  -- pending | done | rejected
  created_at  timestamptz not null default now()
);
alter table public.deletion_requests enable row level security;
-- Anyone may file a request; only the service role can read/resolve them.
drop policy if exists "deletion_requests_insert_any" on public.deletion_requests;
create policy "deletion_requests_insert_any"
  on public.deletion_requests for insert
  with check (true);
