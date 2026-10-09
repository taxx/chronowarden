import 'package:flutter/material.dart';

import '../models/changelog.dart';
import '../services/changelog_service.dart';

/// "What's New" — the app changelog, generated from the git history.
///
/// Reachable from About → What's New and Settings → About & Open Source.
class ChangelogScreen extends StatefulWidget {
  const ChangelogScreen({super.key});

  @override
  State<ChangelogScreen> createState() => _ChangelogScreenState();
}

class _ChangelogScreenState extends State<ChangelogScreen> {
  late final Future<List<ChangelogGroup>> _future;

  @override
  void initState() {
    super.initState();
    _future = ChangelogService().load();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text("What's New")),
      body: SafeArea(
        child: FutureBuilder<List<ChangelogGroup>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return _message(
                theme,
                Icons.error_outline,
                'Could not load the changelog.',
              );
            }

            final groups = snapshot.data ?? const <ChangelogGroup>[];
            if (groups.isEmpty) {
              return _message(
                theme,
                Icons.history_toggle_off,
                'No changelog entries yet.',
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: groups.length,
              itemBuilder: (context, i) => _groupCard(theme, groups[i]),
            );
          },
        ),
      ),
    );
  }

  Widget _groupCard(ThemeData theme, ChangelogGroup group) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.calendar_today_outlined,
                    size: 16, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  _formatDate(group.date),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  group.entries.length == 1
                      ? '1 change'
                      : '${group.entries.length} changes',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            for (final entry in group.entries) _entryRow(theme, entry),
          ],
        ),
      ),
    );
  }

  Widget _entryRow(ThemeData theme, ChangelogEntry entry) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Icon(Icons.circle,
                size: 6, color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(entry.text, style: theme.textTheme.bodyMedium),
                if (entry.hash != null)
                  Text(
                    entry.hash!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontFamily: 'monospace',
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _message(ThemeData theme, IconData icon, String text) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: 12),
            Text(text, style: theme.textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  /// "2026-10-09" → "Oct 9, 2026". Falls back to the raw string.
  static String _formatDate(String iso) {
    final p = DateTime.tryParse(iso);
    if (p == null) return iso;
    return '${_months[p.month - 1]} ${p.day}, ${p.year}';
  }
}
