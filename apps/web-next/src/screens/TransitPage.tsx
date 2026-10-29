import { useEffect, useState } from 'react';

import { StationPicker } from '../components/StationPicker';
import { Button, Card, Field, Input, Spinner } from '../components/ui';
import { useNow } from '../hooks/useNow';
import { useT } from '../i18n';
import { formatClock } from '../lib/date';
import type { JourneyInfo, StationInfo } from '../lib/domain/transit';
import {
  departureDelayMinutes,
  journeyDeparturePlatform,
  journeyMainDestination,
  journeyMainLine,
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

  useEffect(() => {
    if (configQuery.data && !initialised) {
      setDraft(configQuery.data);
      setInitialised(true);
    }
  }, [configQuery.data, initialised]);

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

  function refresh() {
    transitRetryNow();
    void journeysQuery.refetch();
  }

  return (
    <div className="space-y-4">
      <Card>
        <h1 className="text-xl font-semibold text-white">{t('Transit')}</h1>

        <label className="mt-4 flex items-center gap-2 text-sm text-slate-300">
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

        <Button className="mt-4" onClick={() => void save.mutateAsync(draft)} disabled={save.isPending}>
          {t('Save')}
        </Button>
      </Card>

      {canFetch ? (
        <Card>
          <div className="flex items-center justify-between gap-4">
            <h2 className="text-sm font-medium text-slate-300">{directionLabel(draft, morning)}</h2>
            <Button variant="ghost" onClick={refresh}>
              {t('Refresh')}
            </Button>
          </div>

          {availability === 'unavailable' ? (
            <div className="mt-4 rounded-lg border border-amber-800 bg-amber-950/40 p-3">
              <p className="text-sm text-amber-200">{t('Transit unavailable')}</p>
              {transitLastError() ? (
                <p className="mt-1 text-xs text-amber-300/70">{transitLastError()}</p>
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
          ) : journeys.length === 0 ? (
            <p className="mt-4 text-sm text-slate-400">{t('No journeys found')}</p>
          ) : (
            <ul className="mt-4 divide-y divide-slate-800">
              {journeys.map((journey) => (
                <JourneyRow key={journey.departureTime.toISOString()} journey={journey} />
              ))}
            </ul>
          )}
        </Card>
      ) : null}
    </div>
  );
}

function JourneyRow({ journey }: { journey: JourneyInfo }) {
  const t = useT();
  const line = journeyMainLine(journey);
  const platform = journeyDeparturePlatform(journey);
  const delay = departureDelayMinutes(journey);

  return (
    <li className="flex flex-wrap items-center justify-between gap-3 py-3">
      <div>
        <p className="font-medium text-white">
          {formatClock(journey.departureTime)} → {formatClock(journey.arrivalTime)}
        </p>
        <p className="text-xs text-slate-400">
          {line ? `${line} · ` : ''}
          {journeyMainDestination(journey) ?? ''}
          {platform ? ` · ${platform}` : ''}
        </p>
      </div>
      <div className="text-right text-sm">
        <p className="text-slate-300">{journey.durationMinutes} min</p>
        <p className={delay > 0 ? 'text-xs text-amber-400' : 'text-xs text-emerald-400'}>
          {delay > 0 ? `+${delay} min` : t('On time')}
        </p>
      </div>
    </li>
  );
}
