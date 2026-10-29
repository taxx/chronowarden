import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';

import type { WorkConfig } from '../lib/domain/work-config';
import { getWorkConfig, saveWorkConfig } from '../services/settings';
import { useDek } from '../state/auth';

export const settingsKeys = {
  workConfig: ['settings', 'work-config'] as const,
};

export function useWorkConfig() {
  const dek = useDek();
  return useQuery({
    queryKey: settingsKeys.workConfig,
    queryFn: () => getWorkConfig(dek),
    enabled: dek != null,
  });
}

export function useSaveWorkConfig() {
  const dek = useDek();
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: (config: WorkConfig) => {
      if (!dek) throw new Error('Encryption key is not available');
      return saveWorkConfig(config, dek);
    },
    onSuccess: () => queryClient.invalidateQueries({ queryKey: settingsKeys.workConfig }),
  });
}
