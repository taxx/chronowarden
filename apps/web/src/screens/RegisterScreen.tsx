import { useNavigate } from '@tanstack/react-router';
import { useState, type FormEvent } from 'react';

import { authApi } from '../api/auth';
import { AuthCard } from '../components/AuthCard';
import { Button, Field, Input, Spinner } from '../components/ui';
import { useT } from '../i18n';
import { useAuthStore } from '../state/auth';

export function RegisterScreen() {
  const t = useT();
  const navigate = useNavigate();
  const register = useAuthStore((state) => state.register);
  const storeError = useAuthStore((state) => state.error);
  const clearError = useAuthStore((state) => state.clearError);

  const [token, setToken] = useState('');
  const [email, setEmail] = useState('');
  const [fullName, setFullName] = useState('');
  const [password, setPassword] = useState('');
  const [passphrase, setPassphrase] = useState('');
  const [confirm, setConfirm] = useState('');
  const [checking, setChecking] = useState(false);
  const [inviteError, setInviteError] = useState<string | null>(null);
  const [localError, setLocalError] = useState<string | null>(null);
  const [busy, setBusy] = useState(false);

  /** Prefill the (email-bound) address once the invite validates. */
  async function checkInvite() {
    const value = token.trim();
    if (!value) return;
    setChecking(true);
    setInviteError(null);
    try {
      const result = await authApi.validateInvite(value);
      if (result.valid && result.email) {
        setEmail(result.email);
      } else {
        setInviteError(t('Invalid or expired invite token'));
      }
    } catch {
      setInviteError(t('Invalid or expired invite token'));
    } finally {
      setChecking(false);
    }
  }

  async function onSubmit(event: FormEvent) {
    event.preventDefault();
    clearError();
    setLocalError(null);

    if (!token.trim()) return setInviteError(t('Invalid or expired invite token'));
    if (!email.trim()) return setLocalError(t('Email is required'));
    if (password.length < 10) return setLocalError(t('Password must be at least 10 characters'));
    if (passphrase.length < 8) {
      return setLocalError(t('Encryption passphrase must be at least 8 characters'));
    }
    if (passphrase !== confirm) return setLocalError(t('Encryption passphrases do not match'));

    setBusy(true);
    try {
      await register({
        email,
        password,
        fullName,
        inviteToken: token.trim(),
        encryptionPassphrase: passphrase,
      });
      await navigate({ to: '/recovery' });
    } catch {
      // The store holds the error message.
    } finally {
      setBusy(false);
    }
  }

  return (
    <AuthCard brand title={t('Create account')}>
      <form className="space-y-4" onSubmit={onSubmit}>
        <Field label={t('Invite token')} htmlFor="inviteToken" error={inviteError}>
          <div className="flex items-center gap-2">
            <Input
              id="inviteToken"
              value={token}
              onChange={(e) => setToken(e.target.value)}
              onBlur={() => void checkInvite()}
            />
            {checking ? <Spinner /> : null}
          </div>
          <p className="text-xs text-muted-foreground">{t('Ask your administrator for an invite token')}</p>
        </Field>

        <Field label={t('Full name')} htmlFor="fullName">
          <Input id="fullName" value={fullName} onChange={(e) => setFullName(e.target.value)} />
        </Field>
        <Field label={t('Email')} htmlFor="email">
          <Input
            id="email"
            type="email"
            value={email}
            onChange={(e) => setEmail(e.target.value)}
            autoComplete="email"
          />
        </Field>
        <Field label={t('Password')} htmlFor="password">
          <Input
            id="password"
            type="password"
            value={password}
            onChange={(e) => setPassword(e.target.value)}
            autoComplete="new-password"
          />
        </Field>
        <Field label={t('Encryption passphrase')} htmlFor="passphrase">
          <Input
            id="passphrase"
            type="password"
            value={passphrase}
            onChange={(e) => setPassphrase(e.target.value)}
            autoComplete="new-password"
          />
        </Field>
        <Field label={t('Confirm encryption passphrase')} htmlFor="confirm">
          <Input
            id="confirm"
            type="password"
            value={confirm}
            onChange={(e) => setConfirm(e.target.value)}
            autoComplete="new-password"
          />
        </Field>

        {localError || storeError ? (
          <p className="text-sm text-destructive">{localError ?? storeError}</p>
        ) : null}

        <Button type="submit" disabled={busy} className="w-full">
          {busy ? <Spinner /> : t('Create account')}
        </Button>
      </form>
    </AuthCard>
  );
}
