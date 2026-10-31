import type { TimeLog } from './time-log';

/**
 * Time-bank projection maths — ported from the Flutter `ProjectionScreen`.
 *
 * The bank grows by each completed day's `overtimeMinutes` and shrinks by the
 * daily flex the user chooses to withdraw. "Trend" additionally subtracts the
 * recent average growth, so the projection matches how the bank has actually
 * been moving.
 */
export interface ProjectionPoint {
  label: string;
  /** Cumulative balance over recorded days (null after the split). */
  actual: number | null;
  /** Projected balance from today onward (null before the split). */
  projected: number | null;
  /** Only present when trend mode is on. */
  trend?: number | null;
}

export interface ProjectionResult {
  points: ProjectionPoint[];
  /** Sum of overtime over all completed logs. */
  currentBalance: number;
  /** Average weekly overtime over the last ~30 completed workdays. */
  avgGrowthWeekly: number;
  effectiveWeekly: number;
  netWeeklyChange: number;
  weeksToZero: number;
  zeroDate: Date | null;
}

function dayLabel(date: Date): string {
  return `${date.getDate()}/${date.getMonth() + 1}`;
}

/** Average weekly overtime from completed logs in the last ~30 workdays. */
export function computeAvgGrowthWeekly(logs: TimeLog[], today: Date): number {
  const cutoff = new Date(today.getFullYear(), today.getMonth(), today.getDate() - 60);
  const tomorrow = new Date(today.getFullYear(), today.getMonth(), today.getDate() + 1);
  const recent = logs
    .filter((log) => {
      if (!log.endTime) return false;
      const date = new Date(`${log.date}T00:00:00`);
      return date > cutoff && date < tomorrow;
    })
    .sort((a, b) => a.date.localeCompare(b.date));

  if (recent.length < 5) return 0;
  const total = recent.reduce((sum, log) => sum + log.overtimeMinutes, 0);
  return Math.trunc(total / recent.length) * 5;
}

export function computeProjection(
  logs: TimeLog[],
  dailyFlex: number,
  useTrend: boolean,
  today: Date,
): ProjectionResult {
  const avgGrowthWeekly = computeAvgGrowthWeekly(logs, today);
  const avgGrowthDaily = Math.trunc(avgGrowthWeekly / 5);
  const currentBalance = logs.reduce((sum, log) => sum + log.overtimeMinutes, 0);

  const netChange = useTrend
    ? Math.min(Math.max(dailyFlex - avgGrowthDaily, 0), dailyFlex)
    : dailyFlex;
  const effectiveWeekly = netChange * 5;
  const weeksToZero =
    currentBalance <= 0 || netChange <= 0 ? 0 : Math.ceil(currentBalance / (netChange * 5));
  const zeroDate =
    weeksToZero > 0
      ? new Date(today.getFullYear(), today.getMonth(), today.getDate() + weeksToZero * 7)
      : null;

  const completed = logs
    .filter((log) => log.endTime != null)
    .sort((a, b) => a.date.localeCompare(b.date));

  const points: ProjectionPoint[] = [];
  let cumulative = 0;
  completed.forEach((log, index) => {
    cumulative += log.overtimeMinutes;
    const date = new Date(`${log.date}T00:00:00`);
    const label =
      index === 0 || index === completed.length - 1 || (index + 1) % 10 === 0 ? dayLabel(date) : '';
    points.push({ label, actual: cumulative, projected: null });
  });

  // Connection point ("now") shared by both series.
  points.push({ label: 'now', actual: currentBalance, projected: currentBalance });

  let projected = currentBalance;
  let trendCum = currentBalance;
  const maxDays = 365;
  for (let i = 1; i <= maxDays; i += 1) {
    const day = new Date(today.getFullYear(), today.getMonth(), today.getDate() + i);
    if (day.getDay() === 0 || day.getDay() === 6) continue;
    projected -= netChange;
    trendCum += avgGrowthDaily;
    if (projected <= 0) {
      points.push({ label: dayLabel(day), actual: null, projected: 0 });
      break;
    }
    points.push({
      label: i % 20 === 0 ? dayLabel(day) : '',
      actual: null,
      projected,
      ...(useTrend ? { trend: trendCum } : {}),
    });
  }

  return {
    points,
    currentBalance,
    avgGrowthWeekly,
    effectiveWeekly,
    netWeeklyChange: -effectiveWeekly,
    weeksToZero,
    zeroDate,
  };
}
