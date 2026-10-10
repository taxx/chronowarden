import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../models/journey_info.dart';
import '../models/transit_config.dart';
import 'journey_tile.dart';

// ---------------------------------------------------------------------------
// Journey card / occupancy badge / leave-time info (Transit tab)
// ---------------------------------------------------------------------------

class JourneyCard extends StatelessWidget {
  final JourneyInfo journey;
  final TransitConfig cfg;
  final bool isMorning;
  final ThemeData theme;
  final bool isPinned;
  final VoidCallback? onTogglePin;

  const JourneyCard({
    super.key,
    required this.journey,
    required this.cfg,
    required this.isMorning,
    required this.theme,
    this.isPinned = false,
    this.onTogglePin,
  });

  @override
  Widget build(BuildContext context) {
    final depLocal = journey.departureTime.toLocal();
    final depStr =
        '${depLocal.hour.toString().padLeft(2, '0')}:'
        '${depLocal.minute.toString().padLeft(2, '0')}';

    final delayColor = journeyDelayColor(journey);

    // Line badge
    final line = journey.mainLine;
    // Destination
    final dest = journey.mainDestination ?? context.t('Unknown');

    // Occupancy badge
    final occ = journey.occupancy;

    // Platform
    final platform = journey.departurePlatform;

    // Transport mode info is available via legs if needed
    // Transport mode info is available via legs if needed
    final mode = journey.transportMode;
    // ignore: unused_local_variable, no_leading_underscores_for_local_identifiers
    final mode_ = mode;

    final pinnedColor = isPinned
        ? theme.colorScheme.tertiary
        : theme.colorScheme.surfaceContainerHighest;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      color: isPinned ? pinnedColor.withValues(alpha: 0.25) : null,
      shape: isPinned
          ? RoundedRectangleBorder(
              side: BorderSide(color: theme.colorScheme.tertiary, width: 1.5),
              borderRadius: BorderRadius.circular(12),
            )
          : null,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row: departure time + line badge + delay
            Row(
              children: [
                Text(
                  depStr,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (line != null) ...[
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      line,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSecondaryContainer,
                      ),
                    ),
                  ),
                ],
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: delayColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    journey.delayLabel,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: delayColor,
                      fontSize: 11,
                    ),
                  ),
                ),
                const Spacer(),
                PinButton(isPinned: isPinned, onTogglePin: onTogglePin),
              ],
            ),
            const SizedBox(height: 6),
            // Destination + duration + platform
            Row(
              children: [
                Expanded(
                  child: Text(
                    context.t('→ {dest} · {minutes} min',
                        {'dest': dest, 'minutes': journey.durationMinutes}),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                if (platform != null)
                  Text(
                    context.t('Platform {platform}', {'platform': platform}),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
            // Occupancy badge
            if (occ != null) ...[
              const SizedBox(height: 4),
              OccupancyBadge(occupancy: occ, theme: theme),
            ],
            const SizedBox(height: 6),
            LeaveTimeInfo(
              journey: journey,
              cfg: cfg,
              isMorning: isMorning,
              theme: theme,
              isPinned: isPinned,
            ),
          ],
        ),
      ),
    );
  }

}

// ---------------------------------------------------------------------------
// Occupancy badge
// ---------------------------------------------------------------------------

class OccupancyBadge extends StatelessWidget {
  final String occupancy;
  final ThemeData theme;

  const OccupancyBadge({
    super.key,
    required this.occupancy,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final (icon, label, color) = switch (occupancy) {
      'MANY_SEATS' => (
        Icons.chair,
        context.t('Many seats available'),
        Colors.green,
      ),
      'FEW_SEATS' => (
        Icons.chair,
        context.t('Few seats available'),
        Colors.orange.shade700,
      ),
      'STANDING_ONLY' => (
        Icons.directions_bus,
        context.t('Standing room only'),
        Colors.red,
      ),
      _ => (Icons.chair, context.t('Seats available'), Colors.green),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: color,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Leave time info row
// ---------------------------------------------------------------------------

class LeaveTimeInfo extends StatelessWidget {
  final JourneyInfo journey;
  final TransitConfig cfg;
  final bool isMorning;
  final ThemeData theme;
  final bool isPinned;

  const LeaveTimeInfo({
    super.key,
    required this.journey,
    required this.cfg,
    required this.isMorning,
    required this.theme,
    this.isPinned = false,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final walkBuffer = cfg.walkMinutes(isMorning);

    // Arrival time (local) — the "trip" wording shown after leave/departure.
    final arrLocal = journey.arrivalTime.toLocal();
    final arrStr =
        '${arrLocal.hour.toString().padLeft(2, '0')}:'
        '${arrLocal.minute.toString().padLeft(2, '0')}';

    final status = journeyStatus(
      journey: journey,
      now: now,
      walkBuffer: walkBuffer,
      isPinned: isPinned,
      tripLabel: context.t('arrive {time}', {'time': arrStr}),
      theme: theme,
      strings: context.strings,
    );

    // Non-pinned missed journeys are italicized (card-specific styling).
    final italic = !isPinned && !status.catchable;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          status.text,
          style: theme.textTheme.bodySmall?.copyWith(
            color: status.color,
            fontStyle: italic ? FontStyle.italic : null,
          ),
        ),
      ],
    );
  }
}
