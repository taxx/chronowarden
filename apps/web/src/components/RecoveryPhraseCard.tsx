import { useState } from 'react';

import { useT } from '../i18n';
import { useAuthStore } from '../state/auth';
import { Button, Card } from './ui';

/**
 * Show the recovery phrase for the current DEK.
 *
 * Also refreshes the stored `recovery_hash` to the official BIP39 phrase, which
 * is the one-time migration for accounts created with the old wordlist.
 */
export function RecoveryPhraseCard() {
  const t = useT();
  const showRecoveryPhrase = useAuthStore((state) => state.showRecoveryPhrase);

  const [phrase, setPhrase] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);

  async function reveal() {
    setError(null);
    try {
      setPhrase(await showRecoveryPhrase());
    } catch {
      setError(t('Something went wrong'));
    }
  }

  return (
    <Card>
      <h2 className="text-lg font-semibold text-foreground">{t('Recovery phrase')}</h2>
      <p className="mt-1 text-sm text-muted-foreground">
        {t(
          'This is the only way to recover your encrypted data if you forget your encryption passphrase. Write it down and keep it safe.',
        )}
      </p>

      {phrase ? (
        <div
          data-testid="recovery-phrase"
          className="mt-4 break-words rounded-xl border border-input bg-background p-4 font-mono text-sm leading-7 text-amber-200"
        >
          {phrase}
        </div>
      ) : null}

      <Button className="mt-4" variant="ghost" onClick={() => void reveal()}>
        {t('Show recovery phrase')}
      </Button>

      {error ? <p className="mt-3 text-sm text-destructive">{error}</p> : null}
    </Card>
  );
}
