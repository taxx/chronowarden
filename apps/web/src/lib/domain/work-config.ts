/**
 * Per-user work-time configuration.
 *
 * Ported from `apps/web/lib/models/work_config.dart` (same behaviour and tests).
 */
export interface WorkConfig {
  userId?: string | null;
  defaultExpectedMinutes: number;
  reducedExpectedMinutes?: number | null;
  reducedStartWeek?: number | null;
  reducedEndWeek?: number | null;
}

export function hasReducedPeriod(config: WorkConfig): boolean {
  return (
    config.reducedExpectedMinutes != null &&
    config.reducedStartWeek != null &&
    config.reducedEndWeek != null
  );
}

/**
 * ISO week number for a date (1–53).
 *
 * The week containing the first Thursday of the year is week 1. All arithmetic
 * is done in UTC so DST transitions (Europe/Sweden) can never skew the count —
 * the original Dart bug this guards against.
 *
 * Uses the *local* calendar date of `date` (matching the Dart implementation),
 * then computes in UTC.
 */
export function isoWeekNumber(date: Date): number {
  const d = new Date(Date.UTC(date.getFullYear(), date.getMonth(), date.getDate()));
  const weekday = (d.getUTCDay() + 6) % 7 + 1; // 1=Mon … 7=Sun

  // Thursday of the ISO week (Mon–Sun) containing d.
  const thursday = new Date(
    Date.UTC(d.getUTCFullYear(), d.getUTCMonth(), d.getUTCDate() + (((4 - weekday + 3) % 7) - 3)),
  );

  const year = thursday.getUTCFullYear();
  const jan1 = new Date(Date.UTC(year, 0, 1));
  const jan1Weekday = ((jan1.getUTCDay() + 6) % 7) + 1; // 1=Mon … 7=Sun
  const firstThursday = new Date(Date.UTC(year, 0, 1 + ((4 - jan1Weekday + 7) % 7)));

  const days = (thursday.getTime() - firstThursday.getTime()) / 86_400_000;
  return Math.floor(days / 7) + 1;
}

/** Expected minutes for a date, honouring the reduced (seasonal) period. */
export function expectedMinutesForDate(config: WorkConfig, date: Date): number {
  if (hasReducedPeriod(config)) {
    const week = isoWeekNumber(date);
    if (week >= config.reducedStartWeek! && week <= config.reducedEndWeek!) {
      return config.reducedExpectedMinutes!;
    }
  }
  return config.defaultExpectedMinutes;
}

export function workConfigFromJson(json: Record<string, unknown>): WorkConfig {
  return {
    userId: (json['user_id'] as string | null) ?? null,
    defaultExpectedMinutes: (json['default_expected_minutes'] as number | null) ?? 480,
    reducedExpectedMinutes: (json['reduced_expected_minutes'] as number | null) ?? null,
    reducedStartWeek: (json['reduced_start_week'] as number | null) ?? null,
    reducedEndWeek: (json['reduced_end_week'] as number | null) ?? null,
  };
}

export function workConfigToJson(config: WorkConfig): Record<string, unknown> {
  return {
    user_id: config.userId ?? null,
    default_expected_minutes: config.defaultExpectedMinutes,
    reduced_expected_minutes: config.reducedExpectedMinutes ?? null,
    reduced_start_week: config.reducedStartWeek ?? null,
    reduced_end_week: config.reducedEndWeek ?? null,
  };
}
