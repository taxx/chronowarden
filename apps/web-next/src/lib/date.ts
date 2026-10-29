/** Local-date helpers (the app works in the user's timezone). */

/** "YYYY-MM-DD" for a Date. */
export function toDateStr(date: Date): string {
  const year = date.getFullYear();
  const month = String(date.getMonth() + 1).padStart(2, '0');
  const day = String(date.getDate()).padStart(2, '0');
  return `${year}-${month}-${day}`;
}

/** "HH:MM:SS" for a Date. */
export function toTimeStr(date: Date): string {
  const hh = String(date.getHours()).padStart(2, '0');
  const mm = String(date.getMinutes()).padStart(2, '0');
  const ss = String(date.getSeconds()).padStart(2, '0');
  return `${hh}:${mm}:${ss}`;
}

export function todayStr(): string {
  return toDateStr(new Date());
}

/** Minutes between two "HH:MM:SS" times on the same date. */
export function minutesBetween(startTime: string, endTime: string): number {
  const toMinutes = (value: string) => {
    const [h, m] = value.split(':').map(Number) as [number, number];
    return h * 60 + m;
  };
  return toMinutes(endTime) - toMinutes(startTime);
}

/** Format a Date as a local HH:MM clock time. */
export function formatClock(date: Date): string {
  return `${String(date.getHours()).padStart(2, '0')}:${String(date.getMinutes()).padStart(2, '0')}`;
}
