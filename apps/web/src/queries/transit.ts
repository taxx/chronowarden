import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';

import type { TransitConfig } from '../lib/domain/transit-config';
import { getTransitConfig, saveTransitConfig } from '../services/settings';
import { fetchJourneys, fetchStops } from '../services/transit';
import { useDek } from '../state/auth';

export const transitKeys = {
  config: ['transit', 'config'] as const,
  stops: (query: string) => ['transit', 'stops', query] as const,
  journeys: (originId: string, destId: string, walkOffset: number) =>
    ['transit', 'journeys', originId, destId, walkOffset] as const,
};

export function useTransitConfig() {
  const dek = useDek();
  return useQuery({
    queryKey: transitKeys.config,
    queryFn: () => getTransitConfig(dek),
    enabled: dek != null,
  });
}

export function useSaveTransitConfig() {
  const dek = useDek();
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: (config: TransitConfig) => {
      if (!dek) throw new Error('Encryption key is not available');
      return saveTransitConfig(config, dek);
    },
    onSuccess: () => queryClient.invalidateQueries({ queryKey: transitKeys.config }),
  });
}

export function useStopSearch(query: string) {
  return useQuery({
    queryKey: transitKeys.stops(query),
    queryFn: () => fetchStops(query),
    enabled: query.trim().length >= 2,
    staleTime: 5 * 60_000,
  });
}

export function useJourneys(params: {
  originId: string;
  destId: string;
  walkOffsetMinutes: number;
  enabled: boolean;
}) {
  return useQuery({
    queryKey: transitKeys.journeys(params.originId, params.destId, params.walkOffsetMinutes),
    queryFn: () =>
      fetchJourneys({
        originId: params.originId,
        destId: params.destId,
        walkOffsetMinutes: params.walkOffsetMinutes,
      }),
    enabled: params.enabled && params.originId !== '' && params.destId !== '',
    refetchInterval: 60_000,
  });
}
