import { ShieldCheck } from 'lucide-react';
import type { ReactNode } from 'react';

import { useT } from '../i18n';
import { Card, CardContent, CardHeader, cn } from './ui';

function BrandHeader() {
  const t = useT();
  return (
    <div className="mb-6 flex flex-col items-center text-center">
      <img
        src="/icons/Icon-192.png"
        alt=""
        width={56}
        height={56}
        className="h-14 w-14 rounded-2xl shadow-soft"
      />
      <h1 className="mt-3 text-2xl font-semibold tracking-tight">{t('ChronoWarden')}</h1>
      <p className="mt-1 text-sm text-muted-foreground">
        {t('Personal time-banking and overtime protection.')}
      </p>
    </div>
  );
}

/**
 * Centered card used by the unauthenticated screens (login, setup, unlock,
 * recovery…). CardHeader/CardContent give the content the same padding as the
 * rest of the app.
 */
export function AuthCard({
  title,
  description,
  footer,
  info,
  brand = false,
  width = 'max-w-md',
  children,
}: {
  title: string;
  description?: ReactNode;
  footer?: ReactNode;
  info?: ReactNode;
  brand?: boolean;
  width?: string;
  children: ReactNode;
}) {
  return (
    <div className="grid min-h-dvh place-items-center p-6">
      <div className={cn('w-full', width)}>
        {brand ? <BrandHeader /> : null}
        <Card>
          <CardHeader title={title} description={description} />
          <CardContent>{children}</CardContent>
          {footer ? <div className="border-t p-5 text-center">{footer}</div> : null}
        </Card>
        {info ? <div className="mt-4">{info}</div> : null}
      </div>
    </div>
  );
}

/** Compact "your data is private" panel for the public entry screens. */
export function PrivacyNotice({ onLearnMore }: { onLearnMore: () => void }) {
  const t = useT();
  const points = [t('Zero-knowledge'), t('Self-hosted'), t('Open source')];
  return (
    <Card>
      <CardContent className="space-y-3">
        <p className="flex items-start gap-2 text-sm">
          <ShieldCheck className="mt-0.5 h-4 w-4 shrink-0 text-success" />
          <span>
            {t('Your data is encrypted end-to-end. Only you can read it — not even the administrator.')}
          </span>
        </p>
        <div className="flex flex-wrap gap-1.5">
          {points.map((point) => (
            <span key={point} className="rounded-full bg-secondary px-2.5 py-0.5 text-xs text-secondary-foreground">
              {point}
            </span>
          ))}
        </div>
        <button
          type="button"
          onClick={onLearnMore}
          className="text-sm text-primary hover:underline"
        >
          {t('How encryption works')}
        </button>
      </CardContent>
    </Card>
  );
}
