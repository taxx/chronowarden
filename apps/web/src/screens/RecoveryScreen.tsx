import { useNavigate } from '@tanstack/react-router';

import { AuthCard } from '../components/AuthCard';
import { Button } from '../components/ui';
import { useT } from '../i18n';
import { useAuthStore } from '../state/auth';

export function RecoveryScreen() {
  const t = useT();
  const navigate = useNavigate();
  const phrase = useAuthStore((state) => state.pendingRecoveryPhrase);
  const clear = useAuthStore((state) => state.clearPendingRecoveryPhrase);

  async function onContinue() {
    clear();
    await navigate({ to: '/' });
  }

  return (
    <AuthCard
      title={t('Your recovery phrase')}
      description={t(
        'This is the only way to recover your encrypted data if you forget your encryption passphrase. Write it down and keep it safe.',
      )}
      width="max-w-lg"
    >
      <div
        data-testid="recovery-phrase"
        className="rounded-xl border border-input bg-background p-4 font-mono text-sm leading-7 text-warning"
      >
        {phrase}
      </div>

      <Button className="mt-6 w-full" onClick={onContinue}>
        {t('I have saved my recovery phrase')}
      </Button>
    </AuthCard>
  );
}
