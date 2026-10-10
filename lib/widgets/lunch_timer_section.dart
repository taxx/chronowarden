import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import 'small_button.dart';

// ---------------------------------------------------------------------------
// Lunch timer section — Start/Stop buttons plus elapsed display
// ---------------------------------------------------------------------------

/// Lunch timer section — Start/Stop buttons plus elapsed display.
class LunchTimerSection extends StatelessWidget {
  final int lunchMinutes;
  final DateTime? lunchStartTime;
  final DateTime? lunchEndTime;
  final bool lunchActive;
  final VoidCallback onStartLunch;
  final VoidCallback onStopLunch;
  final VoidCallback onEditLunch;
  final ThemeData theme;

  const LunchTimerSection({
    super.key,
    required this.lunchMinutes,
    required this.lunchStartTime,
    required this.lunchEndTime,
    required this.lunchActive,
    required this.onStartLunch,
    required this.onStopLunch,
    required this.onEditLunch,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    if (lunchActive) {
      // Timer is running — show elapsed + Stop button
      final elapsed = DateTime.now().difference(lunchStartTime!);
      final mins = elapsed.inMinutes;
      final secs = elapsed.inSeconds % 60;
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          color: theme.colorScheme.tertiaryContainer.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(Icons.restaurant, size: 16, color: theme.colorScheme.tertiary),
            const SizedBox(width: 4),
            Text(context.t('Lunch'), style: theme.textTheme.bodyMedium),
            Text(
              '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                fontFamily: 'monospace',
              ),
            ),
            const Spacer(),
            SmallButton(
              onPressed: onStopLunch,
              backgroundColor: theme.colorScheme.tertiary,
              foregroundColor: theme.colorScheme.onTertiary,
              label: context.t('Stop'),
            ),
          ],
        ),
      );
    }

    // Timer not running — show stored lunch minutes + Start button
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(Icons.restaurant, size: 16, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(context.t('Lunch: {minutes} min', {'minutes': lunchMinutes}), style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
          if (lunchEndTime != null)
            Text(context.t(' (timer)'), style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 12)),
          const Spacer(),
          SmallButton(
            onPressed: onStartLunch,
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: theme.colorScheme.onPrimary,
            label: context.t('Start'),
          ),
          const SizedBox(width: 4),
          SmallButton(
            onPressed: onEditLunch,
            backgroundColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            foregroundColor: theme.colorScheme.onSurfaceVariant,
            label: context.t('Edit'),
          ),
        ],
      ),
    );
  }
}

