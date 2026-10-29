import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';

import type { TimeLog } from '../lib/domain/time-log';
import {
  createTimeLog,
  deleteTimeLog,
  listTimeLogs,
  todayTimeLog,
  updateTimeLog,
  type TimeLogPatch,
} from '../services/time-logs';
import { useDek } from '../state/auth';

export const timeLogKeys = {
  all: ['time-logs'] as const,
  today: ['time-logs', 'today'] as const,
};

export function useTimeLogs() {
  const dek = useDek();
  return useQuery({
    queryKey: timeLogKeys.all,
    queryFn: () => listTimeLogs(dek),
    enabled: dek != null,
  });
}

export function useTodayLog() {
  const dek = useDek();
  return useQuery({
    queryKey: timeLogKeys.today,
    queryFn: () => todayTimeLog(dek),
    enabled: dek != null,
  });
}

export function useCreateTimeLog() {
  const dek = useDek();
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: (log: TimeLog) => {
      if (!dek) throw new Error('Encryption key is not available');
      return createTimeLog(log, dek);
    },
    onSuccess: () => queryClient.invalidateQueries({ queryKey: timeLogKeys.all }),
  });
}

export function useUpdateTimeLog() {
  const dek = useDek();
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: ({ id, fields }: { id: string; fields: TimeLogPatch }) => {
      if (!dek) throw new Error('Encryption key is not available');
      return updateTimeLog(id, fields, dek);
    },
    onSuccess: () => queryClient.invalidateQueries({ queryKey: timeLogKeys.all }),
  });
}

export function useDeleteTimeLog() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: (id: string) => deleteTimeLog(id),
    onSuccess: () => queryClient.invalidateQueries({ queryKey: timeLogKeys.all }),
  });
}
