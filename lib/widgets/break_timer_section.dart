import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import 'small_button.dart';

// ---------------------------------------------------------------------------
// Break timer section — shared by lunch and non-work time
// ---------------------------------------------------------------------------

/// A start/stop/edit row for a "break" that counts as not-working time.
///
/// Used for both lunch and non-work time (errands). When [active], shows a
/// live mm:ss timer and a Stop button; otherwise shows the stored minutes plus
/// Start and Edit buttons.
///
/// The label is the flexible element: it ellipsizes on narrow (mobile) screens
/// so the timer and action buttons are never clipped.
class BreakTimerSection extends StatelessWidget {
  final IconData icon;

  /// Already-translated label, e.g. "Lunch" or "Non-work time".
  final String label;

  final int minutes;
  final DateTime? startTime;
  final DateTime? endTime;
  final bool active;
  final VoidCallback onStart;
  final VoidCallback onStop;
  final VoidCallback onEdit;
  final ThemeData theme;

  /// Accent color for the icon/button and the running-state background.
  final Color color;
  final Color onColor;

  const BreakTimerSection({
    super.key,
    required this.icon,
    required this.label,
    required this.minutes,
    required this.startTime,
    required this.endTime,
    required this.active,
    required this.onStart,
    required this.onStop,
    required this.onEdit,
    required this.theme,
    required this.color,
    required this.onColor,
  });

  @override
  Widget build(BuildContext context) {
    if (active) {
      // Timer is running — show elapsed + Stop button.
      final elapsed = DateTime.now().difference(startTime!);
      final mins = elapsed.inMinutes;
      final secs = elapsed.inSeconds % 60;
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            // Flexible label — ellipsizes rather than pushing the timer off
            // screen on narrow layouts.
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.bodyMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                fontFamily: 'monospace',
              ),
            ),
            const SizedBox(width: 8),
            SmallButton(
              onPressed: onStop,
              backgroundColor: color,
              foregroundColor: onColor,
              label: context.t('Stop'),
            ),
          ],
        ),
      );
    }

    // Timer not running — show stored minutes + Start/Edit buttons.
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            context.t('{minutes} min', {'minutes': minutes}),
            style: theme.textTheme.bodyMedium
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          if (endTime != null) ...[
            const SizedBox(width: 4),
            Text(context.t(' (timer)'),
                style: const TextStyle(
                    fontStyle: FontStyle.italic, fontSize: 12)),
          ],
          const SizedBox(width: 8),
          SmallButton(
            onPressed: onStart,
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: theme.colorScheme.onPrimary,
            label: context.t('Start'),
          ),
          const SizedBox(width: 4),
          SmallButton(
            onPressed: onEdit,
            backgroundColor:
                theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            foregroundColor: theme.colorScheme.onSurfaceVariant,
            label: context.t('Edit'),
          ),
        ],
      ),
    );
  }
}
