/**
 * A single workday log entry.
 *
 * Ported from `apps/web/lib/models/time_log.dart` (same behaviour and tests).
 * Kept as a plain object plus pure functions — no class — which is idiomatic for
 * React and trivially testable.
 *
 * Commute values are stored per direction so asymmetrical commutes are handled
 * correctly.
 */
export interface TimeLog {
  id?: string | null;
  userId?: string | null;
  /** "YYYY-MM-DD" */
  date: string;
  /** "HH:MM:SS" */
  startTime: string;
  /** "HH:MM:SS" — null/undefined while the day is active */
  endTime?: string | null;
  expectedMinutes: number;
  lunchMinutes: number;
  /** Non-work time (errands) — counts as not working, like lunch. */
  nonWorkMinutes: number;
  flexMinutes: number;
  morningOverheadMinutes: number;
  morningProductiveCommuteMinutes: number;
  eveningOverheadMinutes: number;
  eveningProductiveCommuteMinutes: number;
  overtimeMinutes: number;
  note?: string | null;
  createdAt?: string | null;
  /** ISO timestamp, null when lunch is not running. */
  lunchStartedAt?: string | null;
  /** ISO timestamp, null when non-work is not running. */
  nonWorkStartedAt?: string | null;
}

export function overheadMinutes(log: TimeLog): number {
  return log.morningOverheadMinutes + log.eveningOverheadMinutes;
}

export function productiveCommuteMinutes(log: TimeLog): number {
  return log.morningProductiveCommuteMinutes + log.eveningProductiveCommuteMinutes;
}

/** Merge "YYYY-MM-DD" + "HH:MM:SS" into a local Date. */
export function combineDateAndTime(dateStr: string, timeStr: string): Date {
  const [year, month, day] = dateStr.split('-').map(Number) as [number, number, number];
  const parts = timeStr.split(':');
  const hour = Number(parts[0]);
  const minute = Number(parts[1]);
  const second = parts.length > 2 ? Number(parts[2]!.split('.')[0]) : 0;
  return new Date(year, month - 1, day, hour, minute, second);
}

/**
 * Projected leave time.
 *
 * `start + expected + lunch + nonWork + morningOverhead − eveningProductive − flex`
 *
 * The morning overhead is added (walking happens after starting but before
 * arriving), the evening productive commute is subtracted (that work happens
 * after leaving). The evening overhead is intentionally excluded.
 */
export function leaveTimeWithBreaks(
  log: TimeLog,
  overrides: { lunchMinutes?: number; nonWorkMinutes?: number } = {},
): Date {
  const start = combineDateAndTime(log.date, log.startTime);
  const minutes =
    log.expectedMinutes +
    (overrides.lunchMinutes ?? log.lunchMinutes) +
    (overrides.nonWorkMinutes ?? log.nonWorkMinutes) +
    log.morningOverheadMinutes -
    log.eveningProductiveCommuteMinutes -
    log.flexMinutes;
  return new Date(start.getTime() + minutes * 60_000);
}

/** Convenience wrapper around {@link leaveTimeWithBreaks}. */
export function leaveTime(log: TimeLog): Date {
  return leaveTimeWithBreaks(log);
}

/** Leave time from an explicit day-start (the "morning calculator"). */
export function calculateLeaveTime(log: TimeLog, dayStart: Date): Date {
  const minutes =
    log.expectedMinutes +
    log.lunchMinutes +
    log.nonWorkMinutes +
    log.morningOverheadMinutes -
    log.eveningProductiveCommuteMinutes -
    log.flexMinutes;
  return new Date(dayStart.getTime() + minutes * 60_000);
}

/**
 * Net overtime in minutes.
 *
 * `(end − start) − lunch − nonWork − (expected + overhead)`. Positive = overtime,
 * negative = time-bank credit, `0` while the day is open. Flex is excluded by
 * design (it shifts the projection only).
 */
export function calculateOvertimeMinutes(log: TimeLog): number {
  if (!log.endTime) return 0;
  const start = combineDateAndTime(log.date, log.startTime);
  const end = combineDateAndTime(log.date, log.endTime);
  const actualMinutes = Math.floor((end.getTime() - start.getTime()) / 60_000);
  const totalExpected = log.expectedMinutes + overheadMinutes(log);
  return actualMinutes - log.lunchMinutes - log.nonWorkMinutes - totalExpected;
}

export function totalExpectedMinutes(log: TimeLog): number {
  return log.expectedMinutes + overheadMinutes(log);
}

export function overtimeLabel(log: TimeLog): string {
  if (!log.endTime) return '— working —';
  const mins = log.overtimeMinutes;
  if (mins === 0) return '✓ Exactly on target';
  if (mins > 0) return `+${mins} min overtime`;
  return `${mins} min early`;
}

export function timeLogFromJson(json: Record<string, any>): TimeLog {
  const morningOverhead = json['morning_overhead_minutes'] as number | undefined;
  const morningProductive = json['morning_productive_commute_minutes'] as number | undefined;
  const eveningOverhead = json['evening_overhead_minutes'] as number | undefined;
  const eveningProductive = json['evening_productive_commute_minutes'] as number | undefined;

  const base = {
    id: (json['id'] as string | null) ?? null,
    userId: (json['user_id'] as string | null) ?? null,
    date: json['date'] as string,
    startTime: json['start_time'] as string,
    endTime: (json['end_time'] as string | null) ?? null,
    expectedMinutes: json['expected_minutes'] as number,
    lunchMinutes: (json['lunch_minutes'] as number | null) ?? 0,
    nonWorkMinutes: (json['non_work_minutes'] as number | null) ?? 0,
    flexMinutes: (json['flex_minutes'] as number | null) ?? 0,
    overtimeMinutes: json['overtime_minutes'] as number,
    note: (json['note'] as string | null) ?? null,
    createdAt: (json['created_at'] as string | null) ?? null,
    lunchStartedAt: (json['lunch_started_at'] as string | null) ?? null,
    nonWorkStartedAt: (json['non_work_started_at'] as string | null) ?? null,
  };

  if (morningOverhead != null && eveningOverhead != null) {
    return {
      ...base,
      morningOverheadMinutes: morningOverhead,
      morningProductiveCommuteMinutes: morningProductive ?? 0,
      eveningOverheadMinutes: eveningOverhead,
      eveningProductiveCommuteMinutes: eveningProductive ?? 0,
    };
  }

  // Legacy format — split the totals 50/50, remainder to the evening.
  const totalOverhead = json['overhead_minutes'] as number;
  const totalProductive = (json['productive_commute_minutes'] as number | null) ?? 0;
  const halfOverhead = Math.trunc(totalOverhead / 2);
  const halfProductive = Math.trunc(totalProductive / 2);
  return {
    ...base,
    morningOverheadMinutes: halfOverhead,
    morningProductiveCommuteMinutes: halfProductive,
    eveningOverheadMinutes: totalOverhead - halfOverhead,
    eveningProductiveCommuteMinutes: totalProductive - halfProductive,
  };
}

export function timeLogToJson(log: TimeLog): Record<string, unknown> {
  return {
    id: log.id ?? null,
    user_id: log.userId ?? null,
    date: log.date,
    start_time: log.startTime,
    end_time: log.endTime ?? null,
    expected_minutes: log.expectedMinutes,
    lunch_minutes: log.lunchMinutes,
    non_work_minutes: log.nonWorkMinutes,
    flex_minutes: log.flexMinutes,
    morning_overhead_minutes: log.morningOverheadMinutes,
    morning_productive_commute_minutes: log.morningProductiveCommuteMinutes,
    evening_overhead_minutes: log.eveningOverheadMinutes,
    evening_productive_commute_minutes: log.eveningProductiveCommuteMinutes,
    overhead_minutes: overheadMinutes(log),
    productive_commute_minutes: productiveCommuteMinutes(log),
    overtime_minutes: log.overtimeMinutes,
    note: log.note ?? null,
    created_at: log.createdAt ?? null,
    lunch_started_at: log.lunchStartedAt ?? null,
    non_work_started_at: log.nonWorkStartedAt ?? null,
  };
}

/** Immutable update (mirrors Dart's `copyWith`: undefined keeps the old value). */
export function copyWithTimeLog(log: TimeLog, patch: Partial<TimeLog>): TimeLog {
  return { ...log, ...patch };
}
