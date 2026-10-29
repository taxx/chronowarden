import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';

import type { TravelPreset } from '../lib/domain/travel-preset';
import {
  createTravelPreset,
  deleteTravelPreset,
  listTravelPresets,
  updateTravelPreset,
} from '../services/travel-presets';
import { useDek } from '../state/auth';

export const presetKeys = {
  all: ['travel-presets'] as const,
};

export function useTravelPresets() {
  const dek = useDek();
  return useQuery({
    queryKey: presetKeys.all,
    queryFn: () => listTravelPresets(dek),
    enabled: dek != null,
  });
}

export function useCreateTravelPreset() {
  const dek = useDek();
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: (preset: TravelPreset) => {
      if (!dek) throw new Error('Encryption key is not available');
      return createTravelPreset(preset, dek);
    },
    onSuccess: () => queryClient.invalidateQueries({ queryKey: presetKeys.all }),
  });
}

export function useUpdateTravelPreset() {
  const dek = useDek();
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: ({ id, fields }: { id: string; fields: Record<string, unknown> }) => {
      if (!dek) throw new Error('Encryption key is not available');
      return updateTravelPreset(id, fields, dek);
    },
    onSuccess: () => queryClient.invalidateQueries({ queryKey: presetKeys.all }),
  });
}

export function useDeleteTravelPreset() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: (id: string) => deleteTravelPreset(id),
    onSuccess: () => queryClient.invalidateQueries({ queryKey: presetKeys.all }),
  });
}
