import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../models/journey_info.dart';

/// Delay color for a journey's real-time departure delay.
///
/// Shared by the Transit tab card and the My Day transit row.
Color journeyDelayColor(JourneyInfo journey) {
  final diff = journey.departureDelayMinutes;
  if (diff <= 0) return Colors.green;
  if (diff <= 5) return Colors.orange.shade700;
  return Colors.red;
}

/// Computes the status line for a journey row ("Leave at …", "Departs in …",
/// "Missed …") plus its color, given the walking buffer and pin state.
///
/// [tripLabel] is the arrival/trip wording placed after the leave/departure
/// times, e.g. "arrive 08:40" (Transit tab) or "35min trip" (My Day card).
/// Both screens render the same journey logic with slightly different
/// wording, so the computation lives here once.
///
/// Pinned journeys never show "missed": once the leave time has passed they
/// keep counting down to departure, then fall back to a neutral "departed"
/// label (the pin stays visible all day by design).
({String text, Color color, bool catchable}) journeyStatus({
  required JourneyInfo journey,
  required DateTime now,
  required int walkBuffer,
  required bool isPinned,
  required String tripLabel,
  required ThemeData theme,
  required AppStrings strings,
}) {
  final depLocal = journey.departureTime.toLocal();
  final leaveTime = depLocal.subtract(Duration(minutes: walkBuffer));
  final isCatchable =
      leaveTime.isAfter(now) || leaveTime.difference(now).inMinutes.abs() <= 1;

  final minutesUntilLeave =
      now.isBefore(leaveTime) ? leaveTime.difference(now).inMinutes : 0;
  String untilStr;
  if (minutesUntilLeave <= 0) {
    untilStr = '';
  } else {
    untilStr = strings.translate(
      ' · leave in {minutes} min',
      {'minutes': minutesUntilLeave},
    );
  }

  final leaveStr = '${leaveTime.hour.toString().padLeft(2, '0')}:'
      '${leaveTime.minute.toString().padLeft(2, '0')}';

  String text;
  if (isPinned) {
    if (isCatchable) {
      text = strings.translate('Leave at {time} · {trip}{until}',
          {'time': leaveStr, 'trip': tripLabel, 'until': untilStr});
    } else {
      final minutesUntilDeparture =
          now.isBefore(depLocal) ? depLocal.difference(now).inMinutes : 0;
      if (minutesUntilDeparture > 0) {
        final depCountdown =
            minutesUntilDeparture == 1 ? '1 min' : '$minutesUntilDeparture min';
        text = strings.translate('Departs in {countdown} · {trip}',
            {'countdown': depCountdown, 'trip': tripLabel});
      } else {
        text = strings.translate('Committed ride — departed');
      }
    }
  } else if (isCatchable) {
    text = strings.translate('Leave at {time} · {trip}{until}',
        {'time': leaveStr, 'trip': tripLabel, 'until': untilStr});
  } else {
    text = strings.translate('Missed — needed to leave by {time}',
        {'time': leaveStr});
  }

  final color = isPinned || isCatchable
      ? theme.colorScheme.onSurfaceVariant
      : theme.colorScheme.error;
  return (text: text, color: color, catchable: isCatchable);
}

/// Compact pin/commit control shown on every journey card/row.
///
/// [compact] renders the smaller variant used by the My Day transit row.
class PinButton extends StatelessWidget {
  final bool isPinned;
  final VoidCallback? onTogglePin;
  final bool compact;

  const PinButton({
    super.key,
    required this.isPinned,
    this.onTogglePin,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label = isPinned ? context.t('Locked') : context.t('Pin');
    final icon = isPinned ? Icons.lock : Icons.push_pin_outlined;
    final color = isPinned
        ? theme.colorScheme.tertiary
        : theme.colorScheme.primary;

    final radius = compact ? 8.0 : 12.0;
    final iconSize = compact ? 11.0 : 12.0;
    final gap = compact ? 3.0 : 4.0;
    final padH = compact ? 6.0 : 8.0;
    final padV = compact ? 2.0 : 4.0;
    final fontSize = compact ? 10.0 : 11.0;

    return Tooltip(
      message: isPinned ? context.t('Unpin this journey') : context.t('Commit to this journey'),
      child: InkWell(
        onTap: onTogglePin,
        borderRadius: BorderRadius.circular(radius),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: padH, vertical: padV),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(radius),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: iconSize, color: color),
              SizedBox(width: gap),
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: color,
                  fontSize: fontSize,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


class TransitJourneyRow extends StatelessWidget {
  final JourneyInfo journey;
  final DateTime now;
  final int walkBuffer;
  final ThemeData theme;
  final bool isPinned;
  final VoidCallback? onTogglePin;

  const TransitJourneyRow({
    super.key,
    required this.journey,
    required this.now,
    required this.walkBuffer,
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

    final lineBadge = journey.mainLine ?? '';
    final delayColor = journeyDelayColor(journey);

    final pinnedColor = isPinned
        ? theme.colorScheme.tertiary
        : theme.colorScheme.surfaceContainerHighest;

    final status = journeyStatus(
      journey: journey,
      now: now,
      walkBuffer: walkBuffer,
      isPinned: isPinned,
      tripLabel: context.t('{minutes}min trip', {'minutes': journey.durationMinutes}),
      theme: theme,
      strings: context.strings,
    );

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: isPinned
          ? BoxDecoration(
              color: pinnedColor.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: theme.colorScheme.tertiary, width: 1),
            )
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isPinned || status.catchable
                    ? Icons.check_circle
                    : Icons.cancel,
                size: 16,
                color: isPinned || status.catchable
                    ? Colors.green
                    : theme.colorScheme.error,
              ),
              const SizedBox(width: 6),
              Text(
                depStr,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (lineBadge.isNotEmpty) ...[ 
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    lineBadge,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSecondaryContainer,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
              const SizedBox(width: 6),
              Text(journey.delayLabel,
                  style: theme.textTheme.bodySmall?.copyWith(
                color: delayColor,
                fontSize: 10,
              )),
              const Spacer(),
              PinButton(isPinned: isPinned, onTogglePin: onTogglePin, compact: true),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            status.text,
            style: theme.textTheme.bodySmall?.copyWith(
              color: status.color,
            ),
          ),
        ],
      ),
    );
  }

}
