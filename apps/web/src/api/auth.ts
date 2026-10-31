import { api } from './client';
import type { SessionResponse, StateResponse, User } from './types';

export const authApi = {
  state: () => api.get<StateResponse>('/state'),

  me: () => api.get<User>('/me'),

  setup: (body: { email: string; password: string; fullName: string }) =>
    api.post<SessionResponse>('/auth/setup', body),

  register: (body: {
    email: string;
    password: string;
    fullName: string;
    inviteToken: string;
  }) => api.post<SessionResponse>('/auth/register', body),

  login: (body: { email: string; password: string }) =>
    api.post<SessionResponse>('/auth/login', body),

  logout: () => api.post<{ ok: boolean }>('/auth/logout'),

  validateInvite: (token: string) =>
    api.post<{ valid: boolean; email?: string; reason?: string }>('/invites/validate', { token }),

  changePassword: (body: { currentPassword: string; newPassword: string }) =>
    api.patch<{ ok: boolean }>('/me/password', body),
};
