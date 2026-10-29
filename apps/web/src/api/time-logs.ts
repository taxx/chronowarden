import { api } from './client';
import type { TimeLogRow } from './types';

export const timeLogsApi = {
  list: (date?: string) =>
    api.get<TimeLogRow[]>('/time-logs', date ? { date } : undefined),
  get: (id: string) => api.get<TimeLogRow>(`/time-logs/${id}`),
  create: (body: { date: string; encrypted_data: string }) =>
    api.post<TimeLogRow>('/time-logs', body),
  update: (id: string, body: { encrypted_data: string }) =>
    api.patch<TimeLogRow>(`/time-logs/${id}`, body),
  remove: (id: string) => api.delete<void>(`/time-logs/${id}`),
};
