import { api } from './client';
import type { SettingsRow } from './types';

export const settingsApi = {
  get: () => api.get<SettingsRow | null>('/settings'),

  patch: (body: {
    encrypted_data?: string;
    encrypted_dek?: string;
    kek_salt?: string;
    kek_iterations?: number;
    recovery_hash?: string | null;
  }) => api.patch<SettingsRow>('/settings', body),
};
