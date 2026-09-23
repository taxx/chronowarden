-- ============================================================
-- ChronoWarden — Canonical database schema
--
-- This mirrors the deployed production schema and is the single
-- source of truth for bootstrapping a new Supabase project. The
-- in-app Setup screen loads this exact file (asset) instead of
-- embedding a copy, so it can never drift again.
--
-- Safe to run on an empty Supabase project. It is idempotent
-- (CREATE ... IF NOT EXISTS / CREATE OR REPLACE / DROP POLICY IF
-- EXISTS) and never drops user data.
--
-- Zero-knowledge model: all user content lives exclusively in
-- `encrypted_data` (AES-256-GCM). Only `user_id`, `date` and the
-- preset `name` remain plaintext, for RLS scoping, server-side
-- filtering and dropdown display.
-- ============================================================

-- 1. PROFILES — mirrors auth.users (PostgREST cannot join the auth schema)
create table if not exists public.profiles (
  id uuid references auth.users on delete cascade primary key,
  email text not null default '',
  role text not null default 'user' check (role in ('admin', 'user')),
  status text not null default 'pending' check (status in ('pending', 'approved', 'rejected')),
  full_name text,
  created_at timestamptz not null default timezone('utc', now())
);

-- 2. INVITE TOKENS — admin-issued, single-use
create table if not exists public.invites (
  id uuid primary key default gen_random_uuid(),
  created_by uuid references auth.users on delete set null,
  email text,
  token text not null unique,
  used boolean not null default false,
  expires_at timestamptz,
  created_at timestamptz not null default timezone('utc', now())
);

-- 3. TIME LOGS — one encrypted row per workday
create table if not exists public.time_logs (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users on delete cascade,
  date date not null default current_date,
  encrypted_data text not null default '',
  created_at timestamptz not null default timezone('utc', now())
);

-- 4. TRAVEL PRESETS — encrypted commute scenarios; `name` is plaintext for dropdowns
create table if not exists public.travel_presets (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users on delete cascade,
  name text not null,
  encrypted_data text not null default '',
  created_at timestamptz not null default timezone('utc', now())
);

-- 5. USER SETTINGS — envelope columns (DEK wrap) + encrypted settings payload
create table if not exists public.user_settings (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null unique references auth.users on delete cascade,
  encrypted_dek text not null default '',
  kek_salt text not null default '',
  kek_iterations integer not null default 310000,
  recovery_hash text,
  encrypted_data text not null default '',
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz default now()
);

-- 6. FUNCTIONS ---------------------------------------------------------------

-- Create a profile row whenever a new auth user signs up.
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into profiles (id, email, full_name, role, status)
  values (
    new.id,
    new.email,
    new.raw_user_meta_data->>'full_name',
    coalesce(new.raw_user_meta_data->>'role', 'user'),
    coalesce(new.raw_user_meta_data->>'status', 'pending')
  );
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- SECURITY DEFINER bypasses RLS: avoids recursive policy checks and lets
-- unauthenticated clients probe DB state.
create or replace function public.is_admin()
returns boolean
language sql
security definer
set search_path = public
as $$
  select exists (
    select 1 from profiles
    where id = auth.uid()
      and role = 'admin'
      and status = 'approved'
  )
$$;

create or replace function public.has_profiles()
returns boolean
language sql
security definer
set search_path = public
as $$
  select exists (select 1 from profiles limit 1)
$$;

-- 7. ROW LEVEL SECURITY ------------------------------------------------------

alter table public.profiles enable row level security;
alter table public.invites enable row level security;
alter table public.time_logs enable row level security;
alter table public.travel_presets enable row level security;
alter table public.user_settings enable row level security;

-- profiles: users read their own row; admins manage everyone
drop policy if exists "users_view_own_profile" on public.profiles;
create policy "users_view_own_profile" on public.profiles
  for select using (auth.uid() = id);

drop policy if exists "admin_manage_profiles" on public.profiles;
create policy "admin_manage_profiles" on public.profiles
  for all using (public.is_admin());

-- invites: admins only
drop policy if exists "admin_manage_invites" on public.invites;
create policy "admin_manage_invites" on public.invites
  for all using (public.is_admin());

-- user data: owner only
drop policy if exists "Manage own travel presets" on public.travel_presets;
create policy "Manage own travel presets" on public.travel_presets
  for all using (auth.uid() = user_id);

drop policy if exists "Manage own time logs" on public.time_logs;
create policy "Manage own time logs" on public.time_logs
  for all using (auth.uid() = user_id);

drop policy if exists "Manage own settings" on public.user_settings;
create policy "Manage own settings" on public.user_settings
  for all using (auth.uid() = user_id);

-- 8. REALTIME — cross-device sync for time logs (idempotent)
do $$
begin
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'time_logs'
  ) then
    alter publication supabase_realtime add table public.time_logs;
  end if;
end
$$;
