import { Link, useNavigate } from '@tanstack/react-router';
import { useState, type FormEvent } from 'react';

import { Button, Card, Field, Input, Spinner } from '../components/ui';
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
    <div className="grid min-h-dvh place-items-center p-6">
      <Card className="w-full max-w-md">
        <h1 className="text-xl font-semibold text-white">{t('Sign in')}</h1>

        <form className="mt-6 space-y-4" onSubmit={onSubmit}>
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
              className="text-sm text-sky-400 hover:text-sky-300"
              onClick={() => setShowPassphrase(true)}
            >
              {t('I have an encryption passphrase')}
            </button>
          )}

          {localError || storeError ? (
            <p className="text-sm text-red-400">{localError ?? storeError}</p>
          ) : null}

          <Button type="submit" disabled={busy} className="w-full">
            {busy ? <Spinner /> : t('Sign in')}
          </Button>
        </form>

        <div className="mt-4 text-center">
          <Link to="/register" className="text-sm text-sky-400 hover:text-sky-300">
            {t('Have an invite?')}
          </Link>
        </div>
      </Card>
    </div>
  );
}
