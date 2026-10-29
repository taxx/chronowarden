import { useEffect, useState } from 'react';

import { useT } from '../i18n';
import { Button } from './ui';

/** Commit id this bundle was built from (injected by Vite at build time). */
declare const __BUILD_COMMIT__: string;

interface VersionInfo {
  commit: string;
}

const POLL_INTERVAL_MS = 5 * 60_000;

async function fetchServerCommit(): Promise<string | null> {
  try {
    const response = await fetch(`/version.json?t=${Date.now()}`, { cache: 'no-store' });
    if (!response.ok) return null;
    const info = (await response.json()) as VersionInfo;
    return info?.commit ?? null;
  } catch {
    return null;
  }
}

/**
 * Offers a reload when the served `version.json` reports a newer commit than
 * this bundle's. Long-lived tabs keep running old JS otherwise.
 */
export function UpdateBanner() {
  const t = useT();
  const [serverCommit, setServerCommit] = useState<string | null>(null);
  const [dismissed, setDismissed] = useState<string | null>(() =>
    localStorage.getItem('cw_dismissed_commit'),
  );

  useEffect(() => {
    let cancelled = false;

    const check = async () => {
      const commit = await fetchServerCommit();
      if (!cancelled) setServerCommit(commit);
    };

    void check();
    const id = setInterval(check, POLL_INTERVAL_MS);
    const onVisible = () => {
      if (!document.hidden) void check();
    };
    document.addEventListener('visibilitychange', onVisible);
    return () => {
      cancelled = true;
      clearInterval(id);
      document.removeEventListener('visibilitychange', onVisible);
    };
  }, []);

  const buildCommit = typeof __BUILD_COMMIT__ === 'string' ? __BUILD_COMMIT__ : 'dev';
  if (!serverCommit || buildCommit === 'dev' || serverCommit === buildCommit) return null;
  if (dismissed === serverCommit) return null;

  return (
    <div className="mb-4 flex flex-wrap items-center justify-between gap-3 rounded-xl border border-sky-700 bg-sky-950/50 p-4 text-sky-100">
      <p className="text-sm">{t('A new version is available — reload to update.')}</p>
      <div className="flex gap-2">
        <Button variant="ghost" onClick={() => window.location.reload()}>
          {t('Reload')}
        </Button>
        <Button
          variant="ghost"
          onClick={() => {
            localStorage.setItem('cw_dismissed_commit', serverCommit);
            setDismissed(serverCommit);
          }}
        >
          {t('Dismiss')}
        </Button>
      </div>
    </div>
  );
}
