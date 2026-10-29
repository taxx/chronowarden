import { KeyRound, Lock, ShieldAlert, ShieldCheck, Sparkles } from 'lucide-react';

import { Card, CardContent, CardHeader } from '../components/ui';
import { useT } from '../i18n';

interface Layer {
  icon: typeof Lock;
  title: string;
  body: string;
}

export function EncryptionScreen() {
  const t = useT();

  const layers: Layer[] = [
    {
      icon: KeyRound,
      title: t('Passphrase'),
      body: t(
        'Your passphrase is never stored. It derives a Master Key in memory with PBKDF2-HMAC-SHA256 (310,000 iterations).',
      ),
    },
    {
      icon: Sparkles,
      title: t('Master key'),
      body: t(
        'The Master Key unwraps your random Data Encryption Key. Only the wrapped DEK is stored on the server.',
      ),
    },
    {
      icon: Lock,
      title: t('Data key'),
      body: t(
        'Your time logs, presets and settings are encrypted with AES-256-GCM on your device before they leave it.',
      ),
    },
    {
      icon: ShieldCheck,
      title: t('Recovery'),
      body: t(
        'A 24-word BIP39 recovery phrase encodes the DEK directly, so you can regain access if you forget your passphrase.',
      ),
    },
  ];

  return (
    <div className="space-y-4">
      <Card>
        <CardHeader
          title={t('How encryption works')}
          description={t('Your data is encrypted end-to-end. Even the administrator cannot read it.')}
        />
        <CardContent className="space-y-3">
          {layers.map((layer, index) => {
            const Icon = layer.icon;
            return (
              <div key={layer.title} className="flex gap-3 rounded-lg border border-border p-4">
                <div className="grid h-9 w-9 shrink-0 place-items-center rounded-full bg-primary/10 text-primary">
                  <Icon className="h-4 w-4" />
                </div>
                <div>
                  <p className="font-medium">
                    {index + 1}. {layer.title}
                  </p>
                  <p className="mt-0.5 text-sm text-muted-foreground">{layer.body}</p>
                </div>
              </div>
            );
          })}
        </CardContent>
      </Card>

      <Card className="border-destructive/40 bg-destructive/5">
        <CardContent className="flex gap-3">
          <ShieldAlert className="mt-0.5 h-5 w-5 shrink-0 text-destructive" />
          <div>
            <p className="font-medium text-destructive">{t('Critical warning')}</p>
            <p className="mt-0.5 text-sm text-muted-foreground">
              {t(
                'If you lose both the passphrase and the recovery phrase, your data is gone forever. No one — not even the administrator — can recover it.',
              )}
            </p>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}
