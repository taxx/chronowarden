-- ============================================================
-- Migration: Replace work_period_settings with work_config
-- Run this ONCE in your Supabase SQL Editor
-- ============================================================

-- 1. Add work config columns to user_settings
alter table user_settings add column if not exists default_expected_minutes int not null default 480;
alter table user_settings add column if not exists reduced_expected_minutes int;
alter table user_settings add column if not exists reduced_start_week int;
alter table user_settings add column if not exists reduced_end_week int;
alter table user_settings add column if not exists updated_at timestamptz default now();

-- 2. Migrate existing data — convert work_period_settings to work_config
do $$
declare
  cur record;
  mode_val int;
  alt_record record;
begin
  for cur in select distinct user_id from work_period_settings loop
    -- Find mode (most common expected_minutes) as default
    select expected_minutes into mode_val
    from work_period_settings
    where user_id = cur.user_id
    group by expected_minutes
    order by count(*) desc
    limit 1;

    -- Find alternative period (if any) — take the one with fewer minutes
    select expected_minutes, min(start_date) as start_date, max(end_date) as end_date
    into alt_record
    from work_period_settings
    where user_id = cur.user_id
      and expected_minutes != mode_val
    group by expected_minutes
    order by expected_minutes asc
    limit 1;

    -- Upsert into user_settings
    if alt_record.expected_minutes is not null then
      insert into user_settings (user_id, default_expected_minutes, reduced_expected_minutes, reduced_start_week, reduced_end_week)
      values (cur.user_id, mode_val, alt_record.expected_minutes, 
              extract(week from alt_record.start_date), 
              extract(week from alt_record.end_date))
      on conflict (user_id) do update set
        default_expected_minutes = mode_val,
        reduced_expected_minutes = alt_record.expected_minutes,
        reduced_start_week = extract(week from alt_record.start_date),
        reduced_end_week = extract(week from alt_record.end_date),
        updated_at = now();
    else
      insert into user_settings (user_id, default_expected_minutes)
      values (cur.user_id, mode_val)
      on conflict (user_id) do update set
        default_expected_minutes = mode_val,
        reduced_expected_minutes = null,
        reduced_start_week = null,
        reduced_end_week = null,
        updated_at = now();
    end if;
  end loop;
end;
$$;

-- 3. Drop old table (cascade drops its RLS policies too)
drop table if exists work_period_settings cascade;
