-- 1. SEASONAL WORK PERIODS (Summer / Winter Time Definitions)
create table work_period_settings (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references auth.users default auth.uid(),
  name text not null,
  start_date date not null,
  end_date date not null,
  expected_minutes int not null,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  constraint date_range_check check (start_date <= end_date)
);

-- 2. DYNAMIC COMMUTE / TRAVEL PRESETS
create table travel_presets (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references auth.users default auth.uid(),
  name text not null,
  default_overhead_minutes int not null,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- 3. ACTUAL TIME LOG entries
create table time_logs (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references auth.users default auth.uid(),
  date date not null default current_date,
  start_time time not null,
  end_time time,
  overhead_minutes int not null,
  expected_minutes int not null,
  lunch_minutes int not null default 0,
  overtime_minutes int not null default 0,
  note text,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- 4. ROW LEVEL SECURITY (RLS) - Data Isolation per User
alter table work_period_settings enable row level security;
alter table travel_presets enable row level security;
alter table time_logs enable row level security;

-- Policies: allow authenticated owner AND anon (user_id IS NULL) full CRUD.
-- NULL user_id matches everything for anon-key usage; replace with
-- "auth.uid() = user_id" once you add Supabase Auth.
create policy "Manage own work periods" on work_period_settings
  for all using (user_id IS NULL OR auth.uid() = user_id);

create policy "Manage own travel presets" on travel_presets
  for all using (user_id IS NULL OR auth.uid() = user_id);

create policy "Manage own time logs" on time_logs
  for all using (user_id IS NULL OR auth.uid() = user_id);
