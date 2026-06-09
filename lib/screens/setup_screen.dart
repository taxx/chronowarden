import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_state.dart';

/// Embedded SQL — avoids asset loading issues on Flutter Web.
const _kSetupSql = '''
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
  overtime_minutes int not null default 0,
  note text,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- 4. ROW LEVEL SECURITY (RLS) — Data Isolation per User
alter table work_period_settings enable row level security;
alter table travel_presets enable row level security;
alter table time_logs enable row level security;

-- Owned-data policies (authenticated users only)
create policy "Manage own work periods" on work_period_settings
  for all using (user_id IS NULL OR auth.uid() = user_id);
create policy "Manage own travel presets" on travel_presets
  for all using (user_id IS NULL OR auth.uid() = user_id);
create policy "Manage own time logs" on time_logs
  for all using (user_id IS NULL OR auth.uid() = user_id);
''';

/// Migration SQL — run AFTER the initial schema if tables already exist.
const _kMigrationSql = '''
-- Migration: make user_id nullable so anon-key inserts work.
-- Run this if you already created the tables with "not null" user_id.

drop policy if exists "Users can manage their own work periods" on work_period_settings;
drop policy if exists "Users can manage their own travel presets" on travel_presets;
drop policy if exists "Users can manage their own time logs" on time_logs;
drop policy if exists "Allow anon insert on work_period_settings" on work_period_settings;
drop policy if exists "Allow anon insert on travel_presets" on travel_presets;
drop policy if exists "Allow anon insert on time_logs" on time_logs;
drop policy if exists "Allow anon select on work_period_settings" on work_period_settings;
drop policy if exists "Allow anon select on travel_presets" on travel_presets;
drop policy if exists "Allow anon select on time_logs" on time_logs;

alter table work_period_settings alter column user_id drop not null;
alter table travel_presets alter column user_id drop not null;
alter table time_logs alter column user_id drop not null;

create policy "Manage own work periods" on work_period_settings
  for all using (user_id IS NULL OR auth.uid() = user_id);
create policy "Manage own travel presets" on travel_presets
  for all using (user_id IS NULL OR auth.uid() = user_id);
create policy "Manage own time logs" on time_logs
  for all using (user_id IS NULL OR auth.uid() = user_id);
''';

/// Shown when the Supabase tables are missing or not working.
class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  bool _loading = false;
  bool _copyingSchema = false;
  bool _copyingMigration = false;
  String? _error;

  /// Probe all three tables by trying an actual insert then delete.
  Future<void> _verifyTables() async {
    if (!mounted) return;
    setState(() { _loading = true; _error = null; });

    final state = AppState();
    final ready = await state.refresh();

    if (!mounted) return;
    setState(() {
      _loading = false;
      if (!ready) {
        _error = 'Tables not found or not working. See instructions below.';
      }
    });

    if (ready) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✓ Tables verified')),
      );
    }
  }

  Future<void> _copySchema() async {
    await Clipboard.setData(const ClipboardData(text: _kSetupSql));
    if (!mounted) return;
    setState(() => _copyingSchema = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('✓ Schema SQL copied to clipboard')),
    );
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) setState(() => _copyingSchema = false);
  }

  Future<void> _copyMigration() async {
    await Clipboard.setData(const ClipboardData(text: _kMigrationSql));
    if (!mounted) return;
    setState(() => _copyingMigration = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('✓ Migration SQL copied to clipboard')),
    );
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) setState(() => _copyingMigration = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Database Setup')),
      body: CustomScrollView(
        slivers: [
          // -- Instructions ----------------------------------------
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
                    'ChronoWarden needs three tables in your Supabase project.\n\n'
                    '1. Open your Supabase dashboard → SQL Editor\n'
                    '2. Copy the SQL below and paste it into the editor\n'
                    '3. Click RUN\n'
                    '4. Tap "Verify & Continue"\n\n'
                    'Already ran the initial schema but inserts fail with\n'
                    '"null value in column user_id violates not-null constraint"?\n'
                    '→ Run the **Migration SQL** below instead (scroll down).',
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
                  Row(
                    children: [
                      FilledButton.icon(
                        onPressed: _loading ? null : _verifyTables,
                        icon: _loading
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.check_circle),
                        label: const Text('Verify & Continue'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // -- Schema SQL --------------------------------------
          _SqlCard(
            title: 'Initial Schema SQL',
            sql: _kSetupSql,
            copying: _copyingSchema,
            onCopy: _copySchema,
            theme: theme,
          ),

          // -- Migration SQL -----------------------------------
          _SqlCard(
            title: 'Migration SQL (if "user_id not-null" error)',
            sql: _kMigrationSql,
            copying: _copyingMigration,
            onCopy: _copyMigration,
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
