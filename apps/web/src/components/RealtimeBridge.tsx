import { useQueryClient } from '@tanstack/react-query';
import { useEffect } from 'react';

import { timeLogKeys } from '../queries/time-logs';
import { subscribeRealtime } from '../services/realtime';

/** Only refetch after a meaningful absence, not every tab switch. */
const WAKE_REFRESH_AFTER_MS = 30_000;

/**
 * Keeps the queries fresh when another device changes data. Mounted by the
 * authenticated shell.
 *
 * Besides reacting to live events, it refetches once when the tab becomes
 * visible again after a while and when the SSE stream reconnects. That covers
 * a device that was asleep while another one ended the day: any events sent
 * during the sleep are gone, so the client has to pull the current state.
 */
export function RealtimeBridge() {
  const queryClient = useQueryClient();

  useEffect(() => {
    const invalidate = () => {
      void queryClient.invalidateQueries({ queryKey: timeLogKeys.all });
    };

    const unsubscribe = subscribeRealtime((event) => {
      if (event.table === 'time_logs') invalidate();
    }, invalidate);

    let hiddenAt: number | null = null;
    const onVisibilityChange = () => {
      if (document.visibilityState === 'hidden') {
        hiddenAt = Date.now();
        return;
      }
      if (hiddenAt != null && Date.now() - hiddenAt > WAKE_REFRESH_AFTER_MS) {
        hiddenAt = null;
        invalidate();
      }
    };
    document.addEventListener('visibilitychange', onVisibilityChange);

    return () => {
      unsubscribe();
      document.removeEventListener('visibilitychange', onVisibilityChange);
    };
  }, [queryClient]);

  return null;
}
