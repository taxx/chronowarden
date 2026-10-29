import { Code2, Lock, Server } from 'lucide-react';

import { useT } from '../i18n';
import { Card, CardContent, CardHeader } from './ui';

const GITHUB_URL = 'https://github.com/taxx/chronowarden';

export function AboutCard() {
  const t = useT();
  const commit = typeof __BUILD_COMMIT__ === 'string' ? __BUILD_COMMIT__ : 'dev';

  return (
    <Card>
      <CardHeader title={t('About ChronoWarden')} description={t('Version {version}', { version: commit })} />
      <CardContent className="space-y-4 text-sm">
        <p className="flex items-start gap-2 text-muted-foreground">
          <Lock className="mt-0.5 h-4 w-4 shrink-0 text-primary" />
          {t(
            'Your data is encrypted with AES-256-GCM on your device before it reaches the server. No one — not even the administrator — can read it.',
          )}
        </p>
        <p className="flex items-start gap-2 text-muted-foreground">
          <Server className="mt-0.5 h-4 w-4 shrink-0 text-primary" />
          {t(
            'ChronoWarden is free, open-source and designed to be self-hosted — the whole stack lives in one repository.',
          )}
        </p>
        <div className="flex flex-wrap gap-4 pt-1">
          <a
            href={GITHUB_URL}
            target="_blank"
            rel="noreferrer"
            className="inline-flex items-center gap-2 text-primary hover:underline"
          >
            <Code2 className="h-4 w-4" />
            {t('View source on GitHub')}
          </a>
        </div>
      </CardContent>
    </Card>
  );
}
