-- Migration: make user_id nullable so anon-key inserts work.
-- Run this AFTER supabase_schema.sql has already been executed.

-- 1. Drop old policies (we'll recreate them below)
drop policy if exists "Users can manage their own work periods" on work_period_settings;
drop policy if exists "Users can manage their own travel presets" on travel_presets;
drop policy if exists "Users can manage their own time logs" on time_logs;
drop policy if exists "Allow anon insert on work_period_settings" on work_period_settings;
drop policy if exists "Allow anon insert on travel_presets" on travel_presets;
drop policy if exists "Allow anon insert on time_logs" on time_logs;
drop policy if exists "Allow anon select on work_period_settings" on work_period_settings;
drop policy if exists "Allow anon select on travel_presets" on travel_presets;
drop policy if exists "Allow anon select on time_logs" on time_logs;

-- 2. Make user_id nullable on all tables
alter table work_period_settings alter column user_id drop not null;
alter table travel_presets alter column user_id drop not null;
alter table time_logs alter column user_id drop not null;

-- 3. Recreate policies — allow NULL user_id (anon) to match everything
create policy "Manage own work periods" on work_period_settings
  for all using (user_id IS NULL OR auth.uid() = user_id);
create policy "Manage own travel presets" on travel_presets
  for all using (user_id IS NULL OR auth.uid() = user_id);
create policy "Manage own time logs" on time_logs
  for all using (user_id IS NULL OR auth.uid() = user_id);
