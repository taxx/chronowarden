import { api } from './client';
import type { Invite, User } from './types';

export const adminApi = {
  listUsers: () => api.get<User[]>('/admin/users'),
  updateUser: (id: string, body: { status?: string; role?: string; fullName?: string }) =>
    api.patch<User>(`/admin/users/${id}`, body),
  deleteUser: (id: string) => api.delete<void>(`/admin/users/${id}`),
  resetPassword: (id: string) =>
    api.post<{ email: string; temporaryPassword: string }>(`/admin/users/${id}/reset-password`),

  listInvites: () => api.get<Invite[]>('/admin/invites'),
  createInvite: (body: { email: string; role?: string; ttlDays?: number }) =>
    api.post<Invite>('/admin/invites', body),
  deleteInvite: (id: string) => api.delete<void>(`/admin/invites/${id}`),
};
