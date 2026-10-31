import { useMemo, useState } from 'react';
import { ChevronLeft, ChevronRight, Info } from 'lucide-react';

import { DayDialog } from '../components/DayDialog';
import { TimeBankChart } from '../components/TimeBankChart';
import { ChartSkeleton, StatGridSkeleton } from '../components/skeletons';
import {
  Button,
  Card,
  CardContent,
  CardHeader,
  Tabs,
  Tooltip,
  TooltipContent,
  TooltipTrigger,
  cn,
} from '../components/ui';
import { useSaveDay } from '../hooks/useSaveDay';
import { useT } from '../i18n';
import { toDateStr } from '../lib/date';
import type { TimeLog } from '../lib/domain/time-log';
import { buildTimeBankChart, summarizePeriod, type ChartPeriod } from '../lib/domain/time-bank-chart';
import { isoWeekNumber } from '../lib/domain/work-config';
import { formatDurationMinutes, overtimeTextClass } from '../lib/format';
import { usePreferences, useWorkConfig } from '../queries/settings';
import { useTimeLogs } from '../queries/time-logs';
import { useToastStore } from '../state/toast';

type Period = ChartPeriod;

const PERIOD_KEY = 'cw_overview_period';
const TREND_KEY = 'cw_overview_trend';
const WEEKDAYS = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

function startOfIsoWeek(date: Date): Date {
  const weekday = (date.getDay() + 6) % 7; // Monday = 0
  return new Date(date.getFullYear(), date.getMonth(), date.getDate() - weekday);
}

/**
 * Subtle time-warding tint for a calendar cell: green when time was kept
 * (negative overtime), amber when the user worked over. Zero/no log stays neutral.
 */
function cellTint(minutes: number | null): string {
  if (minutes == null) return 'bg-card hover:bg-accent';
  if (minutes < 0) return 'border-success/30 bg-success/10 hover:bg-success/20';
  if (minutes > 0) return 'border-warning/30 bg-warning/10 hover:bg-warning/20';
  return 'bg-card hover:bg-accent';
}

export function OverviewPage() {
  const t = useT();
  const logsQuery = useTimeLogs();
  const configQuery = useWorkConfig();
  const prefsQuery = usePreferences();
  const { saveDay } = useSaveDay();
  const pushToast = useToastStore((state) => state.push);

  const [period, setPeriodState] = useState<Period>(() => {
    const stored = localStorage.getItem(PERIOD_KEY);
    return stored === 'week' || stored === 'month' || stored === 'year' ? stored : 'week';
  });
  const [showTrend, setShowTrend] = useState(() => localStorage.getItem(TREND_KEY) === 'true');
  const [cursor, setCursor] = useState(() => new Date());
  const [dialog, setDialog] = useState<{ date: string; log: TimeLog | null } | null>(null);

  function setPeriod(next: Period) {
    localStorage.setItem(PERIOD_KEY, next);
    setPeriodState(next);
  }

  function toggleTrend(value: boolean) {
    localStorage.setItem(TREND_KEY, String(value));
    setShowTrend(value);
  }

  const logs = logsQuery.data ?? [];
  const showWeekends = prefsQuery.data?.showWeekends ?? true;

  const byDate = useMemo(() => {
    const map = new Map<string, TimeLog>();
    for (const log of logs) map.set(log.date, log);
    return map;
  }, [logs]);

  const summary = useMemo(
    () => summarizePeriod(logs, period, cursor, showWeekends),
    [logs, period, cursor, showWeekends],
  );

  const chart = useMemo(
    () => buildTimeBankChart(logs, period, cursor, showWeekends),
    [logs, period, cursor, showWeekends],
  );

  const weekDays = useMemo(() => {
    const monday = startOfIsoWeek(cursor);
    const all = Array.from({ length: 7 }, (_, i) =>
      new Date(monday.getFullYear(), monday.getMonth(), monday.getDate() + i),
    );
    return showWeekends ? all : all.slice(0, 5);
  }, [cursor, showWeekends]);

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
      }).filter(
        (cell) => showWeekends || (cell.date.getDay() !== 0 && cell.date.getDay() !== 6),
      ),
    );
  }, [cursor, byDate, showWeekends]);

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
      <div className="space-y-4">
        <Card>
          <CardContent className="space-y-5 p-5">
            <StatGridSkeleton />
            <div className="grid grid-cols-2 gap-2 sm:grid-cols-7">
              {Array.from({ length: 7 }, (_, i) => (
                <div key={i} className="h-20 rounded-lg border bg-card" />
              ))}
            </div>
          </CardContent>
        </Card>
        <ChartSkeleton />
      </div>
    );
  }

  function Stat({ label: statLabel, value, tone }: { label: string; value: string; tone?: string }) {
    return (
      <div className="rounded-lg border bg-card p-3">
        <p className="text-xs uppercase tracking-wide text-muted-foreground">{statLabel}</p>
        <p className={'mt-1 text-lg font-semibold ' + (tone ?? '')}>{value}</p>
      </div>
    );
  }

  return (
    <>
      <div className="space-y-4">
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
          <CardContent className="space-y-5">
            <div className="grid grid-cols-2 gap-3 sm:grid-cols-3 lg:grid-cols-5">
              <Stat label={t('Days logged')} value={String(summary.daysLogged)} />
              <Stat label={t('Total hours worked')} value={formatDurationMinutes(summary.workedMinutes)} />
              <Stat label={t('Expected work')} value={formatDurationMinutes(summary.expectedMinutes)} />
              <Stat label={t('Overhead buffer')} value={formatDurationMinutes(summary.overheadBufferMinutes)} />
              <Stat
                label={t('Net overtime')}
                value={formatDurationMinutes(summary.overtimeMinutes)}
                tone={overtimeTextClass(summary.overtimeMinutes)}
              />
            </div>

            {summary.daysLogged === 0 ? (
              <p className="text-sm text-muted-foreground">{t('No logs in this period')}</p>
            ) : null}

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
                      className={cn(
                        'rounded-lg border p-3 text-left transition',
                        cellTint(log?.overtimeMinutes ?? null),
                      )}
                    >
                      <p className="text-xs uppercase tracking-wide text-muted-foreground">{WEEKDAYS[index]}</p>
                      <p className="mt-0.5 text-sm">{date.getDate()}</p>
                      <p className={'mt-2 text-sm ' + overtimeTextClass(log?.overtimeMinutes ?? 0)}>
                        {log ? formatDurationMinutes(log.overtimeMinutes) : '—'}
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
                      {(showWeekends ? WEEKDAYS : WEEKDAYS.slice(0, 5)).map((day) => (
                        <th key={day} className="px-1 py-2 text-left text-xs uppercase tracking-wide text-muted-foreground">
                          {day}
                        </th>
                      ))}
                    </tr>
                  </thead>
                  <tbody>
                    {months.map((week, weekIndex) => (
                      <tr key={weekIndex}>
                        <td className="px-1 py-1 align-top">
                          <Tooltip>
                            <TooltipTrigger asChild>
                              <button
                                type="button"
                                aria-label={t('View week')}
                                onClick={() => {
                                  setCursor(week[0]!.date);
                                  setPeriod('week');
                                }}
                                className="rounded px-1.5 py-1 text-xs text-muted-foreground transition hover:bg-accent hover:text-foreground"
                              >
                                {isoWeekNumber(week[0]!.date)}
                              </button>
                            </TooltipTrigger>
                            <TooltipContent>{t('View week')}</TooltipContent>
                          </Tooltip>
                        </td>
                        {week.map((cell) => {
                          const key = toDateStr(cell.date);
                          return (
                            <td key={key} className="px-1 py-1 align-top">
                              <button
                                type="button"
                                onClick={() => setDialog({ date: key, log: cell.log })}
                                className={cn(
                                  'h-16 w-full rounded-lg border p-1.5 text-left transition',
                                  cell.inMonth
                                    ? cellTint(cell.log?.overtimeMinutes ?? null)
                                    : 'border-transparent',
                                )}
                              >
                                <div className={cell.inMonth ? '' : 'text-muted-foreground'}>
                                  {cell.date.getDate()}
                                </div>
                                {cell.log ? (
                                  <div className={'mt-1 text-xs ' + overtimeTextClass(cell.log.overtimeMinutes)}>
                                    {formatDurationMinutes(cell.log.overtimeMinutes)}
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
                  const monthTotal = logs
                    .filter(
                      (log) =>
                        Number(log.date.slice(0, 4)) === cursor.getFullYear() &&
                        Number(log.date.slice(5, 7)) === month + 1,
                    )
                    .reduce((sum, log) => sum + log.overtimeMinutes, 0);
                  const hasData = logs.some(
                    (log) =>
                      Number(log.date.slice(0, 4)) === cursor.getFullYear() &&
                      Number(log.date.slice(5, 7)) === month + 1,
                  );
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
                      className={cn(
                        'rounded-lg border p-3 text-left transition',
                        cellTint(hasData ? monthTotal : null),
                      )}
                    >
                      <p className="text-sm capitalize">{name}</p>
                      <p className={'mt-2 text-lg font-semibold ' + overtimeTextClass(monthTotal)}>
                        {hasData ? formatDurationMinutes(monthTotal) : '—'}
                      </p>
                    </button>
                  );
                })}
              </div>
            )}
          </CardContent>
        </Card>

        <TimeBankChart data={chart} showTrend={showTrend} onToggleTrend={toggleTrend} />
      </div>

      <DayDialog
        open={dialog != null}
        onClose={() => setDialog(null)}
        initial={dialog?.log ?? null}
        defaultDate={dialog?.date}
        defaultExpectedMinutes={configQuery.data?.defaultExpectedMinutes ?? 480}
        defaultLunchMinutes={prefsQuery.data?.defaultLunchMinutes ?? 0}
        onSubmit={submit}
      />
    </>
  );
}
