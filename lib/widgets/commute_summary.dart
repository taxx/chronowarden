import 'package:flutter/material.dart';

/// "Commute breakdown" panel shown inside the start-day / add-day dialogs.
///
/// Renders nothing when every commute value is zero (e.g. working from home).
/// Values are passed in explicitly so the same widget serves the My Day,
/// Overview and History dialogs.
class CommuteSummary extends StatelessWidget {
  final int morningOverhead;
  final int morningProductive;
  final int eveningOverhead;
  final int eveningProductive;

  const CommuteSummary({
    super.key,
    required this.morningOverhead,
    required this.morningProductive,
    required this.eveningOverhead,
    required this.eveningProductive,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totalCommute = morningOverhead +
        morningProductive +
        eveningOverhead +
        eveningProductive;
    if (totalCommute == 0) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Commute breakdown',
            style: theme.textTheme.labelSmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 4),
          Text(
            'Morning: $morningOverhead min walk, '
            '$morningProductive min train work',
            style: theme.textTheme.bodySmall,
          ),
          Text(
            'Evening: $eveningOverhead min walk, '
            '$eveningProductive min train work',
            style: theme.textTheme.bodySmall,
          ),
          Text(
            'Total: $totalCommute min commute',
            style: theme.textTheme.bodySmall
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
