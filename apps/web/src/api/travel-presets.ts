import { api } from './client';
import type { TravelPresetRow } from './types';

export const travelPresetsApi = {
  list: () => api.get<TravelPresetRow[]>('/travel-presets'),
  get: (id: string) => api.get<TravelPresetRow>(`/travel-presets/${id}`),
  create: (body: { name: string; encrypted_data: string }) =>
    api.post<TravelPresetRow>('/travel-presets', body),
  update: (id: string, body: { name?: string; encrypted_data: string }) =>
    api.patch<TravelPresetRow>(`/travel-presets/${id}`, body),
  remove: (id: string) => api.delete<void>(`/travel-presets/${id}`),
};
