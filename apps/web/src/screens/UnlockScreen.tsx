import { Link, useNavigate } from '@tanstack/react-router';
import { useState, type FormEvent } from 'react';

import { Button, Card, Field, Input, Spinner } from '../components/ui';
import { useT } from '../i18n';
import { useAuthStore } from '../state/auth';

export function UnlockScreen() {
  const t = useT();
  const navigate = useNavigate();
  const unlock = useAuthStore((state) => state.unlock);
  const storeError = useAuthStore((state) => state.error);
  const clearError = useAuthStore((state) => state.clearError);

  const [passphrase, setPassphrase] = useState('');
  const [busy, setBusy] = useState(false);

  async function onSubmit(event: FormEvent) {
    event.preventDefault();
    clearError();
    setBusy(true);
    try {
      await unlock(passphrase);
      await navigate({ to: '/' });
    } catch {
      // The store holds the error message.
    } finally {
      setBusy(false);
    }
  }

  return (
    <div className="grid min-h-dvh place-items-center p-6">
      <Card className="w-full max-w-md">
        <h1 className="text-xl font-semibold text-foreground">{t('Unlock')}</h1>
        <p className="mt-1 text-sm text-muted-foreground">
          {t('Your data is encrypted. Enter your encryption passphrase to unlock it.')}
        </p>

        <form className="mt-6 space-y-4" onSubmit={onSubmit}>
          <Field label={t('Encryption passphrase')} htmlFor="passphrase">
            <Input
              id="passphrase"
              type="password"
              value={passphrase}
              onChange={(e) => setPassphrase(e.target.value)}
              autoComplete="current-password"
            />
          </Field>

          {storeError ? <p className="text-sm text-destructive">{storeError}</p> : null}

          <Button type="submit" disabled={busy} className="w-full">
            {busy ? <Spinner /> : t('Unlock')}
          </Button>
        </form>

        <div className="mt-4 text-center">
          <Link to="/recover" className="text-sm text-primary hover:text-primary">
            {t('Forgot passphrase?')}
          </Link>
        </div>
      </Card>
    </div>
  );
}
