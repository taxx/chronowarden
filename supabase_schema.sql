-- 1. SEASONAL WORK PERIODS (Summer / Winter Time Definitions)
create table work_period_settings (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references auth.users not null default auth.uid(),
  name text not null, -- e.g., "Winter Time 2025", "Summer Time 2026"
  start_date date not null, -- e.g., '2026-06-01'
  end_date date not null, -- e.g., '2026-08-31'
  expected_minutes int not null, -- e.g., 435 or 480
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  
  constraint date_range_check check (start_date <= end_date)
);

-- 2. DYNAMIC COMMUTE / TRAVEL PRESETS
create table travel_presets (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references auth.users not null default auth.uid(),
  name text not null, -- e.g., "Train via Mörby", "Car", "WFH"
  default_overhead_minutes int not null, -- Total non-work minutes (lunch + commute buffer)
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- 3. ACTUAL TIME LOG entries
create table time_logs (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references auth.users not null default auth.uid(),
  date date not null default current_date,
  
  start_time time not null,
  end_time time, -- Nullable while the workday is currently active
  
  overhead_minutes int not null,
  expected_minutes int not null,
  overtime_minutes int not null default 0, -- Calculated locally or stored upon closing the day
  note text,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- 4. ROW LEVEL SECURITY (RLS) - Data Isolation per User
alter table work_period_settings enable row level security;
alter table travel_presets enable row level security;
alter table time_logs enable row level security;

-- Create RLS policies to restrict operations to the authenticated owner
create policy "Users can manage their own work periods" on work_period_settings
  for all using (auth.uid() = user_id);

create policy "Users can manage their own travel presets" on travel_presets
  for all using (auth.uid() = user_id);

create policy "Users can manage their own time logs" on time_logs
  for all using (auth.uid() = user_id);

-- Anon-key fallback (allows unauthenticated INSERT/SELECT for MVP use).
-- Once you add Supabase Auth you can remove these six policies.
create policy "Allow anon insert on work_period_settings" on work_period_settings
  for insert with check (true);
create policy "Allow anon insert on travel_presets" on travel_presets
  for insert with check (true);
create policy "Allow anon insert on time_logs" on time_logs
  for insert with check (true);
create policy "Allow anon select on work_period_settings" on work_period_settings
  for select using (true);
create policy "Allow anon select on travel_presets" on travel_presets
  for select using (true);
create policy "Allow anon select on time_logs" on time_logs
  for select using (true);
