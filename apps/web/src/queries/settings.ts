import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';

import type { WorkConfig } from '../lib/domain/work-config';
import {
  defaultPreferences,
  getPreferences,
  getWorkConfig,
  savePreferences,
  saveWorkConfig,
  type Preferences,
} from '../services/settings';
import { useDek } from '../state/auth';

export const settingsKeys = {
  workConfig: ['settings', 'work-config'] as const,
  preferences: ['settings', 'preferences'] as const,
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

export function usePreferences() {
  const dek = useDek();
  return useQuery({
    queryKey: settingsKeys.preferences,
    queryFn: () => getPreferences(dek),
    enabled: dek != null,
  });
}

export function useSavePreferences() {
  const dek = useDek();
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: (patch: Partial<Preferences>) => {
      if (!dek) throw new Error('Encryption key is not available');
      return savePreferences(patch, dek);
    },
    onSuccess: () => queryClient.invalidateQueries({ queryKey: settingsKeys.preferences }),
  });
}

export { defaultPreferences };
