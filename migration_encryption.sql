-- ============================================================
-- Migration: Add envelope encryption columns
-- Run this ONCE in your Supabase SQL Editor
-- ============================================================

-- 1. Add encrypted_data to time_logs
alter table time_logs
  add column if not exists encrypted_data text not null default '';

-- 2. Add encrypted_data to travel_presets
alter table travel_presets
  add column if not exists encrypted_data text not null default '';

-- 3. Add envelope columns to user_settings
alter table user_settings
  add column if not exists encrypted_dek    text not null default '',
  add column if not exists kek_salt         text not null default '',
  add column if not exists kek_iterations   int  not null default 310000,
  add column if not exists recovery_hash    text,
  add column if not exists encrypted_data   text not null default '',
  add column if not exists created_at       timestamptz default now(),
  add column if not exists updated_at       timestamptz default now();

-- 4. Add unique constraint on user_id (if not already present)
-- Note: This assumes user_settings already has user_id as primary key or unique.
-- If not, uncomment:
-- alter table user_settings add constraint user_settings_user_id_unique unique (user_id);

-- 5. Verify columns were added (optional)
do $$
declare
  col_count int;
begin
  select count(*) into col_count
  from information_schema.columns
  where table_name = 'time_logs' and column_name = 'encrypted_data';
  raise notice 'time_logs.encrypted_data exists: %', col_count > 0;

  select count(*) into col_count
  from information_schema.columns
  where table_name = 'travel_presets' and column_name = 'encrypted_data';
  raise notice 'travel_presets.encrypted_data exists: %', col_count > 0;

  select count(*) into col_count
  from information_schema.columns
  where table_name = 'user_settings' and column_name = 'encrypted_dek';
  raise notice 'user_settings.encrypted_dek exists: %', col_count > 0;
end $$;
