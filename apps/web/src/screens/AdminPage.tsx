import { useState } from 'react';

import type { Invite, User } from '../api/types';
import { Button, Card, Field, Input, Spinner } from '../components/ui';
import { useT } from '../i18n';
import {
  useAdminInvites,
  useAdminUsers,
  useCreateInvite,
  useDeleteInvite,
  useDeleteUser,
  useUpdateUser,
} from '../queries/admin';

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

  const [tab, setTab] = useState<'users' | 'invites'>('users');
  const [email, setEmail] = useState('');
  const [createdToken, setCreatedToken] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);

  const users = usersQuery.data ?? [];
  const invites = invitesQuery.data ?? [];

  async function run(action: () => Promise<unknown>) {
    setError(null);
    try {
      await action();
    } catch {
      setError(t('Could not save'));
    }
  }

  return (
    <div className="space-y-4">
      <Card>
        <div className="flex gap-2">
          <Button variant={tab === 'users' ? 'primary' : 'ghost'} onClick={() => setTab('users')}>
            {t('Users')}
          </Button>
          <Button variant={tab === 'invites' ? 'primary' : 'ghost'} onClick={() => setTab('invites')}>
            {t('Invites')}
          </Button>
        </div>

        {tab === 'users' ? (
          usersQuery.isLoading ? (
            <div className="flex justify-center py-8">
              <Spinner />
            </div>
          ) : (
            <ul className="mt-4 divide-y divide-border">
              {users.map((user: User) => (
                <li key={user.id} className="flex flex-wrap items-center justify-between gap-3 py-3">
                  <div>
                    <p className="font-medium text-foreground">{user.email}</p>
                    <p className="text-xs text-muted-foreground">
                      {user.role} · {user.status}
                    </p>
                  </div>
                  <div className="flex items-center gap-2">
                    {user.status !== 'approved' ? (
                      <Button
                        variant="ghost"
                        onClick={() => void run(() => updateUser.mutateAsync({ id: user.id, status: 'approved' }))}
                      >
                        {t('Approve')}
                      </Button>
                    ) : null}
                    {user.status !== 'rejected' ? (
                      <Button
                        variant="ghost"
                        onClick={() => void run(() => updateUser.mutateAsync({ id: user.id, status: 'rejected' }))}
                      >
                        {t('Reject')}
                      </Button>
                    ) : null}
                    <Button
                      variant="ghost"
                      onClick={() => {
                        if (window.confirm(t('Delete user?'))) {
                          void run(() => deleteUser.mutateAsync(user.id));
                        }
                      }}
                    >
                      {t('Delete')}
                    </Button>
                  </div>
                </li>
              ))}
            </ul>
          )
        ) : (
          <div className="mt-4 space-y-4">
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
                {t('Create invite')}
              </Button>
            </form>

            {createdToken ? (
              <div className="rounded-lg border border-input bg-background p-3">
                <p className="text-xs text-muted-foreground">{t('Copy this token and share it with the user:')}</p>
                <div className="mt-2 flex items-center gap-2">
                  <code className="flex-1 break-all font-mono text-sm text-amber-200">{createdToken}</code>
                  <Button
                    variant="ghost"
                    onClick={() => void navigator.clipboard.writeText(createdToken)}
                  >
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
                      <p className="font-medium text-foreground">{invite.email}</p>
                      <p className="text-xs text-muted-foreground">
                        {inviteState(invite) === 'used'
                          ? t('Used')
                          : inviteState(invite) === 'expired'
                            ? t('Expired')
                            : t('Active')}
                      </p>
                    </div>
                    <Button
                      variant="ghost"
                      onClick={() => {
                        if (window.confirm(t('Delete invite?'))) {
                          void run(() => deleteInvite.mutateAsync(invite.id));
                        }
                      }}
                    >
                      {t('Delete')}
                    </Button>
                  </li>
                ))}
              </ul>
            )}
          </div>
        )}

        {error ? <p className="mt-3 text-sm text-destructive">{error}</p> : null}
      </Card>
    </div>
  );
}
