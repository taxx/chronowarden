import { useState } from 'react';
import { KeyRound, ShieldCheck, UserPlus } from 'lucide-react';

import type { Invite, User } from '../api/types';
import {
  Badge,
  Button,
  Card,
  CardContent,
  CardHeader,
  ConfirmDialog,
  Field,
  Input,
  Modal,
  Tabs,
} from '../components/ui';
import { useT } from '../i18n';
import {
  useAdminInvites,
  useAdminUsers,
  useCreateInvite,
  useDeleteInvite,
  useDeleteUser,
  useResetPassword,
  useUpdateUser,
} from '../queries/admin';
import { useToastStore } from '../state/toast';

function inviteState(invite: Invite): 'active' | 'used' | 'expired' {
  if (invite.used_at) return 'used';
  if (new Date(invite.expires_at).getTime() < Date.now()) return 'expired';
  return 'active';
}

export function AdminPage() {
  const t = useT();
  const usersQuery = useAdminUsers();
  const invitesQuery = useAdminInvites();
  const updateUser = useUpdateUser();
  const deleteUser = useDeleteUser();
  const createInvite = useCreateInvite();
  const deleteInvite = useDeleteInvite();
  const resetPassword = useResetPassword();
  const pushToast = useToastStore((state) => state.push);

  const [tab, setTab] = useState<'users' | 'invites'>('users');
  const [email, setEmail] = useState('');
  const [createdToken, setCreatedToken] = useState<string | null>(null);
  const [tempPassword, setTempPassword] = useState<{ email: string; password: string } | null>(null);
  const [confirming, setConfirming] = useState<
    { kind: 'user'; id: string } | { kind: 'invite'; id: string } | null
  >(null);

  const users = usersQuery.data ?? [];
  const invites = invitesQuery.data ?? [];

  async function run(action: () => Promise<unknown>, success?: string) {
    try {
      await action();
      if (success) pushToast(success, 'success');
    } catch {
      pushToast(t('Could not save'), 'error');
    } finally {
      setConfirming(null);
    }
  }

  return (
    <div className="space-y-4">
      <Card>
        <CardHeader
          title={t('Admin')}
          action={
            <Tabs
              value={tab}
              onChange={setTab}
              items={[
                { value: 'users', label: t('Users') },
                { value: 'invites', label: t('Invites') },
              ]}
            />
          }
        />
        <CardContent>
          {tab === 'users' ? (
            <ul className="divide-y divide-border">
              {users.map((user: User) => (
                <li key={user.id} className="flex flex-wrap items-center justify-between gap-3 py-3">
                  <div className="min-w-0">
                    <p className="truncate font-medium">{user.email}</p>
                    <div className="mt-1 flex gap-1.5">
                      <Badge variant={user.role === 'admin' ? 'default' : 'secondary'}>
                        {user.role === 'admin' ? t('Admin') : t('User')}
                      </Badge>
                      <Badge
                        variant={
                          user.status === 'approved'
                            ? 'success'
                            : user.status === 'rejected'
                              ? 'destructive'
                              : 'warning'
                        }
                      >
                        {user.status}
                      </Badge>
                    </div>
                  </div>
                  <div className="flex flex-wrap items-center gap-1">
                    {user.status !== 'approved' ? (
                      <Button
                        variant="outline"
                        size="sm"
                        onClick={() => void run(() => updateUser.mutateAsync({ id: user.id, status: 'approved' }))}
                      >
                        {t('Approve')}
                      </Button>
                    ) : null}
                    {user.status !== 'rejected' ? (
                      <Button
                        variant="outline"
                        size="sm"
                        onClick={() => void run(() => updateUser.mutateAsync({ id: user.id, status: 'rejected' }))}
                      >
                        {t('Reject')}
                      </Button>
                    ) : null}
                    <Button
                      variant="ghost"
                      size="sm"
                      onClick={() =>
                        void run(
                          () =>
                            updateUser.mutateAsync({
                              id: user.id,
                              role: user.role === 'admin' ? 'user' : 'admin',
                            }),
                          t('Saved'),
                        )
                      }
                    >
                      <ShieldCheck className="h-3.5 w-3.5" />
                      {user.role === 'admin' ? t('Make user') : t('Make admin')}
                    </Button>
                    <Button
                      variant="ghost"
                      size="sm"
                      onClick={() =>
                        void run(async () => {
                          const result = await resetPassword.mutateAsync(user.id);
                          setTempPassword({ email: result.email, password: result.temporaryPassword });
                        })
                      }
                    >
                      <KeyRound className="h-3.5 w-3.5" />
                      {t('Reset password')}
                    </Button>
                    <Button
                      variant="ghost"
                      size="sm"
                      className="text-destructive"
                      onClick={() => setConfirming({ kind: 'user', id: user.id })}
                    >
                      {t('Delete')}
                    </Button>
                  </div>
                </li>
              ))}
            </ul>
          ) : (
            <div className="space-y-4">
              <form
                className="flex flex-wrap items-end gap-2"
                onSubmit={(event) => {
                  event.preventDefault();
                  if (!email.trim()) return;
                  void run(async () => {
                    const invite = await createInvite.mutateAsync({ email: email.trim() });
                    setCreatedToken(invite.token ?? null);
                    setEmail('');
                  });
                }}
              >
                <div className="flex-1">
                  <Field label={t('Email')} htmlFor="inviteEmail">
                    <Input
                      id="inviteEmail"
                      type="email"
                      value={email}
                      onChange={(e) => setEmail(e.target.value)}
                    />
                  </Field>
                </div>
                <Button type="submit" disabled={createInvite.isPending}>
                  <UserPlus className="h-4 w-4" />
                  {t('Create invite')}
                </Button>
              </form>

              {createdToken ? (
                <div className="rounded-lg border border-input bg-background p-3">
                  <p className="text-xs text-muted-foreground">{t('Copy this token and share it with the user:')}</p>
                  <div className="mt-2 flex items-center gap-2">
                    <code className="flex-1 break-all font-mono text-sm text-warning">{createdToken}</code>
                    <Button variant="ghost" onClick={() => void navigator.clipboard.writeText(createdToken)}>
                      {t('Copy')}
                    </Button>
                  </div>
                </div>
              ) : null}

              {invites.length === 0 ? (
                <p className="text-sm text-muted-foreground">{t('No invites yet')}</p>
              ) : (
                <ul className="divide-y divide-border">
                  {invites.map((invite) => (
                    <li key={invite.id} className="flex flex-wrap items-center justify-between gap-3 py-3">
                      <div>
                        <p className="font-medium">{invite.email}</p>
                        <Badge variant={inviteState(invite) === 'active' ? 'success' : 'secondary'}>
                          {inviteState(invite) === 'used'
                            ? t('Used')
                            : inviteState(invite) === 'expired'
                              ? t('Expired')
                              : t('Active')}
                        </Badge>
                      </div>
                      <Button
                        variant="ghost"
                        size="sm"
                        className="text-destructive"
                        onClick={() => setConfirming({ kind: 'invite', id: invite.id })}
                      >
                        {t('Delete')}
                      </Button>
                    </li>
                  ))}
                </ul>
              )}
            </div>
          )}
        </CardContent>
      </Card>

      <Modal
        open={tempPassword != null}
        onClose={() => setTempPassword(null)}
        title={t('Temporary password')}
        size="sm"
        footer={
          <div className="flex justify-end gap-2">
            <Button variant="ghost" onClick={() => setTempPassword(null)}>
              {t('Close')}
            </Button>
            <Button
              onClick={() => {
                if (tempPassword) void navigator.clipboard.writeText(tempPassword.password);
              }}
            >
              {t('Copy')}
            </Button>
          </div>
        }
      >
        <p className="text-sm text-muted-foreground">
          {t('Share this temporary password with the user. Their sessions were signed out.')}
        </p>
        <code className="mt-3 block break-all rounded-lg border border-input bg-background p-3 font-mono text-sm">
          {tempPassword?.password}
        </code>
      </Modal>

      <ConfirmDialog
        open={confirming != null}
        title={t('Delete')}
        description={
          confirming?.kind === 'user'
            ? t('Permanently delete this user and all their data? This cannot be undone.')
            : t('Delete invite?')
        }
        busy={deleteUser.isPending || deleteInvite.isPending}
        onClose={() => setConfirming(null)}
        onConfirm={() => {
          if (!confirming) return;
          if (confirming.kind === 'user') {
            void run(() => deleteUser.mutateAsync(confirming.id), t('Saved'));
          } else {
            void run(() => deleteInvite.mutateAsync(confirming.id), t('Saved'));
          }
        }}
      />
    </div>
  );
}
