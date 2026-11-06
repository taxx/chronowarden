import { useEffect, useState } from 'react';

import { leaveTimeWithBreaks } from '../lib/domain/time-log';
import { useTodayLog } from '../queries/time-logs';
import { useNotificationsStore } from '../state/notifications';

/**
 * Watches the projected leave time and feeds the alert evaluator.
 *
 * Lives in the app shell (not on a single page) so alerts keep firing while the
 * user is on any screen. Browsers clamp hidden-tab timers, so we slow the tick
 * down when hidden and re-check immediately on `visibilitychange`.
 */
function minutesSince(iso: string, now: Date): number {
  return Math.max(0, Math.round((now.getTime() - new Date(iso).getTime()) / 60_000));
}

function tickIntervalMs(): number {
  if (typeof document === 'undefined') return 1000;
  return document.visibilityState === 'visible' ? 1000 : 30_000;
}

export function NotificationWatcher() {
  const today = useTodayLog().data ?? null;
  const check = useNotificationsStore((state) => state.check);
  const [now, setNow] = useState(() => new Date());

  useEffect(() => {
    let id = window.setInterval(() => setNow(new Date()), tickIntervalMs());

    const onVisibilityChange = () => {
      window.clearInterval(id);
      id = window.setInterval(() => setNow(new Date()), tickIntervalMs());
      // Re-evaluate right away instead of waiting for the next tick.
      setNow(new Date());
    };

    document.addEventListener('visibilitychange', onVisibilityChange);
    return () => {
      window.clearInterval(id);
      document.removeEventListener('visibilitychange', onVisibilityChange);
    };
  }, []);

  useEffect(() => {
    if (!today || today.endTime != null) return;

    const lunchActive =
      today.lunchStartedAt != null
        ? Math.max(today.lunchMinutes, minutesSince(today.lunchStartedAt, now))
        : today.lunchMinutes;
    const nonWorkActive =
      today.nonWorkStartedAt != null
        ? Math.max(today.nonWorkMinutes, minutesSince(today.nonWorkStartedAt, now))
        : today.nonWorkMinutes;

    const leave = leaveTimeWithBreaks(today, {
      lunchMinutes: lunchActive,
      nonWorkMinutes: nonWorkActive,
    });
    check((leave.getTime() - now.getTime()) / 60_000, now);
  }, [now, today, check]);

  return null;
}
