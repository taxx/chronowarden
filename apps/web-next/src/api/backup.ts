import { api } from './client';

export interface BackupBundle {
  format: string;
  version: number;
  exported_at: string;
  user: { email: string | null; full_name: string | null };
  envelope: {
    encrypted_dek: string;
    kek_salt: string;
    kek_iterations: number;
    recovery_hash: string | null;
  } | null;
  settings: { encrypted_data: string };
  time_logs: Array<{ date: string; encrypted_data: string }>;
  travel_presets: Array<{ name: string; encrypted_data: string }>;
}

export const backupApi = {
  export: () => api.get<BackupBundle>('/export'),
  import: (bundle: unknown) => api.post<{ imported: { time_logs: number; travel_presets: number } }>('/import', bundle),
};
