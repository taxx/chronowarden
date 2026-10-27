import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/app_strings.dart';
import '../services/auth_service.dart';
import '../services/supabase_service.dart';
import 'login_screen.dart';
import 'signup_screen.dart';


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

  /// Canonical schema, loaded from the bundled `supabase_schema.sql` asset so
  /// the Setup screen and the repo can never drift apart.
  String _schemaSql = '';

  @override
  void initState() {
    super.initState();
    _loadSchema();
  }

  Future<void> _loadSchema() async {
    final sql = await rootBundle.loadString('supabase_schema.sql');
    if (!mounted) return;
    setState(() => _schemaSql = sql);
  }

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
        SnackBar(content: Text(context.t('✓ Tables verified'))),
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
    await Clipboard.setData(ClipboardData(text: _schemaSql));
    if (!mounted) return;
    setState(() => _copyingSchema = true);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.t('✓ SQL copied to clipboard'))),
    );
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) setState(() => _copyingSchema = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(context.t('Database Setup'))),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.t('First-time setup'),
                    style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    context.t(
                      'ChronoWarden needs several tables in your Supabase project.\n\n'
                      '1. Open your Supabase dashboard → SQL Editor\n'
                      '2. Copy the SQL below and paste it into the editor\n'
                      '3. Click RUN\n'
                      '4. Tap "Verify & Continue"\n\n'
                      'This creates the profiles, invites, and data tables\n'
                      'along with RLS policies and a signup trigger.',
                    ),
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
                    label: Text(context.t('Verify & Continue')),
                  ),
                ],
              ),
            ),
          ),
          _SqlCard(
            title: context.t('Complete Schema SQL'),
            sql: _schemaSql,
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
                  label: Text(copying ? context.t('Copied!') : context.t('Copy'), style: const TextStyle(fontSize: 13)),
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
