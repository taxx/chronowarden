import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../app_state.dart';

/// Shown when the Supabase tables are missing.
/// Displays the raw SQL from supabase_schema.sql and guides the user
/// to paste it into the Supabase SQL Editor.
class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  String _sql = '';
  bool _loading = true;
  String? _error;
  bool _verified = false;

  @override
  void initState() {
    super.initState();
    _loadSql();
  }

  Future<void> _loadSql() async {
    try {
      _sql = await rootBundle.loadString('supabase_schema.sql');
    } catch (e) {
      // Fallback: embedded version if asset is missing
      _sql = '''
create table work_period_settings (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references auth.users not null default auth.uid(),
  name text not null,
  start_date date not null,
  end_date date not null,
  expected_minutes int not null,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  constraint date_range_check check (start_date <= end_date)
);

create table travel_presets (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references auth.users not null default auth.uid(),
  name text not null,
  default_overhead_minutes int not null,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

create table time_logs (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references auth.users not null default auth.uid(),
  date date not null default current_date,
  start_time time not null,
  end_time time,
  overhead_minutes int not null,
  expected_minutes int not null,
  overtime_minutes int not null default 0,
  note text,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Enable RLS
alter table work_period_settings enable row level security;
alter table travel_presets enable row level security;
alter table time_logs enable row level security;

-- RLS policies
create policy "Users can manage their own work periods" on work_period_settings
  for all using (auth.uid() = user_id);
create policy "Users can manage their own travel presets" on travel_presets
  for all using (auth.uid() = user_id);
create policy "Users can manage their own time logs" on time_logs
  for all using (auth.uid() = user_id);
''';
    }
    setState(() => _loading = false);
  }

  /// Try to query a table — if it works, tables are set up.
  Future<void> _verifyTables() async {
    setState(() { _loading = true; _error = null; });

    try {
      // Probe: try to read from each table. If they exist, we're good.
      await Future.wait([
        AppState().logs.all(),
        AppState().periods.all(),
        AppState().presets.all(),
      ]);
      setState(() {
        _loading = false;
        _verified = true;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✓ Tables verified — refreshing app…')),
      );
      // Refresh state and signal that setup is done.
      await AppState().refresh();
      // The main app will pick up the new state via ListenableBuilder.
    } catch (e) {
      setState(() {
        _loading = false;
        _error = 'Still missing: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Database Setup')),
      body: _loading && _sql.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
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
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'ChronoWarden needs three tables in your Supabase project.\n\n'
                          '1. Open your Supabase dashboard → SQL Editor\n'
                          '2. Copy the SQL below\n'
                          '3. Paste it and click RUN\n\n'
                          'Then tap "Verify & Continue".',
                          style: theme.textTheme.bodyLarge,
                        ),
                        if (_error != null) ...[
                          const SizedBox(height: 12),
                          Card(color: theme.colorScheme.errorContainer, child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Text(_error!, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onErrorContainer)),
                          )),
                        ],
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          onPressed: _loading ? null : _verifyTables,
                          icon: _loading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.check_circle),
                          label: Text(_verified ? 'Verified!' : 'Verify & Continue'),
                        ),
                      ],
                    ),
                  ),
                ),

                // -- SQL code block --------------------------------------
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Text('SQL Schema', style: theme.textTheme.titleSmall),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Card(
                      color: theme.colorScheme.surfaceContainerHighest,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Text(
                            _sql,
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontFamily: 'monospace',
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SliverPadding(padding: EdgeInsets.only(bottom: 32)),
              ],
            ),
    );
  }
}
