import { useNavigate } from '@tanstack/react-router';

import { Button, Card } from '../components/ui';
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
    <div className="grid min-h-dvh place-items-center p-6">
      <Card className="w-full max-w-lg">
        <h1 className="text-xl font-semibold text-white">{t('Your recovery phrase')}</h1>
        <p className="mt-1 text-sm text-slate-400">
          {t(
            'This is the only way to recover your encrypted data if you forget your encryption passphrase. Write it down and keep it safe.',
          )}
        </p>

        <div
          data-testid="recovery-phrase"
          className="mt-5 rounded-xl border border-slate-700 bg-slate-950 p-4 font-mono text-sm leading-7 text-amber-200"
        >
          {phrase}
        </div>

        <Button className="mt-6 w-full" onClick={onContinue}>
          {t('I have saved my recovery phrase')}
        </Button>
      </Card>
    </div>
  );
}
