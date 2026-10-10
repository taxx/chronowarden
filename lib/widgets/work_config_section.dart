import 'package:flutter/material.dart';

import '../app_state.dart';
import '../l10n/app_strings.dart';
import '../utils/format.dart';
import 'stat_row.dart';

/// Work-time configuration summary card.
class WorkConfigSection extends StatelessWidget {
  final VoidCallback onEdit;

  const WorkConfigSection({
    super.key,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final state = AppState();
    final theme = Theme.of(context);
    final cfg = state.workConfig;
    final dflt = cfg?.defaultExpectedMinutes ?? 480;
    final hasReduced = cfg?.hasReducedPeriod ?? false;
    final reducedMinutes = cfg?.reducedExpectedMinutes;
    final reducedStartWeek = cfg?.reducedStartWeek;
    final reducedEndWeek = cfg?.reducedEndWeek;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.work_outlined, color: theme.colorScheme.primary),
                const SizedBox(width: 12),
                Expanded(child: Text(context.t('Work Hours'), style: theme.textTheme.titleLarge)),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              context.t('Configure your expected work time per day.'),
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            StatRow(
              label: context.t('Default'),
              value: context.t('{time} per day', {'time': formatMins(dflt)}),
            ),
            if (hasReduced) ...[
              StatRow(
                label: context.t('Reduced period'),
                value: context.t('{time} per day', {'time': formatMins(reducedMinutes!)}),
              ),
              StatRow(
                label: context.t('ISO weeks'),
                value: '$reducedStartWeek – $reducedEndWeek',
              ),
            ] else ...[
              StatRow(label: context.t('Reduced period'), value: context.t('Not configured')),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onEdit,
                icon: const Icon(Icons.edit, size: 18),
                label: Text(context.t('Edit configuration')),
              ),
            ),
          ],
        ),
      ),
    );
  }


}


// ---------------------------------------------------------------------------
// Reusable section widget
// ---------------------------------------------------------------------------

