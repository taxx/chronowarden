import { overheadMinutes, elapsedMinutes, type TimeLog } from './time-log';

/**
 * Time-bank chart data — ported from the Flutter `TimeBankChart`.
 *
 * Each bar is the *relative change* for the period (the day's overtime in
 * week/month view, the month's overtime in year view). The optional trend line
 * is the running balance, expressed as a deviation from the period's baseline
 * (the bank at the start of the period), so the Y axis stays centred on zero.
 */
export type ChartPeriod = 'week' | 'month' | 'year';

export interface TimeBankPoint {
  label: string;
  delta: number;
  /** cumulative balance − baseline */
  deviation: number;
}

export interface TimeBankChartData {
  points: TimeBankPoint[];
  /** Bank balance before the period started. */
  baseline: number;
  endBalance: number;
  netChange: number;
  maxAbs: number;
}

export interface PeriodSummary {
  daysLogged: number;
  workedMinutes: number;
  expectedMinutes: number;
  overheadBufferMinutes: number;
  overtimeMinutes: number;
}

const WEEKDAYS = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const MONTHS = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

function dateStr(date: Date): string {
  return `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, '0')}-${String(date.getDate()).padStart(2, '0')}`;
}

function weekStart(date: Date): Date {
  const weekday = (date.getDay() + 6) % 7; // Monday = 0
  return new Date(date.getFullYear(), date.getMonth(), date.getDate() - weekday);
}

function periodBounds(period: ChartPeriod, refDate: Date): { start: string; end: string } {
  if (period === 'week') {
    const monday = weekStart(refDate);
    const sunday = new Date(monday.getFullYear(), monday.getMonth(), monday.getDate() + 6);
    return { start: dateStr(monday), end: dateStr(sunday) };
  }
  if (period === 'month') {
    const last = new Date(refDate.getFullYear(), refDate.getMonth() + 1, 0);
    return { start: dateStr(new Date(refDate.getFullYear(), refDate.getMonth(), 1)), end: dateStr(last) };
  }
  return {
    start: `${refDate.getFullYear()}-01-01`,
    end: `${refDate.getFullYear()}-12-31`,
  };
}

function isWeekend(dateStrValue: string): boolean {
  const day = new Date(`${dateStrValue}T00:00:00`).getDay();
  return day === 0 || day === 6;
}

/** Logs inside the period, honouring the weekend visibility preference. */
export function filterLogsForPeriod(
  logs: TimeLog[],
  period: ChartPeriod,
  refDate: Date,
  showWeekends: boolean,
): TimeLog[] {
  const { start, end } = periodBounds(period, refDate);
  return logs.filter((log) => {
    if (log.date < start || log.date > end) return false;
    if (!showWeekends && isWeekend(log.date)) return false;
    return true;
  });
}

export function summarizePeriod(
  logs: TimeLog[],
  period: ChartPeriod,
  refDate: Date,
  showWeekends: boolean,
): PeriodSummary {
  const filtered = filterLogsForPeriod(logs, period, refDate, showWeekends);
  return filtered.reduce<PeriodSummary>(
    (acc, log) => ({
      daysLogged: acc.daysLogged + 1,
      workedMinutes: acc.workedMinutes + elapsedMinutes(log),
      expectedMinutes: acc.expectedMinutes + log.expectedMinutes,
      overheadBufferMinutes: acc.overheadBufferMinutes + overheadMinutes(log),
      overtimeMinutes: acc.overtimeMinutes + log.overtimeMinutes,
    }),
    { daysLogged: 0, workedMinutes: 0, expectedMinutes: 0, overheadBufferMinutes: 0, overtimeMinutes: 0 },
  );
}

export function buildTimeBankChart(
  logs: TimeLog[],
  period: ChartPeriod,
  refDate: Date,
  showWeekends: boolean,
): TimeBankChartData {
  const { start, end } = periodBounds(period, refDate);
  const byDate = new Map<string, TimeLog>();
  for (const log of logs) byDate.set(log.date, log);

  const baseline = logs
    .filter((log) => log.date < start)
    .reduce((sum, log) => sum + log.overtimeMinutes, 0);

  const deltas: Array<{ label: string; delta: number }> = [];

  if (period === 'week') {
    const monday = weekStart(refDate);
    for (let i = 0; i < 7; i += 1) {
      const day = new Date(monday.getFullYear(), monday.getMonth(), monday.getDate() + i);
      if (!showWeekends && (day.getDay() === 0 || day.getDay() === 6)) continue;
      const log = byDate.get(dateStr(day));
      if (!log || log.endTime == null) continue;
      deltas.push({ label: WEEKDAYS[i]!, delta: log.overtimeMinutes });
    }
  } else if (period === 'month') {
    const lastDay = new Date(refDate.getFullYear(), refDate.getMonth() + 1, 0).getDate();
    for (let day = 1; day <= lastDay; day += 1) {
      const date = new Date(refDate.getFullYear(), refDate.getMonth(), day);
      if (!showWeekends && (date.getDay() === 0 || date.getDay() === 6)) continue;
      const log = byDate.get(dateStr(date));
      if (!log || log.endTime == null) continue;
      const label = day === 1 || day === lastDay || day % 5 === 0 ? String(day) : '';
      deltas.push({ label, delta: log.overtimeMinutes });
    }
  } else {
    const year = refDate.getFullYear();
    for (let month = 0; month < 12; month += 1) {
      const monthPrefix = `${year}-${String(month + 1).padStart(2, '0')}`;
      let monthly = 0;
      for (const log of logs) {
        if (log.date >= start && log.date <= end && log.date.startsWith(monthPrefix)) {
          monthly += log.overtimeMinutes;
        }
      }
      deltas.push({ label: MONTHS[month]!, delta: monthly });
    }
  }

  let running = baseline;
  let maxAbs = 1;
  const points: TimeBankPoint[] = deltas.map(({ label, delta }) => {
    running += delta;
    const deviation = running - baseline;
    maxAbs = Math.max(maxAbs, Math.abs(delta), Math.abs(deviation));
    return { label, delta, deviation };
  });

  if (points.length === 0) {
    return { points: [], baseline, endBalance: baseline, netChange: 0, maxAbs: 1 };
  }

  return {
    points,
    baseline,
    endBalance: running,
    netChange: running - baseline,
    maxAbs,
  };
}
