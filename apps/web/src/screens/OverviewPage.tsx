import { useMemo, useState } from 'react';
import { ChevronLeft, ChevronRight, Info } from 'lucide-react';

import { DayDialog } from '../components/DayDialog';
import { Button, Card, CardContent, CardHeader, Tabs } from '../components/ui';
import { useSaveDay } from '../hooks/useSaveDay';
import { useT } from '../i18n';
import { toDateStr } from '../lib/date';
import type { TimeLog } from '../lib/domain/time-log';
import { isoWeekNumber } from '../lib/domain/work-config';
import { formatSignedMinutes, overtimeTextClass } from '../lib/format';
import { useWorkConfig } from '../queries/settings';
import { useTimeLogs } from '../queries/time-logs';
import { useToastStore } from '../state/toast';

type Period = 'week' | 'month' | 'year';

const PERIOD_KEY = 'cw_overview_period';
const WEEKDAYS = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

function startOfIsoWeek(date: Date): Date {
  const weekday = (date.getDay() + 6) % 7; // Monday = 0
  return new Date(date.getFullYear(), date.getMonth(), date.getDate() - weekday);
}

function sumOvertime(logs: Iterable<TimeLog>): number {
  let total = 0;
  for (const log of logs) total += log.overtimeMinutes;
  return total;
}

export function OverviewPage() {
  const t = useT();
  const logsQuery = useTimeLogs();
  const configQuery = useWorkConfig();
  const { saveDay } = useSaveDay();
  const pushToast = useToastStore((state) => state.push);

  const [period, setPeriodState] = useState<Period>(() => {
    const stored = localStorage.getItem(PERIOD_KEY);
    return stored === 'week' || stored === 'month' || stored === 'year' ? stored : 'week';
  });
  const [cursor, setCursor] = useState(() => new Date());
  const [dialog, setDialog] = useState<{ date: string; log: TimeLog | null } | null>(null);

  function setPeriod(next: Period) {
    localStorage.setItem(PERIOD_KEY, next);
    setPeriodState(next);
  }

  const byDate = useMemo(() => {
    const map = new Map<string, TimeLog>();
    for (const log of logsQuery.data ?? []) map.set(log.date, log);
    return map;
  }, [logsQuery.data]);

  const weekDays = useMemo(() => {
    const monday = startOfIsoWeek(cursor);
    return Array.from({ length: 7 }, (_, i) =>
      new Date(monday.getFullYear(), monday.getMonth(), monday.getDate() + i),
    );
  }, [cursor]);

  const months = useMemo(() => {
    const first = new Date(cursor.getFullYear(), cursor.getMonth(), 1);
    const offset = (first.getDay() + 6) % 7;
    const start = new Date(cursor.getFullYear(), cursor.getMonth(), 1 - offset);
    return Array.from({ length: 6 }, (_, week) =>
      Array.from({ length: 7 }, (_, day) => {
        const date = new Date(start.getFullYear(), start.getMonth(), start.getDate() + week * 7 + day);
        return {
          date,
          inMonth: date.getMonth() === cursor.getMonth(),
          log: byDate.get(toDateStr(date)) ?? null,
        };
      }),
    );
  }, [cursor, byDate]);

  const weekTotal = weekDays.reduce((sum, date) => sum + (byDate.get(toDateStr(date))?.overtimeMinutes ?? 0), 0);
  const monthLogs = [...byDate.values()].filter((log) => {
    const [y, m] = log.date.split('-').map(Number) as [number, number];
    return y === cursor.getFullYear() && m === cursor.getMonth() + 1;
  });
  const yearLogs = [...byDate.values()].filter(
    (log) => Number(log.date.slice(0, 4)) === cursor.getFullYear(),
  );

  function label(): string {
    if (period === 'year') return String(cursor.getFullYear());
    if (period === 'week') {
      const monday = weekDays[0]!;
      const sunday = weekDays[6]!;
      const fmt = new Intl.DateTimeFormat(undefined, { month: 'short', day: 'numeric' });
      return `${t('Week')} ${isoWeekNumber(cursor)} · ${fmt.format(monday)} – ${fmt.format(sunday)}`;
    }
    return new Intl.DateTimeFormat(undefined, { month: 'long', year: 'numeric' }).format(cursor);
  }

  function shift(delta: number) {
    if (period === 'week') {
      setCursor(new Date(cursor.getFullYear(), cursor.getMonth(), cursor.getDate() + delta * 7));
    } else if (period === 'month') {
      setCursor(new Date(cursor.getFullYear(), cursor.getMonth() + delta, 1));
    } else {
      setCursor(new Date(cursor.getFullYear() + delta, cursor.getMonth(), 1));
    }
  }

  async function submit(values: import('../components/DayDialog').DayFormValues) {
    try {
      await saveDay(values, dialog?.log ?? null);
      pushToast(t('Saved'), 'success');
    } catch {
      pushToast(t('Could not save'), 'error');
    } finally {
      setDialog(null);
    }
  }

  if (logsQuery.isLoading) {
    return (
      <Card>
        <CardContent className="grid place-items-center py-10">
          <div className="h-6 w-6 animate-spin rounded-full border-2 border-border border-t-primary" />
        </CardContent>
      </Card>
    );
  }

  const total = period === 'week' ? weekTotal : sumOvertime(period === 'month' ? monthLogs : yearLogs);

  return (
    <>
      <Card>
        <CardHeader
          title={<span className="capitalize">{label()}</span>}
          description={
            <span className="flex items-center gap-1.5">
              <Info className="h-3.5 w-3.5" />
              {t('Green means you kept your time; red means you worked over.')}
            </span>
          }
          action={
            <div className="flex flex-wrap items-center gap-2">
              <Tabs
                value={period}
                onChange={setPeriod}
                items={[
                  { value: 'week', label: t('Week') },
                  { value: 'month', label: t('Month') },
                  { value: 'year', label: t('Year') },
                ]}
              />
              <div className="flex items-center gap-1">
                <Button variant="ghost" size="icon" aria-label={t('Previous')} onClick={() => shift(-1)}>
                  <ChevronLeft className="h-4 w-4" />
                </Button>
                <Button variant="ghost" size="sm" onClick={() => setCursor(new Date())}>
                  {t('Today')}
                </Button>
                <Button variant="ghost" size="icon" aria-label={t('Next')} onClick={() => shift(1)}>
                  <ChevronRight className="h-4 w-4" />
                </Button>
              </div>
            </div>
          }
        />
        <CardContent>
          <div className="mb-4 flex items-baseline gap-2">
            <span className="text-xs uppercase tracking-wide text-muted-foreground">{t('Total')}</span>
            <span className={'text-2xl font-semibold ' + overtimeTextClass(total)}>
              {logsQuery.data && logsQuery.data.length > 0 ? formatSignedMinutes(total) : '—'}
            </span>
          </div>

          {period === 'week' ? (
            <div className="grid grid-cols-2 gap-2 sm:grid-cols-7">
              {weekDays.map((date, index) => {
                const key = toDateStr(date);
                const log = byDate.get(key) ?? null;
                return (
                  <button
                    key={key}
                    type="button"
                    onClick={() => setDialog({ date: key, log })}
                    className="rounded-lg border border-border bg-card p-3 text-left transition hover:bg-accent"
                  >
                    <p className="text-xs uppercase tracking-wide text-muted-foreground">{WEEKDAYS[index]}</p>
                    <p className="mt-0.5 text-sm">{date.getDate()}</p>
                    <p className={'mt-2 text-sm ' + overtimeTextClass(log?.overtimeMinutes ?? 0)}>
                      {log ? formatSignedMinutes(log.overtimeMinutes) : '—'}
                    </p>
                  </button>
                );
              })}
            </div>
          ) : period === 'month' ? (
            <div className="overflow-x-auto">
              <table className="w-full min-w-[640px] border-collapse text-sm">
                <thead>
                  <tr>
                    <th className="w-10 px-1 py-2 text-left text-xs uppercase tracking-wide text-muted-foreground">
                      {t('Week')}
                    </th>
                    {WEEKDAYS.map((day) => (
                      <th key={day} className="px-1 py-2 text-left text-xs uppercase tracking-wide text-muted-foreground">
                        {day}
                      </th>
                    ))}
                  </tr>
                </thead>
                <tbody>
                  {months.map((week, weekIndex) => (
                    <tr key={weekIndex}>
                      <td className="px-1 py-1 align-top text-xs text-muted-foreground">
                        {isoWeekNumber(week[0]!.date)}
                      </td>
                      {week.map((cell) => {
                        const key = toDateStr(cell.date);
                        return (
                          <td key={key} className="px-1 py-1 align-top">
                            <button
                              type="button"
                              onClick={() => setDialog({ date: key, log: cell.log })}
                              className={
                                'h-16 w-full rounded-lg border p-1.5 text-left transition hover:bg-accent ' +
                                (cell.inMonth ? 'border-border bg-card' : 'border-transparent')
                              }
                            >
                              <div className={cell.inMonth ? '' : 'text-muted-foreground'}>
                                {cell.date.getDate()}
                              </div>
                              {cell.log ? (
                                <div className={'mt-1 text-xs ' + overtimeTextClass(cell.log.overtimeMinutes)}>
                                  {formatSignedMinutes(cell.log.overtimeMinutes)}
                                </div>
                              ) : null}
                            </button>
                          </td>
                        );
                      })}
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          ) : (
            <div className="grid grid-cols-2 gap-3 sm:grid-cols-3">
              {Array.from({ length: 12 }, (_, month) => {
                const monthTotal = sumOvertime(
                  yearLogs.filter((log) => Number(log.date.slice(5, 7)) === month + 1),
                );
                const hasData = yearLogs.some((log) => Number(log.date.slice(5, 7)) === month + 1);
                const name = new Intl.DateTimeFormat(undefined, { month: 'long' }).format(
                  new Date(cursor.getFullYear(), month, 1),
                );
                return (
                  <button
                    key={month}
                    type="button"
                    onClick={() => {
                      setCursor(new Date(cursor.getFullYear(), month, 1));
                      setPeriod('month');
                    }}
                    className="rounded-lg border border-border bg-card p-3 text-left transition hover:bg-accent"
                  >
                    <p className="text-sm capitalize">{name}</p>
                    <p className={'mt-2 text-lg font-semibold ' + overtimeTextClass(monthTotal)}>
                      {hasData ? formatSignedMinutes(monthTotal) : '—'}
                    </p>
                  </button>
                );
              })}
            </div>
          )}
        </CardContent>
      </Card>

      <DayDialog
        open={dialog != null}
        onClose={() => setDialog(null)}
        initial={dialog?.log ?? null}
        defaultDate={dialog?.date}
        defaultExpectedMinutes={configQuery.data?.defaultExpectedMinutes ?? 480}
        onSubmit={submit}
      />
    </>
  );
}
