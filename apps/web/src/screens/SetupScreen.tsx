import { useNavigate } from '@tanstack/react-router';
import { useState, type FormEvent } from 'react';

import { Button, Card, Field, Input, Spinner } from '../components/ui';
import { useT } from '../i18n';
import { useAuthStore } from '../state/auth';

export function SetupScreen() {
  const t = useT();
  const navigate = useNavigate();
  const setup = useAuthStore((state) => state.setup);
  const storeError = useAuthStore((state) => state.error);
  const clearError = useAuthStore((state) => state.clearError);

  const [fullName, setFullName] = useState('');
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [passphrase, setPassphrase] = useState('');
  const [confirm, setConfirm] = useState('');
  const [localError, setLocalError] = useState<string | null>(null);
  const [busy, setBusy] = useState(false);

  async function onSubmit(event: FormEvent) {
    event.preventDefault();
    clearError();
    setLocalError(null);

    if (!email.trim()) return setLocalError(t('Email is required'));
    if (password.length < 10) return setLocalError(t('Password must be at least 10 characters'));
    if (passphrase.length < 8) {
      return setLocalError(t('Encryption passphrase must be at least 8 characters'));
    }
    if (passphrase !== confirm) return setLocalError(t('Encryption passphrases do not match'));

    setBusy(true);
    try {
      await setup({ email, password, fullName, encryptionPassphrase: passphrase });
      await navigate({ to: '/recovery' });
    } catch {
      // The store holds the error message.
    } finally {
      setBusy(false);
    }
  }

  return (
    <div className="grid min-h-dvh place-items-center p-6">
      <Card className="w-full max-w-md">
        <h1 className="text-xl font-semibold text-white">{t('First-time setup')}</h1>
        <p className="mt-1 text-sm text-slate-400">
          {t('You are the first user. This account will be an administrator.')}
        </p>

        <form className="mt-6 space-y-4" onSubmit={onSubmit}>
          <Field label={t('Full name')} htmlFor="fullName">
            <Input
              id="fullName"
              value={fullName}
              onChange={(e) => setFullName(e.target.value)}
              autoComplete="name"
            />
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
            <p className="text-sm text-red-400">{localError ?? storeError}</p>
          ) : null}

          <Button type="submit" disabled={busy} className="w-full">
            {busy ? <Spinner /> : t('Create admin account')}
          </Button>
        </form>
      </Card>
    </div>
  );
}
