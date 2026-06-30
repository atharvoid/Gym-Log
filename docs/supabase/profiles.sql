-- ════════════════════════════════════════════════════════════════════════
--  GymLog · remote profile store
--  Run once in the Supabase SQL editor (Dashboard → SQL → New query).
--  This is the source of truth for a user's display name so it survives
--  reinstalls and follows them across devices. Workout data stays local.
-- ════════════════════════════════════════════════════════════════════════

create table if not exists public.profiles (
  id                  uuid        primary key references auth.users (id) on delete cascade,
  display_name        text        not null,
  email               text,
  -- Authoritative first-run gate: set to true by the client once the
  -- onboarding wizard completes. Backfill existing named users via:
  --   update public.profiles set onboarding_complete = true
  --    where coalesce(trim(display_name), '') <> '';
  onboarding_complete boolean     not null default false,
  created_at          timestamptz not null default now(),
  updated_at          timestamptz not null default now()
);

-- Row-Level Security: a user may only ever see and write their OWN row.
-- The app talks to PostgREST with the user's auth JWT, so auth.uid() is them.
alter table public.profiles enable row level security;

drop policy if exists "profiles_select_own" on public.profiles;
create policy "profiles_select_own"
  on public.profiles for select
  using (auth.uid() = id);

drop policy if exists "profiles_insert_own" on public.profiles;
create policy "profiles_insert_own"
  on public.profiles for insert
  with check (auth.uid() = id);

drop policy if exists "profiles_update_own" on public.profiles;
create policy "profiles_update_own"
  on public.profiles for update
  using (auth.uid() = id)
  with check (auth.uid() = id);

-- Keep updated_at honest on every write (the client also sends it, but this
-- guarantees it server-side).
create or replace function public.touch_profiles_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

drop trigger if exists trg_profiles_updated_at on public.profiles;
create trigger trg_profiles_updated_at
  before update on public.profiles
  for each row execute function public.touch_profiles_updated_at();

-- NOTE: The app is resilient to this table not existing yet — profile writes
-- queue locally and retry on the next launch, so nothing breaks before you
-- run this. Once the table is live, queued names sync automatically.
