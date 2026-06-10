# Migration SQL — add missing columns / functions

Run this in Supabase SQL Editor if you hit schema issues.
It only adds/fixes things — never drops data.

```sql
-- Add lunch_minutes to time_logs if missing
do $$
begin
  if not exists (
    select 1 from information_schema.columns
    where table_name = 'time_logs' and column_name = 'lunch_minutes'
  ) then
    alter table time_logs add column lunch_minutes int not null default 0;
  end if;
end $$;

-- Add email to profiles if missing
do $$
begin
  if not exists (
    select 1 from information_schema.columns
    where table_name = 'profiles' and column_name = 'email'
  ) then
    alter table profiles add column email text not null default '';
    -- Backfill from auth.users
    update profiles set email = (
      select email from auth.users where auth.users.id = profiles.id
    ) where email = '';
  end if;
end $$;

-- Create has_profiles() function if missing
create or replace function has_profiles() returns boolean
language sql
security definer
set search_path = public
as $$
  select exists (select 1 from profiles limit 1)
$$;

-- Create is_admin() function if missing
create or replace function is_admin() returns boolean
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
```
