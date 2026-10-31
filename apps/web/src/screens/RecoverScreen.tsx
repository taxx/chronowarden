import { useNavigate } from '@tanstack/react-router';
import { useState, type FormEvent } from 'react';

import { AuthCard } from '../components/AuthCard';
import { Button, Field, Input, Spinner, Textarea } from '../components/ui';
import { useT } from '../i18n';
import { useAuthStore } from '../state/auth';

/** Recover the DEK from the recovery phrase and set a new encryption passphrase. */
export function RecoverScreen() {
  const t = useT();
  const navigate = useNavigate();
  const recover = useAuthStore((state) => state.recoverAndSetPassphrase);
  const storeError = useAuthStore((state) => state.error);
  const clearError = useAuthStore((state) => state.clearError);

  const [phrase, setPhrase] = useState('');
  const [newPassphrase, setNewPassphrase] = useState('');
  const [confirm, setConfirm] = useState('');
  const [localError, setLocalError] = useState<string | null>(null);
  const [busy, setBusy] = useState(false);

  async function onSubmit(event: FormEvent) {
    event.preventDefault();
    clearError();
    setLocalError(null);

    if (!phrase.trim()) return setLocalError(t('Recovery phrase is required'));
    if (newPassphrase.length < 8) {
      return setLocalError(t('Encryption passphrase must be at least 8 characters'));
    }
    if (newPassphrase !== confirm) {
      return setLocalError(t('Encryption passphrases do not match'));
    }

    setBusy(true);
    try {
      await recover(phrase, newPassphrase);
      await navigate({ to: '/' });
    } catch {
      // The store holds the error message.
    } finally {
      setBusy(false);
    }
  }

  return (
    <AuthCard
      title={t('Recover access')}
      description={t(
        'This is the only way to recover your encrypted data if you forget your encryption passphrase. Write it down and keep it safe.',
      )}
      width="max-w-lg"
    >
      <form className="space-y-4" onSubmit={onSubmit}>
        <Field label={t('Enter your recovery phrase')} htmlFor="phrase">
          <Textarea
            id="phrase"
            className="h-24 font-mono text-sm"
            value={phrase}
            onChange={(event) => setPhrase(event.target.value)}
          />
        </Field>
        <Field label={t('New encryption passphrase')} htmlFor="newPassphrase">
          <Input
            id="newPassphrase"
            type="password"
            value={newPassphrase}
            onChange={(event) => setNewPassphrase(event.target.value)}
            autoComplete="new-password"
          />
        </Field>
        <Field label={t('Confirm encryption passphrase')} htmlFor="confirm">
          <Input
            id="confirm"
            type="password"
            value={confirm}
            onChange={(event) => setConfirm(event.target.value)}
            autoComplete="new-password"
          />
        </Field>

        {localError || storeError ? (
          <p className="text-sm text-destructive">{localError ?? storeError}</p>
        ) : null}

        <Button type="submit" disabled={busy} className="w-full">
          {busy ? <Spinner /> : t('Recover access')}
        </Button>
      </form>
    </AuthCard>
  );
}
