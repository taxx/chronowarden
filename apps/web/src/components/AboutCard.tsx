import { useEffect, useState } from 'react';
import { Code2, Download, Lock, RefreshCw, Server } from 'lucide-react';

import { useT } from '../i18n';
import { useLocaleStore } from '../i18n';
import { useAuthStore } from '../state/auth';
import { useThemeStore } from '../state/theme';
import { useToastStore } from '../state/toast';
import { Button, Card, CardContent, CardHeader } from './ui';

const GITHUB_URL = 'https://github.com/taxx/chronowarden';

function Row({ label, value, tone }: { label: string; value: string; tone?: string }) {
  return (
    <div className="flex items-center justify-between gap-4 border-b border-border py-1.5 last:border-0">
      <dt className="text-sm text-muted-foreground">{label}</dt>
      <dd className={'text-sm font-medium ' + (tone ?? '')}>{value}</dd>
    </div>
  );
}

export function AboutCard() {
  const t = useT();
  const dek = useAuthStore((state) => state.dek);
  const locale = useLocaleStore((state) => state.locale);
  const theme = useThemeStore((state) => state.preference);
  const pushToast = useToastStore((state) => state.push);

  const commit = typeof __BUILD_COMMIT__ === 'string' ? __BUILD_COMMIT__ : 'dev';
  const [apiOk, setApiOk] = useState<boolean | null>(null);
  const [checking, setChecking] = useState(false);

  useEffect(() => {
    let cancelled = false;
    fetch('/api/health')
      .then((res) => !cancelled && setApiOk(res.ok))
      .catch(() => !cancelled && setApiOk(false));
    return () => {
      cancelled = true;
    };
  }, []);

  async function checkForUpdates() {
    setChecking(true);
    try {
      const res = await fetch(`/version.json?ts=${Date.now()}`, { cache: 'no-store' });
      const info = (await res.json()) as { commit?: string };
      if (!info.commit || info.commit === 'dev' || info.commit === commit) {
        pushToast(t('You are on the latest version ({commit}).', { commit }), 'success');
      } else {
        pushToast(t('A new version is available — reload to update.'), 'default');
      }
    } catch {
      pushToast(t('Update check unavailable.'), 'error');
    } finally {
      setChecking(false);
    }
  }

  return (
    <Card>
      <CardHeader
        title={t('About ChronoWarden')}
        description={t('Version {version}', { version: commit })}
        action={
          <Button variant="outline" size="sm" onClick={() => void checkForUpdates()} disabled={checking}>
            <RefreshCw className="h-3.5 w-3.5" />
            {t('Check for updates')}
          </Button>
        }
      />
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

        <div>
          <p className="mb-1 text-xs uppercase tracking-wide text-muted-foreground">{t('Diagnostics')}</p>
          <dl>
            <Row label={t('Version')} value={commit} />
            <Row
              label={t('API')}
              value={apiOk == null ? '…' : apiOk ? t('Connected') : t('Unreachable')}
              tone={apiOk == null ? undefined : apiOk ? 'text-success' : 'text-warning'}
            />
            <Row label={t('Encryption key')} value={dek ? t('Unlocked') : t('Locked')} />
            <Row label={t('Language')} value={locale === 'sv' ? 'Svenska' : 'English'} />
            <Row label={t('Appearance')} value={theme} />
          </dl>
        </div>

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
          <a
            href={`${GITHUB_URL}#readme`}
            target="_blank"
            rel="noreferrer"
            className="inline-flex items-center gap-2 text-primary hover:underline"
          >
            <Download className="h-4 w-4" />
            {t('Self-hosting guide')}
          </a>
        </div>
      </CardContent>
    </Card>
  );
}
