import { Link, useNavigate } from '@tanstack/react-router';
import { useState, type FormEvent } from 'react';

import { AuthCard } from '../components/AuthCard';
import { Button, Field, Input, Spinner } from '../components/ui';
import { useT } from '../i18n';
import { useAuthStore } from '../state/auth';

export function LoginScreen() {
  const t = useT();
  const navigate = useNavigate();
  const login = useAuthStore((state) => state.login);
  const unlock = useAuthStore((state) => state.unlock);
  const storeError = useAuthStore((state) => state.error);
  const clearError = useAuthStore((state) => state.clearError);

  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [passphrase, setPassphrase] = useState('');
  const [showPassphrase, setShowPassphrase] = useState(false);
  const [localError, setLocalError] = useState<string | null>(null);
  const [busy, setBusy] = useState(false);

  async function onSubmit(event: FormEvent) {
    event.preventDefault();
    clearError();
    setLocalError(null);
    if (!email.trim()) return setLocalError(t('Email is required'));

    setBusy(true);
    try {
      await login(email, password);

      if (showPassphrase && passphrase) {
        await unlock(passphrase);
      }

      const status = useAuthStore.getState().status;
      await navigate({ to: status === 'ready' ? '/' : '/passphrase' });
    } catch {
      // The store holds the error message.
    } finally {
      setBusy(false);
    }
  }

  return (
    <AuthCard
      title={t('Sign in')}
      footer={
        <Link to="/register" className="text-sm text-primary hover:underline">
          {t('Have an invite?')}
        </Link>
      }
    >
      <form className="space-y-4" onSubmit={onSubmit}>
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
            autoComplete="current-password"
          />
        </Field>

        {showPassphrase ? (
          <Field label={t('Encryption passphrase')} htmlFor="passphrase">
            <Input
              id="passphrase"
              type="password"
              value={passphrase}
              onChange={(e) => setPassphrase(e.target.value)}
              autoComplete="current-password"
            />
          </Field>
        ) : (
          <button
            type="button"
            className="text-sm text-primary hover:underline"
            onClick={() => setShowPassphrase(true)}
          >
            {t('I have an encryption passphrase')}
          </button>
        )}

        {localError || storeError ? (
          <p className="text-sm text-destructive">{localError ?? storeError}</p>
        ) : null}

        <Button type="submit" disabled={busy} className="w-full">
          {busy ? <Spinner /> : t('Sign in')}
        </Button>
      </form>
    </AuthCard>
  );
}
