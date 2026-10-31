import { useQueryClient } from '@tanstack/react-query';
import { useEffect } from 'react';

import { timeLogKeys } from '../queries/time-logs';
import { subscribeRealtime } from '../services/realtime';

/**
 * Keeps the queries fresh when another device changes data. Mounted by the
 * authenticated shell.
 */
export function RealtimeBridge() {
  const queryClient = useQueryClient();

  useEffect(() => {
    return subscribeRealtime((event) => {
      if (event.table === 'time_logs') {
        void queryClient.invalidateQueries({ queryKey: timeLogKeys.all });
      }
    });
  }, [queryClient]);

  return null;
}
