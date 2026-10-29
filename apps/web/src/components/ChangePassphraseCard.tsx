import { useState } from 'react';
import { KeyRound } from 'lucide-react';
import { Link } from '@tanstack/react-router';

import { useT } from '../i18n';
import { useAuthStore } from '../state/auth';
import { useToastStore } from '../state/toast';
import { Button, Card, CardContent, CardHeader, Field, Input } from './ui';

/**
 * Re-wrap the DEK under a new encryption passphrase. The data itself is not
 * re-encrypted — only the envelope changes — so this is fast and safe.
 */
export function ChangePassphraseCard() {
  const t = useT();
  const dek = useAuthStore((state) => state.dek);
  const changePassphrase = useAuthStore((state) => state.changePassphrase);
  const pushToast = useToastStore((state) => state.push);

  const [newPassphrase, setNewPassphrase] = useState('');
  const [confirm, setConfirm] = useState('');
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);

  if (!dek) return null;

  async function submit() {
    setError(null);
    if (newPassphrase.length < 8) {
      setError(t('Passphrase must be at least 8 characters'));
      return;
    }
    if (newPassphrase !== confirm) {
      setError(t('Passphrases do not match'));
      return;
    }
    setBusy(true);
    try {
      await changePassphrase(newPassphrase);
      setNewPassphrase('');
      setConfirm('');
      pushToast(t('Passphrase changed'), 'success');
    } catch {
      setError(t('Could not save'));
    } finally {
      setBusy(false);
    }
  }

  return (
    <Card>
      <CardHeader
        title={
          <span className="flex items-center gap-2">
            <KeyRound className="h-4 w-4 text-primary" />
            {t('Encryption')}
          </span>
        }
        description={t('Your passphrase protects your encryption key — it never leaves this device.')}
      />
      <CardContent className="space-y-4">
        <div className="grid gap-4 sm:grid-cols-2">
          <Field label={t('New passphrase')} htmlFor="newPassphrase">
            <Input
              id="newPassphrase"
              type="password"
              autoComplete="new-password"
              value={newPassphrase}
              onChange={(event) => setNewPassphrase(event.target.value)}
            />
          </Field>
          <Field label={t('Confirm passphrase')} htmlFor="confirmPassphrase" error={error}>
            <Input
              id="confirmPassphrase"
              type="password"
              autoComplete="new-password"
              value={confirm}
              onChange={(event) => setConfirm(event.target.value)}
            />
          </Field>
        </div>
        <Button onClick={() => void submit()} disabled={busy}>
          {t('Change passphrase')}
        </Button>
        <Link to="/encryption" className="ml-3 text-sm text-primary hover:underline">
          {t('How encryption works')}
        </Link>
      </CardContent>
    </Card>
  );
}
