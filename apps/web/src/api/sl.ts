import { api } from './client';

export const slApi = {
  /** Proxy a Journey Planner `/v2/…` path through the API (slimmed). */
  proxy: <T>(path: string) => api.post<T>('/sl/proxy', { path }),
};
