import { useMemo, useState } from 'react';

import { Button, Card } from '../components/ui';
import { useT } from '../i18n';
import { toDateStr } from '../lib/date';
import { isoWeekNumber } from '../lib/domain/work-config';
import type { TimeLog } from '../lib/domain/time-log';
import { formatSignedMinutes } from '../lib/format';
import { useTimeLogs } from '../queries/time-logs';

const WEEKDAYS = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

interface DayCell {
  date: Date;
  inMonth: boolean;
  log: TimeLog | null;
}

function buildMonth(year: number, month: number, byDate: Map<string, TimeLog>): DayCell[][] {
  const first = new Date(year, month, 1);
  const startOffset = (first.getDay() + 6) % 7; // Monday-based
  const start = new Date(year, month, 1 - startOffset);

  const weeks: DayCell[][] = [];
  for (let week = 0; week < 6; week++) {
    const days: DayCell[] = [];
    for (let day = 0; day < 7; day++) {
      const date = new Date(start.getFullYear(), start.getMonth(), start.getDate() + week * 7 + day);
      const key = toDateStr(date);
      days.push({ date, inMonth: date.getMonth() === month, log: byDate.get(key) ?? null });
    }
    weeks.push(days);
  }
  return weeks;
}

export function OverviewPage() {
  const t = useT();
  const logsQuery = useTimeLogs();
  const [cursor, setCursor] = useState(() => new Date());

  const byDate = useMemo(() => {
    const map = new Map<string, TimeLog>();
    for (const log of logsQuery.data ?? []) map.set(log.date, log);
    return map;
  }, [logsQuery.data]);

  const weeks = useMemo(
    () => buildMonth(cursor.getFullYear(), cursor.getMonth(), byDate),
    [cursor, byDate],
  );

  const monthLabel = new Intl.DateTimeFormat(undefined, {
    month: 'long',
    year: 'numeric',
  }).format(cursor);

  const shiftMonth = (delta: number) =>
    setCursor(new Date(cursor.getFullYear(), cursor.getMonth() + delta, 1));

  return (
    <Card>
      <div className="flex items-center justify-between gap-4">
        <h1 className="text-xl font-semibold capitalize text-white">{monthLabel}</h1>
        <div className="flex gap-2">
          <Button variant="ghost" onClick={() => shiftMonth(-1)}>
            ‹
          </Button>
          <Button variant="ghost" onClick={() => setCursor(new Date())}>
            {t('Today')}
          </Button>
          <Button variant="ghost" onClick={() => shiftMonth(1)}>
            ›
          </Button>
        </div>
      </div>

      <div className="mt-4 overflow-x-auto">
        <table className="w-full min-w-[640px] border-collapse text-sm">
          <thead>
            <tr>
              <th className="w-10 px-1 py-2 text-left text-xs uppercase tracking-wide text-slate-500">
                {t('Week')}
              </th>
              {WEEKDAYS.map((day) => (
                <th key={day} className="px-1 py-2 text-left text-xs uppercase tracking-wide text-slate-500">
                  {day}
                </th>
              ))}
            </tr>
          </thead>
          <tbody>
            {weeks.map((week, weekIndex) => (
              <tr key={weekIndex}>
                <td className="px-1 py-1 align-top text-xs text-slate-500">
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
                          (cell.inMonth ? 'border-slate-800 bg-slate-900/60' : 'border-transparent')
                        }
                      >
                        <div className={cell.inMonth ? 'text-slate-300' : 'text-slate-600'}>
                          {cell.date.getDate()}
                        </div>
                        {cell.log ? (
                          <div
                            className={
                              overtime >= 0 ? 'mt-1 text-xs text-emerald-400' : 'mt-1 text-xs text-amber-400'
                            }
                          >
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
    </Card>
  );
}
