import { useT } from '../i18n';
import { formatClock } from '../lib/date';
import { computeJourneyStatus } from '../lib/domain/journey-status';
import type { PinnedJourney } from '../lib/domain/pinned-journey';
import {
  departureDelayMinutes,
  journeyDeparturePlatform,
  journeyMainDestination,
  journeyMainLine,
  journeyOccupancy,
  journeyTransferCount,
  type JourneyInfo,
} from '../lib/domain/transit';
import { Badge, Button } from './ui';

/** Translate an SL occupancy code into a human label. */
export function occupancyLabel(t: ReturnType<typeof useT>, occupancy: string | null): string | null {
  if (!occupancy) return null;
  const value = occupancy.toLowerCase();
  if (value.includes('standing') || value === 'high') return t('Standing room only');
  if (value.includes('few') || value === 'medium') return t('Few seats available');
  if (value.includes('many') || value === 'low') return t('Many seats available');
  return t('Seats available');
}

/**
 * The "leave at… / missed…" line that accounts for the walking time to the
 * station. Shared by the Transit tab and the My Day commute card.
 */
export function JourneyStatusLine({
  journey,
  now,
  walkBuffer,
  pinned,
  variant,
}: {
  journey: JourneyInfo;
  now: Date;
  walkBuffer: number;
  pinned: boolean;
  variant: 'transit' | 'myday';
}) {
  const t = useT();
  const status = computeJourneyStatus(journey, now, walkBuffer, pinned);
  const tripLabel =
    variant === 'myday'
      ? t('{minutes}min trip', { minutes: journey.durationMinutes })
      : t('arrive {time}', { time: formatClock(journey.arrivalTime) });

  let text: string;
  switch (status.kind) {
    case 'leave': {
      const until =
        status.minutesUntilLeave > 0
          ? t(' · leave in {minutes} min', { minutes: status.minutesUntilLeave })
          : '';
      text = t('Leave at {time} · {trip}{until}', {
        time: formatClock(status.leaveTime),
        trip: tripLabel,
        until,
      });
      break;
    }
    case 'departs':
      text = t('Departs in {countdown} · {trip}', {
        countdown: `${status.minutesUntilDeparture} min`,
        trip: tripLabel,
      });
      break;
    case 'departed':
      text = t('Committed ride — departed');
      break;
    default:
      text = t('Missed — needed to leave by {time}', { time: formatClock(status.leaveTime) });
  }

  const tone = status.kind === 'missed' ? 'text-destructive' : 'text-muted-foreground';
  return <p className={'text-xs ' + tone}>{text}</p>;
}

/** A single journey row. `compact` is used by the My Day commute card. */
export function JourneyRow({
  journey,
  now,
  walkBuffer,
  pinned = false,
  variant = 'transit',
  compact = false,
  onPin,
  onUnpin,
}: {
  journey: JourneyInfo;
  now: Date;
  walkBuffer: number;
  pinned?: boolean;
  variant?: 'transit' | 'myday';
  compact?: boolean;
  onPin?: () => void;
  onUnpin?: () => void;
}) {
  const t = useT();
  const line = journeyMainLine(journey);
  const platform = journeyDeparturePlatform(journey);
  const delay = departureDelayMinutes(journey);
  const occupancy = occupancyLabel(t, journeyOccupancy(journey));
  const transfers = journeyTransferCount(journey);

  return (
    <li
      className={
        'flex flex-wrap items-start justify-between gap-3 py-3 first:pt-0 last:pb-0' +
        (pinned ? ' rounded-lg bg-accent/50 px-3' : '')
      }
    >
      <div className="min-w-0">
        <p className="flex items-center gap-2 font-medium">
          <span className="font-mono">{formatClock(journey.departureTime)}</span>
          {!compact ? (
            <>
              <span className="text-muted-foreground">→</span>
              <span className="font-mono">{formatClock(journey.arrivalTime)}</span>
            </>
          ) : null}
          {pinned ? <Badge>{t('Pinned')}</Badge> : null}
        </p>
        <p className="mt-1 text-xs text-muted-foreground">
          {line ? `${line} · ` : ''}
          {journeyMainDestination(journey) ?? ''}
          {!compact && platform ? ` · ${t('Platform')} ${platform}` : ''}
        </p>
        <JourneyStatusLine
          journey={journey}
          now={now}
          walkBuffer={walkBuffer}
          pinned={pinned}
          variant={variant}
        />
        {!compact && (occupancy || transfers > 0) ? (
          <div className="mt-2 flex flex-wrap gap-1.5">
            {occupancy ? <Badge variant="secondary">{occupancy}</Badge> : null}
            {transfers > 0 ? (
              <Badge variant="outline">
                {transfers === 1 ? t('1 change') : t('{count} changes', { count: transfers })}
              </Badge>
            ) : null}
          </div>
        ) : null}
      </div>
      <div className="flex items-center gap-3 text-sm">
        <div className="text-right">
          <p>{t('{minutes}min trip', { minutes: journey.durationMinutes })}</p>
          <p className={delay > 0 ? 'text-xs text-warning' : 'text-xs text-success'}>
            {delay > 0 ? `+${delay} min` : t('On time')}
          </p>
        </div>
        {pinned && onUnpin ? (
          <Button variant="ghost" size="sm" onClick={onUnpin}>
            {t('Unpin')}
          </Button>
        ) : onPin ? (
          <Button variant="outline" size="sm" onClick={onPin}>
            {t('Pin')}
          </Button>
        ) : null}
      </div>
    </li>
  );
}

/** The committed journey: live data when present, otherwise a synthetic card. */
export function PinnedJourneyRow({
  pin,
  live,
  now,
  walkBuffer,
  variant,
  onUnpin,
}: {
  pin: PinnedJourney;
  live: JourneyInfo | null;
  now: Date;
  walkBuffer: number;
  variant: 'transit' | 'myday';
  onUnpin: () => void;
}) {
  const t = useT();
  if (live) {
    return (
      <JourneyRow
        journey={live}
        now={now}
        walkBuffer={walkBuffer}
        variant={variant}
        pinned
        onUnpin={onUnpin}
      />
    );
  }

  return (
    <li className="flex flex-wrap items-center justify-between gap-3 rounded-lg bg-accent/50 px-3 py-3">
      <div>
        <p className="flex items-center gap-2 font-medium">
          <span className="font-mono">{pin.timeOfDay}</span>
          <Badge>{t('Pinned')}</Badge>
        </p>
        <p className="mt-1 text-xs text-muted-foreground">
          {pin.line ? `${pin.line} · ` : ''}
          {pin.destination ?? ''}
        </p>
      </div>
      <div className="flex items-center gap-3 text-sm">
        {pin.durationMinutes ? (
          <span>{t('{minutes}min trip', { minutes: pin.durationMinutes })}</span>
        ) : null}
        <Button variant="outline" size="sm" onClick={onUnpin}>
          {t('Unpin')}
        </Button>
      </div>
    </li>
  );
}
