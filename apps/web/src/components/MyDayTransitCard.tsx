import { useEffect, useState } from 'react';

import { useT } from '../i18n';
import { toDateStr } from '../lib/date';
import { isMorningCommute } from '../lib/domain/journey-status';
import {
  journeyMatchesPin,
  pinBelongsToRoute,
  pinFromJourney,
  pinIsExpired,
  type PinnedJourney,
} from '../lib/domain/pinned-journey';
import type { TimeLog } from '../lib/domain/time-log';
import { commuteUsesTransit, type TravelPreset } from '../lib/domain/travel-preset';
import { shouldShowTransitPlanning, type JourneyInfo } from '../lib/domain/transit';
import {
  destStopId,
  directionLabel,
  hasHome,
  hasWork,
  originStopId,
  walkMinutes,
  type TransitConfig,
} from '../lib/domain/transit-config';
import {
  clearPinnedJourney,
  loadPinnedJourney,
  savePinnedJourney,
} from '../services/pinned-journey-store';
import {
  transitAvailability,
  transitBackoffRemainingMs,
  transitLastError,
  transitRetryNow,
} from '../services/transit';
import { useJourneys } from '../queries/transit';
import { JourneyRow, PinnedJourneyRow } from './journey-row';
import { Button, Card, CardContent, CardHeader } from './ui';

/**
 * The commute card shown on My Day.
 *
 * Direction: an active day always heads home; before 11:00 without a day it
 * plans the trip to work, after 11:00 the trip home. It is hidden when the
 * day's commute does not use transit (e.g. working from home or driving), when
 * the day has ended, or on weekends unless the user works them.
 */
export function MyDayTransitCard({
  now,
  log,
  presets,
  config,
  showWeekends,
  lastPresetId,
}: {
  now: Date;
  log: TimeLog | null;
  presets: TravelPreset[];
  config: TransitConfig;
  showWeekends: boolean;
  lastPresetId: string;
}) {
  const t = useT();
  const [pinned, setPinned] = useState<PinnedJourney | null>(() => loadPinnedJourney());

  useEffect(() => {
    if (pinned && pinIsExpired(pinned, toDateStr(new Date()))) {
      clearPinnedJourney();
      setPinned(null);
    }
  }, [pinned]);

  const dayEnded = log != null && log.endTime != null;
  const active = log != null && log.endTime == null;
  const configured = config.enabled && hasHome(config) && hasWork(config);
  const usesTransit = commuteUsesTransit(presets, log, lastPresetId);
  const planning = !active && shouldShowTransitPlanning(now, showWeekends);
  const visible = configured && !dayEnded && (active || planning) && usesTransit;

  const morning = isMorningCommute(now, log);
  const walkBuffer = walkMinutes(config, morning);

  const query = useJourneys({
    originId: originStopId(config, morning),
    destId: destStopId(config, morning),
    walkOffsetMinutes: walkBuffer,
    enabled: visible,
  });

  if (!visible) return null;

  const journeys = query.data ?? [];
  const origin = originStopId(config, morning);
  const dest = destStopId(config, morning);
  const pinForRoute = pinned && pinBelongsToRoute(pinned, origin, dest) ? pinned : null;
  const livePinned = pinForRoute
    ? (journeys.find((journey) => journeyMatchesPin(journey, pinForRoute)) ?? null)
    : null;
  const availability = transitAvailability(now.getTime());

  // Nothing relevant to show yet.
  if (journeys.length === 0 && !pinForRoute && availability === 'ok' && !query.isLoading) return null;

  function pin(journey: JourneyInfo) {
    const next = pinFromJourney(journey, origin, dest, toDateStr(new Date()));
    savePinnedJourney(next);
    setPinned(next);
  }

  function unpin() {
    clearPinnedJourney();
    setPinned(null);
  }

  function refresh() {
    transitRetryNow();
    void query.refetch();
  }

  return (
    <Card>
      <CardHeader
        title={t('Transit — {direction}', { direction: directionLabel(config, morning) })}
        action={
          <Button variant="outline" size="sm" onClick={refresh}>
            {t('Refresh')}
          </Button>
        }
      />
      <CardContent>
        {availability === 'unavailable' ? (
          <div className="rounded-lg border border-warning/40 bg-warning/10 p-3">
            <p className="text-sm text-warning">{t('Transit unavailable')}</p>
            {transitLastError() ? (
              <p className="mt-1 text-xs text-warning/70">{transitLastError()}</p>
            ) : null}
            <Button className="mt-3" variant="outline" size="sm" onClick={refresh}>
              {t('Try again')}
            </Button>
          </div>
        ) : availability === 'backingOff' ? (
          <p className="text-sm text-warning">
            {t('Retrying in {seconds}s', {
              seconds: Math.ceil(transitBackoffRemainingMs(now.getTime()) / 1000),
            })}
          </p>
        ) : (
          <ul className="divide-y divide-border">
            {pinForRoute ? (
              <PinnedJourneyRow
                pin={pinForRoute}
                live={livePinned}
                now={now}
                walkBuffer={walkBuffer}
                variant="myday"
                onUnpin={unpin}
              />
            ) : null}
            {journeys.map((journey) => (
              <JourneyRow
                key={journey.departureTime.toISOString()}
                journey={journey}
                now={now}
                walkBuffer={walkBuffer}
                variant="myday"
                compact
                onPin={() => pin(journey)}
              />
            ))}
          </ul>
        )}
      </CardContent>
    </Card>
  );
}
