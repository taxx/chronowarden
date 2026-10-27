import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../services/transit_fetch_guard.dart';

/// Card shown when transit data cannot be loaded, either because the service
/// is backing off after a failure or because it has given up.
///
/// Used by both the "My Day" transit card and the Transit tab so the message
/// and the manual-retry affordance are consistent.
class TransitUnavailableCard extends StatelessWidget {
  /// Current availability, from `TransitService.availability`.
  final TransitAvailability availability;

  /// Time left before the next automatic attempt (only for [backingOff]).
  final Duration? remaining;

  /// Called when the user presses "Try again". The caller should reset the
  /// back-off (`TransitService.retryNow()`) and trigger a fresh fetch.
  final VoidCallback onRetry;

  const TransitUnavailableCard({
    super.key,
    required this.availability,
    this.remaining,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final backingOff = availability == TransitAvailability.backingOff;
    final seconds = (remaining?.inSeconds ?? 0).clamp(0, 24 * 3600);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.cloud_off, color: theme.colorScheme.error),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    context.t('Transit info unavailable'),
                    style: theme.textTheme.titleSmall,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              backingOff
                  ? context.t('Retrying in about {seconds}s.',
                      {'seconds': seconds})
                  : context.t(
                      'The transit service is unavailable right now. Try again in a while.'),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh, size: 18),
                label: Text(context.t('Try again')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
