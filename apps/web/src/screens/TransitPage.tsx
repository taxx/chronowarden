import { useEffect, useState } from 'react';

import { StationPicker } from '../components/StationPicker';
import { Badge, Button, Card, Field, Input, Spinner } from '../components/ui';
import { useNow } from '../hooks/useNow';
import { useT } from '../i18n';
import { formatClock, toDateStr } from '../lib/date';
import {
  journeyMatchesPin,
  pinBelongsToRoute,
  pinFromJourney,
  pinIsExpired,
  type PinnedJourney,
} from '../lib/domain/pinned-journey';
import type { JourneyInfo, StationInfo } from '../lib/domain/transit';
import {
  departureDelayMinutes,
  journeyDeparturePlatform,
  journeyMainDestination,
  journeyMainLine,
  journeyOccupancy,
  journeyTransferCount,
} from '../lib/domain/transit';
import {
  defaultTransitConfig,
  destStopId,
  directionLabel,
  hasHome,
  hasWork,
  originStopId,
  walkMinutes,
  type TransitConfig,
} from '../lib/domain/transit-config';
import {
  transitAvailability,
  transitBackoffRemainingMs,
  transitLastError,
  transitRetryNow,
} from '../services/transit';
import {
  clearPinnedJourney,
  loadPinnedJourney,
  savePinnedJourney,
} from '../services/pinned-journey-store';
import { useJourneys, useSaveTransitConfig, useTransitConfig } from '../queries/transit';

function asStation(id: string, name: string): StationInfo | null {
  return id && name ? { id, name, siteId: null } : null;
}

export function TransitPage() {
  const t = useT();
  const now = useNow(5000);

  const configQuery = useTransitConfig();
  const save = useSaveTransitConfig();

  const [draft, setDraft] = useState<TransitConfig>(defaultTransitConfig);
  const [initialised, setInitialised] = useState(false);
  const [pinned, setPinned] = useState<PinnedJourney | null>(() => loadPinnedJourney());

  useEffect(() => {
    if (configQuery.data && !initialised) {
      setDraft(configQuery.data);
      setInitialised(true);
    }
  }, [configQuery.data, initialised]);

  // A pin only lives for the day it was made.
  useEffect(() => {
    if (pinned && pinIsExpired(pinned, toDateStr(new Date()))) {
      clearPinnedJourney();
      setPinned(null);
    }
  }, [pinned]);

  const morning = now.getHours() < 11;
  const canFetch = draft.enabled && hasHome(draft) && hasWork(draft);

  const journeysQuery = useJourneys({
    originId: originStopId(draft, morning),
    destId: destStopId(draft, morning),
    walkOffsetMinutes: walkMinutes(draft, morning),
    enabled: canFetch,
  });

  if (configQuery.isLoading || !initialised) {
    return (
      <Card>
        <div className="flex justify-center py-8">
          <Spinner />
        </div>
      </Card>
    );
  }

  const availability = transitAvailability(now.getTime());
  const journeys = journeysQuery.data ?? [];

  const routeOrigin = originStopId(draft, morning);
  const routeDest = destStopId(draft, morning);
  const pinForRoute =
    pinned && pinBelongsToRoute(pinned, routeOrigin, routeDest) ? pinned : null;
  const livePinned = pinForRoute
    ? (journeys.find((journey) => journeyMatchesPin(journey, pinForRoute)) ?? null)
    : null;

  function pin(journey: JourneyInfo) {
    const next = pinFromJourney(journey, routeOrigin, routeDest, toDateStr(new Date()));
    savePinnedJourney(next);
    setPinned(next);
  }

  function unpin() {
    clearPinnedJourney();
    setPinned(null);
  }

  function refresh() {
    transitRetryNow();
    void journeysQuery.refetch();
  }

  return (
    <div className="space-y-4">
      <Card>
        <h1 className="text-xl font-semibold text-foreground">{t('Transit')}</h1>

        <label className="mt-4 flex items-center gap-2 text-sm text-foreground">
          <input
            type="checkbox"
            checked={draft.enabled}
            onChange={(event) => setDraft({ ...draft, enabled: event.target.checked })}
          />
          {t('Enable transit')}
        </label>

        <div className="mt-4 grid gap-4 sm:grid-cols-2">
          <StationPicker
            label={t('Home station')}
            selected={asStation(draft.homeStopId, draft.homeStopName)}
            onSelect={(station) =>
              setDraft({ ...draft, homeStopId: station.id, homeStopName: station.name })
            }
          />
          <StationPicker
            label={t('Work station')}
            selected={asStation(draft.workStopId, draft.workStopName)}
            onSelect={(station) =>
              setDraft({ ...draft, workStopId: station.id, workStopName: station.name })
            }
          />
          <Field label={t('Walk from home (min)')} htmlFor="walkHome">
            <Input
              id="walkHome"
              type="number"
              inputMode="numeric"
              value={String(draft.walkHomeMinutes)}
              onChange={(event) => setDraft({ ...draft, walkHomeMinutes: Number(event.target.value) || 0 })}
            />
          </Field>
          <Field label={t('Walk to work (min)')} htmlFor="walkWork">
            <Input
              id="walkWork"
              type="number"
              inputMode="numeric"
              value={String(draft.walkWorkMinutes)}
              onChange={(event) => setDraft({ ...draft, walkWorkMinutes: Number(event.target.value) || 0 })}
            />
          </Field>
        </div>

        <Button
          className="mt-4"
          disabled={save.isPending}
          onClick={() => {
            const previous = configQuery.data;
            if (
              previous &&
              (previous.homeStopId !== draft.homeStopId ||
                previous.workStopId !== draft.workStopId)
            ) {
              // The route changed, so the pin no longer applies.
              unpin();
            }
            void save.mutateAsync(draft);
          }}
        >
          {t('Save')}
        </Button>
      </Card>

      {canFetch ? (
        <Card>
          <div className="flex items-center justify-between gap-4">
            <h2 className="text-sm font-medium text-foreground">{directionLabel(draft, morning)}</h2>
            <Button variant="ghost" onClick={refresh}>
              {t('Refresh')}
            </Button>
          </div>

          {availability === 'unavailable' ? (
            <div className="mt-4 rounded-lg border border-warning/40 bg-warning/10 p-3">
              <p className="text-sm text-warning">{t('Transit unavailable')}</p>
              {transitLastError() ? (
                <p className="mt-1 text-xs text-warning/70">{transitLastError()}</p>
              ) : null}
              <Button className="mt-3" variant="ghost" onClick={refresh}>
                {t('Try again')}
              </Button>
            </div>
          ) : availability === 'backingOff' ? (
            <p className="mt-4 text-sm text-amber-300">
              {t('Retrying in {seconds}s', {
                seconds: Math.ceil(transitBackoffRemainingMs(now.getTime()) / 1000),
              })}
            </p>
          ) : journeysQuery.isLoading ? (
            <div className="flex justify-center py-6">
              <Spinner />
            </div>
          ) : journeys.length === 0 && !pinForRoute ? (
            <p className="mt-4 text-sm text-muted-foreground">{t('No journeys found')}</p>
          ) : (
            <ul className="mt-4 divide-y divide-border">
              {pinForRoute ? (
                <PinnedRow pin={pinForRoute} live={livePinned} now={now} onUnpin={unpin} />
              ) : null}
              {journeys.map((journey) => (
                <JourneyRow
                  key={journey.departureTime.toISOString()}
                  journey={journey}
                  now={now}
                  onPin={() => pin(journey)}
                />
              ))}
            </ul>
          )}
        </Card>
      ) : null}
    </div>
  );
}

function occupancyLabel(t: ReturnType<typeof useT>, occupancy: string | null): string | null {
  if (!occupancy) return null;
  const value = occupancy.toLowerCase();
  if (value.includes('standing') || value === 'high') return t('Standing room only');
  if (value.includes('few') || value === 'medium') return t('Few seats available');
  if (value.includes('many') || value === 'low') return t('Many seats available');
  return t('Seats available');
}

function JourneyRow({
  journey,
  now,
  onPin,
  pinned = false,
  onUnpin,
}: {
  journey: JourneyInfo;
  now: Date;
  onPin?: () => void;
  pinned?: boolean;
  onUnpin?: () => void;
}) {
  const t = useT();
  const line = journeyMainLine(journey);
  const platform = journeyDeparturePlatform(journey);
  const delay = departureDelayMinutes(journey);
  const occupancy = occupancyLabel(t, journeyOccupancy(journey));
  const transfers = journeyTransferCount(journey);
  const departsIn = Math.round((journey.departureEstimated.getTime() - now.getTime()) / 60_000);

  return (
    <li
      className={
        'flex flex-wrap items-start justify-between gap-3 py-3' +
        (pinned ? ' rounded-lg bg-accent/50 px-3' : '')
      }
    >
      <div className="min-w-0">
        <p className="flex items-center gap-2 font-medium">
          <span className="font-mono">{formatClock(journey.departureTime)}</span>
          <span className="text-muted-foreground">→</span>
          <span className="font-mono">{formatClock(journey.arrivalTime)}</span>
          {pinned ? <Badge variant="default">{t('Pinned')}</Badge> : null}
        </p>
        <p className="mt-1 text-xs text-muted-foreground">
          {line ? `${line} · ` : ''}
          {journeyMainDestination(journey) ?? ''}
          {platform ? ` · ${t('Platform')} ${platform}` : ''}
        </p>
        <div className="mt-2 flex flex-wrap gap-1.5">
          {occupancy ? <Badge variant="secondary">{occupancy}</Badge> : null}
          {transfers > 0 ? (
            <Badge variant="outline">
              {transfers === 1 ? t('1 change') : t('{count} changes', { count: transfers })}
            </Badge>
          ) : null}
          {departsIn >= -2 ? (
            <Badge variant="outline">{t('in {minutes} min', { minutes: Math.max(0, departsIn) })}</Badge>
          ) : (
            <Badge variant="warning">{t('Departed')}</Badge>
          )}
        </div>
      </div>
      <div className="flex items-center gap-3 text-sm">
        <div className="text-right">
          <p>{t('{minutes}min trip', { minutes: journey.durationMinutes })}</p>
          <p className={delay > 0 ? 'text-xs text-warning' : 'text-xs text-success'}>
            {delay > 0 ? `+${delay} min` : t('On time')}
          </p>
        </div>
        {pinned ? (
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

/** The committed journey: live data when available, otherwise a synthetic card. */
function PinnedRow({
  pin,
  live,
  now,
  onUnpin,
}: {
  pin: PinnedJourney;
  live: JourneyInfo | null;
  now: Date;
  onUnpin: () => void;
}) {
  const t = useT();
  if (live) return <JourneyRow journey={live} now={now} pinned onUnpin={onUnpin} />;

  return (
    <li className="flex flex-wrap items-center justify-between gap-3 rounded-lg bg-accent/50 px-3 py-3">
      <div>
        <p className="flex items-center gap-2 font-medium">
          <span className="font-mono">{pin.timeOfDay}</span>
          <Badge variant="default">{t('Pinned')}</Badge>
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
