import { useEffect, useState } from 'react';

import { JourneyRow, PinnedJourneyRow } from '../components/journey-row';
import { StationPicker } from '../components/StationPicker';
import { ListSkeleton, SkeletonRows } from '../components/skeletons';
import {
  Button,
  Card,
  CardContent,
  CardHeader,
  EmptyState,
  Field,
  Input,
  Switch,
} from '../components/ui';
import { useNow } from '../hooks/useNow';
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
import type { JourneyInfo, StationInfo } from '../lib/domain/transit';
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
import { useTodayLog } from '../queries/time-logs';
import { useToastStore } from '../state/toast';

function asStation(id: string, name: string): StationInfo | null {
  return id && name ? { id, name, siteId: null } : null;
}

export function TransitPage() {
  const t = useT();
  const now = useNow(5000);

  const configQuery = useTransitConfig();
  const save = useSaveTransitConfig();
  const today = useTodayLog().data ?? null;
  const pushToast = useToastStore((state) => state.push);

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

  // An active day always heads home, regardless of the clock.
  const morning = isMorningCommute(now, today);
  const canFetch = draft.enabled && hasHome(draft) && hasWork(draft);
  const walkBuffer = walkMinutes(draft, morning);

  const journeysQuery = useJourneys({
    originId: originStopId(draft, morning),
    destId: destStopId(draft, morning),
    walkOffsetMinutes: walkBuffer,
    enabled: canFetch,
  });

  if (configQuery.isLoading || !initialised) {
    return (
      <div className="space-y-4">
        <ListSkeleton rows={4} />
      </div>
    );
  }

  const availability = transitAvailability(now.getTime());
  const journeys = journeysQuery.data ?? [];

  const routeOrigin = originStopId(draft, morning);
  const routeDest = destStopId(draft, morning);
  const pinForRoute = pinned && pinBelongsToRoute(pinned, routeOrigin, routeDest) ? pinned : null;
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

  async function saveConfig() {
    const previous = configQuery.data;
    if (
      previous &&
      (previous.homeStopId !== draft.homeStopId || previous.workStopId !== draft.workStopId)
    ) {
      // The route changed, so the pin no longer applies.
      unpin();
    }
    try {
      await save.mutateAsync(draft);
      pushToast(t('Saved'), 'success');
    } catch {
      pushToast(t('Could not save'), 'error');
    }
  }

  return (
    <div className="space-y-4">
      <Card>
        <CardHeader
          title={t('Transit')}
          description={t('Journey planning between home and work stations.')}
        />
        <CardContent className="space-y-4">
          <label className="flex items-center justify-between gap-4 text-sm">
            <span>{t('Enable transit')}</span>
            <Switch
              checked={draft.enabled}
              onCheckedChange={(enabled) => setDraft({ ...draft, enabled })}
            />
          </label>

          <div className="grid gap-4 sm:grid-cols-2">
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
                onChange={(event) =>
                  setDraft({ ...draft, walkHomeMinutes: Math.max(0, Number(event.target.value) || 0) })
                }
              />
            </Field>
            <Field label={t('Walk to work (min)')} htmlFor="walkWork">
              <Input
                id="walkWork"
                type="number"
                inputMode="numeric"
                value={String(draft.walkWorkMinutes)}
                onChange={(event) =>
                  setDraft({ ...draft, walkWorkMinutes: Math.max(0, Number(event.target.value) || 0) })
                }
              />
            </Field>
          </div>

          {!canFetch ? (
            <p className="text-xs text-muted-foreground">{t('Both work and home stations must be set.')}</p>
          ) : null}

          <div>
            <Button onClick={() => void saveConfig()} disabled={save.isPending}>
              {t('Save')}
            </Button>
          </div>
        </CardContent>
      </Card>

      {canFetch ? (
        <Card>
          <CardHeader
            title={directionLabel(draft, morning)}
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
            ) : journeysQuery.isLoading ? (
              <SkeletonRows rows={3} />
            ) : journeys.length === 0 && !pinForRoute ? (
              <EmptyState title={t('No journeys found')} />
            ) : (
              <ul className="divide-y divide-border">
                {pinForRoute ? (
                  <PinnedJourneyRow
                    pin={pinForRoute}
                    live={livePinned}
                    now={now}
                    walkBuffer={walkBuffer}
                    variant="transit"
                    onUnpin={unpin}
                  />
                ) : null}
                {journeys.map((journey) => (
                  <JourneyRow
                    key={journey.departureTime.toISOString()}
                    journey={journey}
                    now={now}
                    walkBuffer={walkBuffer}
                    variant="transit"
                    onPin={() => pin(journey)}
                  />
                ))}
              </ul>
            )}
          </CardContent>
        </Card>
      ) : null}
    </div>
  );
}
