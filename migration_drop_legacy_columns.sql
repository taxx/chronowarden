-- ============================================================
-- Migration: Drop legacy plaintext columns
-- Run this AFTER verifying all users have migrated to encrypted_data
-- ============================================================

-- 1. Drop legacy columns from time_logs
alter table time_logs
  drop column if exists start_time,
  drop column if exists end_time,
  drop column if exists expected_minutes,
  drop column if exists lunch_minutes,
  drop column if exists flex_minutes,
  drop column if exists morning_overhead_minutes,
  drop column if exists morning_productive_commute_minutes,
  drop column if exists evening_overhead_minutes,
  drop column if exists evening_productive_commute_minutes,
  drop column if exists overhead_minutes,
  drop column if exists productive_commute_minutes,
  drop column if exists overtime_minutes,
  drop column if exists note;

-- 2. Drop legacy columns from travel_presets
alter table travel_presets
  drop column if exists default_overhead_minutes,
  drop column if exists productive_commute_minutes,
  drop column if exists morning_overhead_minutes,
  drop column if exists morning_productive_commute_minutes,
  drop column if exists evening_overhead_minutes,
  drop column if exists evening_productive_commute_minutes;

-- 3. Drop legacy columns from user_settings
alter table user_settings
  drop column if exists default_flex_minutes,
  drop column if exists default_expected_minutes,
  drop column if exists reduced_expected_minutes,
  drop column if exists reduced_start_week,
  drop column if exists reduced_end_week;

-- 4. Verify
do $$
declare
  col_count int;
begin
  select count(*) into col_count
  from information_schema.columns
  where table_name = 'time_logs' and column_name = 'expected_minutes';
  raise notice 'time_logs.expected_minutes dropped: %', col_count = 0;

  select count(*) into col_count
  from information_schema.columns
  where table_name = 'travel_presets' and column_name = 'default_overhead_minutes';
  raise notice 'travel_presets.default_overhead_minutes dropped: %', col_count = 0;

  select count(*) into col_count
  from information_schema.columns
  where table_name = 'user_settings' and column_name = 'default_expected_minutes';
  raise notice 'user_settings.default_expected_minutes dropped: %', col_count = 0;
end $$;
