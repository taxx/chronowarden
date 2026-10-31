import type { ReactNode } from 'react';

import { Card, CardContent, CardHeader, cn } from './ui';

/**
 * Centered card used by the unauthenticated screens (login, setup, unlock,
 * recovery…). Uses CardHeader/CardContent so the content always has the same
 * padding as the rest of the app.
 */
export function AuthCard({
  title,
  description,
  footer,
  width = 'max-w-md',
  children,
}: {
  title: string;
  description?: ReactNode;
  footer?: ReactNode;
  width?: string;
  children: ReactNode;
}) {
  return (
    <div className="grid min-h-dvh place-items-center p-6">
      <Card className={cn('w-full', width)}>
        <CardHeader title={title} description={description} />
        <CardContent>{children}</CardContent>
        {footer ? <div className="border-t p-5 text-center">{footer}</div> : null}
      </Card>
    </div>
  );
}
