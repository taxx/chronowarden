/**
 * Shared formatting helpers for minute values.
 *
 * Ported from `apps/web/lib/utils/format.dart`. All values are plain `number`
 * minutes — conversion to display strings belongs here.
 */

/** Unsigned magnitude: `45 min`, `8h 30m`, `8h`. */
export function formatMins(minutes: number): string {
  const abs = Math.abs(minutes);
  const h = Math.floor(abs / 60);
  const m = abs % 60;
  if (h === 0) return `${m} min`;
  if (m === 0) return `${h}h`;
  return `${h}h ${m}m`;
}

/** Signed duration without a leading `+`: `8h 30m`, `-45 min`, `0 min`. */
export function formatDurationMinutes(minutes: number): string {
  if (minutes === 0) return '0 min';
  const sign = minutes < 0 ? '-' : '';
  const abs = Math.abs(minutes);
  const h = Math.floor(abs / 60);
  const m = abs % 60;
  if (h === 0) return `${sign}${m} min`;
  if (m === 0) return `${sign}${h}h`;
  return `${sign}${h}h ${m}m`;
}

/** Signed balance with an explicit `+` for non-negative values. */
export function formatSignedMinutes(minutes: number): string {
  const sign = minutes >= 0 ? '+' : '-';
  const abs = Math.abs(minutes);
  const h = Math.floor(abs / 60);
  const m = abs % 60;
  if (h === 0) return `${sign}${m} min`;
  if (m === 0) return `${sign}${h}h`;
  return `${sign}${h}h ${m}m`;
}

/** Overtime status chip label: `✓` when exactly on target, else the balance. */
export function formatOvertimeStatus(minutes: number): string {
  return minutes === 0 ? '✓' : formatSignedMinutes(minutes);
}

/**
 * Time-warding tone for an overtime / balance value.
 *
 * ChronoWarden's job is to protect the user's time, so working **less** than
 * expected (a negative overtime) is the good outcome — green — while working
 * **more** (a positive overtime) is what we flag — red. Zero is neutral.
 */
export type OvertimeTone = 'success' | 'warning' | 'neutral';

export function overtimeTone(minutes: number): OvertimeTone {
  if (minutes < 0) return 'success';
  if (minutes > 0) return 'warning';
  return 'neutral';
}

/** Tailwind text colour class for an overtime value. */
export function overtimeTextClass(minutes: number): string {
  const tone = overtimeTone(minutes);
  if (tone === 'success') return 'text-success';
  if (tone === 'warning') return 'text-warning';
  return 'text-muted-foreground';
}

/** Badge variant for an overtime value. */
export function overtimeBadgeVariant(minutes: number): 'success' | 'warning' | 'secondary' {
  const tone = overtimeTone(minutes);
  if (tone === 'success') return 'success';
  if (tone === 'warning') return 'warning';
  return 'secondary';
}
