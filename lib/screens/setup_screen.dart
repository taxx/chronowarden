import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_state.dart';

/// Embedded SQL — avoids asset loading issues on Flutter Web.
const _kSetupSql = '''
-- 1. SEASONAL WORK PERIODS (Summer / Winter Time Definitions)
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

-- 2. DYNAMIC COMMUTE / TRAVEL PRESETS
create table travel_presets (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references auth.users not null default auth.uid(),
  name text not null,
  default_overhead_minutes int not null,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- 3. ACTUAL TIME LOG entries
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

-- 4. ROW LEVEL SECURITY (RLS) — Data Isolation per User
alter table work_period_settings enable row level security;
alter table travel_presets enable row level security;
alter table time_logs enable row level security;

-- Owned-data policies (authenticated users only)
create policy "Users can manage their own work periods" on work_period_settings
  for all using (auth.uid() = user_id);
create policy "Users can manage their own travel presets" on travel_presets
  for all using (auth.uid() = user_id);
create policy "Users can manage their own time logs" on time_logs
  for all using (auth.uid() = user_id);

-- Anon-key fallback (allows unauthenticated INSERT/SELECT for MVP use).
-- Once you add Supabase Auth you can remove these three policies.
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
''';

/// Shown when the Supabase tables are missing.
class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  bool _loading = false;
  bool _copying = false;
  String? _error;

  /// Probe all three tables. If they all respond, mark tables as ready.
  Future<void> _verifyTables() async {
    if (!mounted) return;
    setState(() { _loading = true; _error = null; });

    final state = AppState();
    final ready = await state.refresh();

    if (!mounted) return;
    setState(() {
      _loading = false;
      if (!ready) {
        _error = 'Tables not found yet. Run the SQL in your Supabase dashboard first.';
      }
    });

    if (ready) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✓ Tables verified')),
      );
    }
  }

  Future<void> _copyToClipboard() async {
    await Clipboard.setData(const ClipboardData(text: _kSetupSql));
    if (!mounted) return;
    setState(() => _copying = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('✓ SQL copied to clipboard')),
    );
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) setState(() => _copying = false);
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
                    '2. Copy the SQL below\n'
                    '3. Paste it and click RUN\n\n'
                    'Then tap "Verify & Continue".',
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
                      const SizedBox(width: 12),
                      OutlinedButton.icon(
                        onPressed: _copying ? null : _copyToClipboard,
                        icon: Icon(_copying ? Icons.check : Icons.content_copy),
                        label: Text(_copying ? 'Copied!' : 'Copy SQL'),
                      ),
                    ],
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
                    child: SelectableText(
                      _kSetupSql,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontFamily: 'monospace',
                        fontSize: 12,
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
