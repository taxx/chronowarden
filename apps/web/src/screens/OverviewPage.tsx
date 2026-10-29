import { useMemo, useState } from 'react';

import { Button, Card } from '../components/ui';
import { useT } from '../i18n';
import { toDateStr } from '../lib/date';
import { isoWeekNumber } from '../lib/domain/work-config';
import type { TimeLog } from '../lib/domain/time-log';
import { formatSignedMinutes } from '../lib/format';
import { useTimeLogs } from '../queries/time-logs';

type Period = 'week' | 'month' | 'year';

const WEEKDAYS = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

function startOfIsoWeek(date: Date): Date {
  const weekday = (date.getDay() + 6) % 7; // Monday = 0
  return new Date(date.getFullYear(), date.getMonth(), date.getDate() - weekday);
}

function monthTotal(byDate: Map<string, TimeLog>, year: number, month: number): number {
  let total = 0;
  for (const log of byDate.values()) {
    const [y, m] = log.date.split('-').map(Number) as [number, number];
    if (y === year && m === month + 1) total += log.overtimeMinutes;
  }
  return total;
}

function overtimeClass(minutes: number): string {
  return minutes >= 0 ? 'text-success' : 'text-warning';
}

export function OverviewPage() {
  const t = useT();
  const logsQuery = useTimeLogs();
  const [period, setPeriod] = useState<Period>('month');
  const [cursor, setCursor] = useState(() => new Date());

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

  const weeks = useMemo(() => {
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

  const monthLabel = new Intl.DateTimeFormat(undefined, { month: 'long', year: 'numeric' }).format(cursor);
  const yearLabel = String(cursor.getFullYear());

  function label(): string {
    if (period === 'year') return yearLabel;
    if (period === 'week') {
      const week = isoWeekNumber(cursor);
      const monday = weekDays[0]!;
      const sunday = weekDays[6]!;
      const fmt = new Intl.DateTimeFormat(undefined, { month: 'short', day: 'numeric' });
      return `${t('Week')} ${week} · ${fmt.format(monday)} – ${fmt.format(sunday)}`;
    }
    return monthLabel;
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

  if (logsQuery.isLoading) {
    return (
      <Card>
        <div className="flex justify-center py-8 text-muted-foreground">{t('Loading…')}</div>
      </Card>
    );
  }

  return (
    <Card>
      <div className="flex flex-wrap items-center justify-between gap-3">
        <h1 className="text-xl font-semibold capitalize text-foreground">{label()}</h1>
        <div className="flex items-center gap-1">
          <Button variant={period === 'week' ? 'primary' : 'ghost'} onClick={() => setPeriod('week')}>
            {t('Week')}
          </Button>
          <Button variant={period === 'month' ? 'primary' : 'ghost'} onClick={() => setPeriod('month')}>
            {t('Month')}
          </Button>
          <Button variant={period === 'year' ? 'primary' : 'ghost'} onClick={() => setPeriod('year')}>
            {t('Year')}
          </Button>
          <Button variant="ghost" onClick={() => shift(-1)}>
            ‹
          </Button>
          <Button variant="ghost" onClick={() => setCursor(new Date())}>
            {t('Today')}
          </Button>
          <Button variant="ghost" onClick={() => shift(1)}>
            ›
          </Button>
        </div>
      </div>

      {period === 'week' ? (
        <div className="mt-4 grid grid-cols-2 gap-2 sm:grid-cols-7">
          {weekDays.map((date, index) => {
            const log = byDate.get(toDateStr(date)) ?? null;
            return (
              <div key={toDateStr(date)} className="rounded-lg border border-border bg-card p-3">
                <p className="text-xs uppercase tracking-wide text-muted-foreground">{WEEKDAYS[index]}</p>
                <p className="mt-0.5 text-sm text-foreground">{date.getDate()}</p>
                {log ? (
                  <p className={'mt-2 text-sm ' + overtimeClass(log.overtimeMinutes)}>
                    {formatSignedMinutes(log.overtimeMinutes)}
                  </p>
                ) : (
                  <p className="mt-2 text-sm text-muted-foreground">—</p>
                )}
              </div>
            );
          })}
        </div>
      ) : period === 'month' ? (
        <div className="mt-4 overflow-x-auto">
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
              {weeks.map((week, weekIndex) => (
                <tr key={weekIndex}>
                  <td className="px-1 py-1 align-top text-xs text-muted-foreground">
                    {isoWeekNumber(week[0]!.date)}
                  </td>
                  {week.map((cell) => {
                    const key = toDateStr(cell.date);
                    const overtime = cell.log?.overtimeMinutes ?? 0;
                    return (
                      <td key={key} className="px-1 py-1 align-top">
                        <div
                          className={
                            'h-16 rounded-lg border p-1.5 ' +
                            (cell.inMonth ? 'border-border bg-card' : 'border-transparent')
                          }
                        >
                          <div className={cell.inMonth ? 'text-foreground' : 'text-muted-foreground'}>
                            {cell.date.getDate()}
                          </div>
                          {cell.log ? (
                            <div className={'mt-1 text-xs ' + overtimeClass(overtime)}>
                              {formatSignedMinutes(overtime)}
                            </div>
                          ) : null}
                        </div>
                      </td>
                    );
                  })}
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      ) : (
        <div className="mt-4 grid grid-cols-2 gap-3 sm:grid-cols-3">
          {Array.from({ length: 12 }, (_, month) => {
            const total = monthTotal(byDate, cursor.getFullYear(), month);
            const name = new Intl.DateTimeFormat(undefined, { month: 'long' }).format(
              new Date(cursor.getFullYear(), month, 1),
            );
            const hasData = [...byDate.values()].some((log) => {
              const [y, m] = log.date.split('-').map(Number) as [number, number];
              return y === cursor.getFullYear() && m === month + 1;
            });
            return (
              <div key={month} className="rounded-lg border border-border bg-card p-3">
                <p className="text-sm capitalize text-foreground">{name}</p>
                <p className={'mt-2 text-lg font-semibold ' + overtimeClass(total)}>
                  {hasData ? formatSignedMinutes(total) : '—'}
                </p>
              </div>
            );
          })}
        </div>
      )}
    </Card>
  );
}
