-- ============================================================
-- ChronoWarden — self-hosted canonical schema (Postgres 18)
--
-- Replaces the Supabase project: `profiles` is merged into `users`
-- (there is no separate `auth.users`), and Row Level Security is
-- intentionally absent because the database is only ever reached by
-- the API container, which scopes every query to the authenticated
-- user. The database is not published on the host.
--
-- Zero-knowledge model is unchanged: all user content lives in
-- `encrypted_data` (AES-256-GCM, client-side). Only `user_id`, `date`
-- and the preset `name` remain plaintext for filtering/display.
-- ============================================================

create table if not exists users (
  id            uuid primary key default gen_random_uuid(),
  email         text not null unique,
  password_hash text not null,
  full_name     text,
  role          text not null default 'user'    check (role   in ('admin','user')),
  status        text not null default 'approved' check (status in ('pending','approved','rejected')),
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now()
);

-- Opaque bearer tokens. Only the SHA-256 hash is stored, never the token.
create table if not exists sessions (
  token_hash   text primary key,
  user_id      uuid not null references users(id) on delete cascade,
  created_at   timestamptz not null default now(),
  expires_at   timestamptz not null,
  last_seen_at timestamptz not null default now()
);
create index if not exists sessions_user_id_idx on sessions (user_id);
create index if not exists sessions_expires_at_idx on sessions (expires_at);

-- Single-use invitations, bound to an email address. Only the token hash is
-- stored; the raw token is shown once when the admin creates the invite.
create table if not exists invites (
  id          uuid primary key default gen_random_uuid(),
  email       text not null,
  token_hash  text not null unique,
  role        text not null default 'user' check (role in ('admin','user')),
  invited_by  uuid references users(id) on delete set null,
  used_at     timestamptz,
  expires_at  timestamptz not null,
  created_at  timestamptz not null default now()
);
create index if not exists invites_email_idx on invites (email);

create table if not exists time_logs (
  id             uuid primary key default gen_random_uuid(),
  user_id        uuid not null references users(id) on delete cascade,
  date           date not null default current_date,
  encrypted_data text not null default '',
  created_at     timestamptz not null default now()
);
create index if not exists time_logs_user_date_idx on time_logs (user_id, date);
-- One log per user per day.
create unique index if not exists time_logs_user_date_unique on time_logs (user_id, date);

create table if not exists travel_presets (
  id             uuid primary key default gen_random_uuid(),
  user_id        uuid not null references users(id) on delete cascade,
  name           text not null,
  encrypted_data text not null default '',
  created_at     timestamptz not null default now()
);
create index if not exists travel_presets_user_idx on travel_presets (user_id);

create table if not exists user_settings (
  id             uuid primary key default gen_random_uuid(),
  user_id        uuid not null unique references users(id) on delete cascade,
  encrypted_dek  text not null default '',
  kek_salt       text not null default '',
  kek_iterations integer not null default 310000,
  recovery_hash  text,
  encrypted_data text not null default '',
  created_at     timestamptz not null default now(),
  updated_at     timestamptz not null default now()
);
