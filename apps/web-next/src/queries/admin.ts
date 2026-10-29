import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';

import { adminApi } from '../api/admin';

export const adminKeys = {
  users: ['admin', 'users'] as const,
  invites: ['admin', 'invites'] as const,
};

export function useAdminUsers() {
  return useQuery({ queryKey: adminKeys.users, queryFn: adminApi.listUsers });
}

export function useUpdateUser() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: ({ id, ...body }: { id: string; status?: string; role?: string; fullName?: string }) =>
      adminApi.updateUser(id, body),
    onSuccess: () => queryClient.invalidateQueries({ queryKey: adminKeys.users }),
  });
}

export function useDeleteUser() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: (id: string) => adminApi.deleteUser(id),
    onSuccess: () => queryClient.invalidateQueries({ queryKey: adminKeys.users }),
  });
}

export function useAdminInvites() {
  return useQuery({ queryKey: adminKeys.invites, queryFn: adminApi.listInvites });
}

export function useCreateInvite() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: (body: { email: string; role?: string; ttlDays?: number }) =>
      adminApi.createInvite(body),
    onSuccess: () => queryClient.invalidateQueries({ queryKey: adminKeys.invites }),
  });
}

export function useDeleteInvite() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: (id: string) => adminApi.deleteInvite(id),
    onSuccess: () => queryClient.invalidateQueries({ queryKey: adminKeys.invites }),
  });
}
