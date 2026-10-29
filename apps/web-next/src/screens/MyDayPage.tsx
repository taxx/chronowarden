import { useState } from 'react';

import { Button, Card, Input, Spinner } from '../components/ui';
import { useNow } from '../hooks/useNow';
import { useT } from '../i18n';
import { formatClock, minutesBetween, toDateStr, toTimeStr } from '../lib/date';
import { expectedMinutesForDate, type WorkConfig } from '../lib/domain/work-config';
import {
  calculateOvertimeMinutes,
  copyWithTimeLog,
  leaveTimeWithBreaks,
  type TimeLog,
} from '../lib/domain/time-log';
import { formatDurationMinutes, formatSignedMinutes } from '../lib/format';
import { useWorkConfig } from '../queries/settings';
import { useCreateTimeLog, useTimeLogs, useTodayLog, useUpdateTimeLog } from '../queries/time-logs';

const DEFAULT_CONFIG: WorkConfig = { defaultExpectedMinutes: 480 };

function minutesSince(iso: string, now: Date): number {
  return Math.max(0, Math.round((now.getTime() - new Date(iso).getTime()) / 60_000));
}

function Stat({ label, value }: { label: string; value: string }) {
  return (
    <div>
      <dt className="text-xs uppercase tracking-wide text-slate-500">{label}</dt>
      <dd className="mt-0.5 text-lg font-semibold text-white">{value}</dd>
    </div>
  );
}

export function MyDayPage() {
  const t = useT();
  const now = useNow(1000);

  const todayQuery = useTodayLog();
  const logsQuery = useTimeLogs();
  const workConfigQuery = useWorkConfig();
  const createLog = useCreateTimeLog();
  const updateLog = useUpdateTimeLog();

  const [error, setError] = useState<string | null>(null);
  const [showFlex, setShowFlex] = useState(false);
  const [flexInput, setFlexInput] = useState('');

  const today = todayQuery.data ?? null;
  const logs = logsQuery.data ?? [];
  const config = workConfigQuery.data ?? DEFAULT_CONFIG;
  const timeBank = logs.reduce((sum, log) => sum + log.overtimeMinutes, 0);

  if (todayQuery.isLoading) {
    return (
      <Card>
        <div className="flex justify-center py-8">
          <Spinner />
        </div>
      </Card>
    );
  }

  const withError = async (action: () => Promise<unknown>) => {
    setError(null);
    try {
      await action();
    } catch {
      setError(t('Could not save'));
    }
  };

  const startDay = () =>
    withError(() =>
      createLog.mutateAsync({
        date: toDateStr(now),
        startTime: toTimeStr(now),
        expectedMinutes: expectedMinutesForDate(config, now),
        lunchMinutes: 0,
        nonWorkMinutes: 0,
        flexMinutes: 0,
        morningOverheadMinutes: 0,
        morningProductiveCommuteMinutes: 0,
        eveningOverheadMinutes: 0,
        eveningProductiveCommuteMinutes: 0,
        overtimeMinutes: 0,
      }),
    );

  const id = today?.id ?? null;

  const patch = (fields: Record<string, unknown>) => {
    if (!id) return Promise.resolve();
    return updateLog.mutateAsync({ id, fields });
  };

  const stopDay = () => {
    if (!today) return Promise.resolve();
    const endTime = toTimeStr(now);
    const overtime = calculateOvertimeMinutes(copyWithTimeLog(today, { endTime }));
    return patch({ end_time: endTime, overtime_minutes: overtime });
  };

  const startBreak = (field: 'lunch_started_at' | 'non_work_started_at') =>
    patch({ [field]: now.toISOString() });

  const stopBreak = (
    startedAt: string | null | undefined,
    minutesField: 'lunch_minutes' | 'non_work_minutes',
    startedField: 'lunch_started_at' | 'non_work_started_at',
  ) => {
    const minutes = startedAt ? minutesSince(startedAt, now) : 0;
    return patch({ [minutesField]: minutes, [startedField]: null });
  };

  // Live leave time, accounting for a break that is still running.
  const lunchActive =
    today?.lunchStartedAt != null
      ? Math.max(today.lunchMinutes, minutesSince(today.lunchStartedAt, now))
      : (today?.lunchMinutes ?? 0);
  const nonWorkActive =
    today?.nonWorkStartedAt != null
      ? Math.max(today.nonWorkMinutes, minutesSince(today.nonWorkStartedAt, now))
      : (today?.nonWorkMinutes ?? 0);

  return (
    <div className="space-y-4">
      {!today ? (
        <Card>
          <h1 className="text-xl font-semibold text-white">{t('My Day')}</h1>
          <p className="mt-1 text-sm text-slate-400">
            {t('Expected today')}: {formatDurationMinutes(expectedMinutesForDate(config, now))}
          </p>
          <Button className="mt-5" onClick={startDay} disabled={createLog.isPending}>
            {t('Start Day')}
          </Button>
        </Card>
      ) : today.endTime == null ? (
        <ActiveDayCard
          log={today}
          now={now}
          leave={leaveTimeWithBreaks(today, {
            lunchMinutes: lunchActive,
            nonWorkMinutes: nonWorkActive,
          })}
          onStartLunch={() => startBreak('lunch_started_at')}
          onStopLunch={() => stopBreak(today.lunchStartedAt, 'lunch_minutes', 'lunch_started_at')}
          onStartNonWork={() => startBreak('non_work_started_at')}
          onStopNonWork={() =>
            stopBreak(today.nonWorkStartedAt, 'non_work_minutes', 'non_work_started_at')
          }
          onStopDay={stopDay}
          onAdjustFlex={() => {
            setFlexInput(String(today.flexMinutes));
            setShowFlex(true);
          }}
        />
      ) : (
        <CompletedDayCard log={today} />
      )}

      {showFlex && today ? (
        <Card>
          <h2 className="text-sm font-medium text-slate-300">{t('Banked time to withdraw')}</h2>
          <div className="mt-3 flex items-center gap-2">
            <Input
              type="number"
              inputMode="numeric"
              className="max-w-32"
              value={flexInput}
              onChange={(event) => setFlexInput(event.target.value)}
            />
            <Button
              onClick={() =>
                withError(async () => {
                  await patch({ flex_minutes: Number(flexInput) || 0 });
                  setShowFlex(false);
                })
              }
            >
              {t('Save')}
            </Button>
            <Button variant="ghost" onClick={() => setShowFlex(false)}>
              {t('Cancel')}
            </Button>
          </div>
        </Card>
      ) : null}

      <Card>
        <h2 className="text-sm font-medium text-slate-300">{t('Time bank')}</h2>
        <p className="mt-2 text-2xl font-semibold text-white">{formatSignedMinutes(timeBank)}</p>
      </Card>

      {error ? <p className="text-sm text-red-400">{error}</p> : null}
    </div>
  );
}

function ActiveDayCard({
  log,
  now,
  leave,
  onStartLunch,
  onStopLunch,
  onStartNonWork,
  onStopNonWork,
  onStopDay,
  onAdjustFlex,
}: {
  log: TimeLog;
  now: Date;
  leave: Date;
  onStartLunch: () => void;
  onStopLunch: () => void;
  onStartNonWork: () => void;
  onStopNonWork: () => void;
  onStopDay: () => void;
  onAdjustFlex: () => void;
}) {
  const t = useT();
  const elapsed = minutesBetween(log.startTime, toTimeStr(now));

  return (
    <Card>
      <h1 className="text-xl font-semibold text-white">{t('My Day')}</h1>
      <dl className="mt-5 grid grid-cols-2 gap-4 sm:grid-cols-4">
        <Stat label={t('Start')} value={log.startTime.slice(0, 5)} />
        <Stat label={t('Leave time')} value={formatClock(leave)} />
        <Stat label={t('Elapsed')} value={formatDurationMinutes(elapsed)} />
        <Stat label={t('Lunch')} value={formatDurationMinutes(log.lunchMinutes)} />
      </dl>

      <div className="mt-6 flex flex-wrap gap-2">
        {log.lunchStartedAt ? (
          <Button variant="ghost" onClick={onStopLunch}>
            {t('Stop lunch')}
          </Button>
        ) : (
          <Button variant="ghost" onClick={onStartLunch}>
            {t('Start lunch')}
          </Button>
        )}

        {log.nonWorkStartedAt ? (
          <Button variant="ghost" onClick={onStopNonWork}>
            {t('Stop non-work')}
          </Button>
        ) : (
          <Button variant="ghost" onClick={onStartNonWork}>
            {t('Start non-work')}
          </Button>
        )}

        <Button variant="ghost" onClick={onAdjustFlex}>
          {t('Banked time to withdraw')}
        </Button>
      </div>

      <Button className="mt-6 w-full" onClick={onStopDay}>
        {t('Stop Day')}
      </Button>
    </Card>
  );
}

function CompletedDayCard({ log }: { log: TimeLog }) {
  const t = useT();
  return (
    <Card>
      <h1 className="text-xl font-semibold text-white">{t('Day complete')}</h1>
      <dl className="mt-5 grid grid-cols-2 gap-4 sm:grid-cols-4">
        <Stat label={t('Start')} value={log.startTime.slice(0, 5)} />
        <Stat label={t('Stop')} value={(log.endTime ?? '').slice(0, 5)} />
        <Stat label={t('Overtime')} value={formatSignedMinutes(log.overtimeMinutes)} />
        <Stat label={t('Non-work')} value={formatDurationMinutes(log.nonWorkMinutes)} />
      </dl>
    </Card>
  );
}
