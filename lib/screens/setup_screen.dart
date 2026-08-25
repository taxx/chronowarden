import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/auth_service.dart';
import '../services/supabase_service.dart';
import 'login_screen.dart';
import 'signup_screen.dart';

/// Complete schema SQL — drops everything and recreates with auth support.
const _kSetupSql = r'''
-- ============================================================
-- ChronoWarden — Full Schema (drops + recreates everything)
-- Run this ONCE in your Supabase SQL Editor
-- ============================================================

-- === MIGRATION (existing databases only — run once) ===
alter table travel_presets add column if not exists productive_commute_minutes int not null default 0;
alter table time_logs add column if not exists productive_commute_minutes int not null default 0;

-- Per-direction commute fields (v2)
alter table travel_presets add column if not exists morning_overhead_minutes int not null default 0;
alter table travel_presets add column if not exists morning_productive_commute_minutes int not null default 0;
alter table travel_presets add column if not exists evening_overhead_minutes int not null default 0;
alter table travel_presets add column if not exists evening_productive_commute_minutes int not null default 0;
alter table time_logs add column if not exists morning_overhead_minutes int not null default 0;
alter table time_logs add column if not exists morning_productive_commute_minutes int not null default 0;
alter table time_logs add column if not exists evening_overhead_minutes int not null default 0;
alter table time_logs add column if not exists evening_productive_commute_minutes int not null default 0;

-- Split existing total values 50/50 into morning/evening
update travel_presets set
  morning_overhead_minutes = default_overhead_minutes / 2,
  evening_overhead_minutes = default_overhead_minutes - (default_overhead_minutes / 2),
  morning_productive_commute_minutes = productive_commute_minutes / 2,
  evening_productive_commute_minutes = productive_commute_minutes - (productive_commute_minutes / 2);

update time_logs set
  morning_overhead_minutes = overhead_minutes / 2,
  evening_overhead_minutes = overhead_minutes - (overhead_minutes / 2),
  morning_productive_commute_minutes = productive_commute_minutes / 2,
  evening_productive_commute_minutes = productive_commute_minutes - (productive_commute_minutes / 2);

-- Flex minutes (v3) — banked overtime spent on personal time
alter table time_logs add column if not exists flex_minutes int not null default 0;

-- User settings table (v3)
create table if not exists user_settings (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references auth.users on delete cascade not null,
  default_flex_minutes int not null default 0,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  unique(user_id)
);
alter table user_settings enable row level security;
create policy "Manage own settings" on user_settings
  for all using (auth.uid() = user_id);

-- 0. Clean slate — drop tables (cascade removes their policies automatically)
drop table if exists time_logs cascade;
drop table if exists travel_presets cascade;
drop table if exists invites cascade;
drop table if exists profiles cascade;

-- Also clean up auth trigger/functions if they exist
drop trigger if exists on_auth_user_created on auth.users;
drop function if exists handle_new_user();
drop function if exists is_admin();
drop function if exists has_profiles();

-- 1. PROFILES — extends auth.users
create table profiles (
  id uuid references auth.users on delete cascade primary key,
  email text not null default '',
  role text not null default 'user' check (role in ('admin', 'user')),
  status text not null default 'pending' check (status in ('pending', 'approved', 'rejected')),
  full_name text,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- 2. INVITE TOKENS
create table invites (
  id uuid default gen_random_uuid() primary key,
  created_by uuid references auth.users on delete set null,
  email text,
  token text not null unique,
  used boolean not null default false,
  expires_at timestamp with time zone,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- 3. TRAVEL PRESETS
create table travel_presets (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references auth.users on delete cascade not null,
  name text not null,
  default_overhead_minutes int not null default 0,
  productive_commute_minutes int not null default 0,
  morning_overhead_minutes int not null default 0,
  morning_productive_commute_minutes int not null default 0,
  evening_overhead_minutes int not null default 0,
  evening_productive_commute_minutes int not null default 0,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- 5. TIME LOGS
create table time_logs (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references auth.users on delete cascade not null,
  date date not null default current_date,
  start_time time not null,
  end_time time,
  expected_minutes int not null,
  lunch_minutes int not null default 0,
  flex_minutes int not null default 0,
  morning_overhead_minutes int not null default 0,
  morning_productive_commute_minutes int not null default 0,
  evening_overhead_minutes int not null default 0,
  evening_productive_commute_minutes int not null default 0,
  overtime_minutes int not null default 0,
  note text,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- 5b. USER SETTINGS — per-user preferences
create table user_settings (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references auth.users on delete cascade not null,
  default_flex_minutes int not null default 0,
  default_expected_minutes int not null default 480,
  reduced_expected_minutes int,
  reduced_start_week int,
  reduced_end_week int,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  updated_at timestamp with time zone default timezone('utc'::text, now()),
  unique(user_id)
);
alter table user_settings enable row level security;
create policy "Manage own settings" on user_settings
  for all using (auth.uid() = user_id);

-- 6. TRIGGER — create profile row on signup
create function handle_new_user()
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

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure handle_new_user();

-- 6b. Helper: check if current user is an approved admin.
--     SECURITY DEFINER bypasses RLS so the policy doesn't recurse.
create function is_admin() returns boolean
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

-- 6c. Helper: check if any profiles exist (used by unauthenticated clients
--     to decide between first-admin signup vs normal login).
create function has_profiles() returns boolean
language sql
security definer
set search_path = public
as $$
  select exists (select 1 from profiles limit 1)
$$;

-- 7. ROW LEVEL SECURITY
alter table profiles enable row level security;
alter table invites enable row level security;
alter table travel_presets enable row level security;
alter table time_logs enable row level security;

-- profiles: everyone can read their own; admins can manage all
create policy "users_view_own_profile" on profiles
  for select using (auth.uid() = id);

create policy "admin_manage_profiles" on profiles
  for all using (is_admin());

-- invites: admins only
create policy "admin_manage_invites" on invites
  for all using (is_admin());

-- user data tables: owner only
create policy "Manage own travel presets" on travel_presets
  for all using (auth.uid() = user_id);

create policy "Manage own time logs" on time_logs
  for all using (auth.uid() = user_id);

-- 8. GRANT — allow service role to manage auth.users (for admin delete)
grant delete on auth.users to service_role;
''';

/// Shown when the Supabase tables are missing.
class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  bool _loading = false;
  bool _copyingSchema = false;
  String? _error;

  /// Probe tables directly — no auth required, just checks they exist.
  Future<void> _verifyTables() async {
    if (!mounted) return;
    setState(() { _loading = true; _error = null; });

    final client = SupabaseService.instance.client;
    bool ok = false;
    try {
      // Probe all 5 tables with a simple select query.
    final tables = ['profiles', 'invites', 'travel_presets', 'time_logs'];
      for (final table in tables) {
        await client.from(table).select('id').limit(1);
      }
      ok = true;
    } catch (e) {
      _error = e.toString();
    }

    if (!mounted) return;
    setState(() => _loading = false);

    if (ok) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✓ Tables verified')),
      );
      // Navigate to the next step.
      final hasProfiles = await AuthService().checkDatabaseState();
      if (!mounted) return;
      if (hasProfiles == true) {
        // Tables exist but no profiles → first admin signup.
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const SignupScreen(isFirstAdmin: true)),
        );
      } else {
        // Tables exist with profiles → normal login.
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    }
  }

  Future<void> _copySchema() async {
    await Clipboard.setData(const ClipboardData(text: _kSetupSql));
    if (!mounted) return;
    setState(() => _copyingSchema = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('✓ SQL copied to clipboard')),
    );
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) setState(() => _copyingSchema = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Database Setup')),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'First-time setup',
                    style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'ChronoWarden needs several tables in your Supabase project.\n\n'
                    '1. Open your Supabase dashboard → SQL Editor\n'
                    '2. Copy the SQL below and paste it into the editor\n'
                    '3. Click RUN\n'
                    '4. Tap "Verify & Continue"\n\n'
                    'This creates the profiles, invites, and data tables\n'
                    'along with RLS policies and a signup trigger.',
                    style: theme.textTheme.bodyLarge,
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Card(
                      color: theme.colorScheme.errorContainer,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(
                          _error!,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onErrorContainer,
                          ),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: _loading ? null : _verifyTables,
                    icon: _loading
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.check_circle),
                    label: const Text('Verify & Continue'),
                  ),
                ],
              ),
            ),
          ),
          _SqlCard(
            title: 'Complete Schema SQL',
            sql: _kSetupSql,
            copying: _copyingSchema,
            onCopy: _copySchema,
            theme: theme,
          ),
          const SliverPadding(padding: EdgeInsets.only(bottom: 32)),
        ],
      ),
    );
  }
}

class _SqlCard extends StatelessWidget {
  final String title;
  final String sql;
  final bool copying;
  final VoidCallback onCopy;
  final ThemeData theme;

  const _SqlCard({
    required this.title,
    required this.sql,
    required this.copying,
    required this.onCopy,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: theme.textTheme.titleSmall),
                OutlinedButton.icon(
                  onPressed: copying ? null : onCopy,
                  icon: Icon(copying ? Icons.check : Icons.content_copy, size: 18),
                  label: Text(copying ? 'Copied!' : 'Copy', style: const TextStyle(fontSize: 13)),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Card(
              color: theme.colorScheme.surfaceContainerHighest,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SelectableText(
                    sql,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
