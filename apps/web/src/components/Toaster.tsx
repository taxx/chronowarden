import { CheckCircle2, Info, X, XCircle } from 'lucide-react';

import { useToastStore } from '../state/toast';
import { Button, cn } from './ui';

const icons = {
  default: Info,
  success: CheckCircle2,
  error: XCircle,
};

const tones = {
  default: 'text-foreground',
  success: 'text-success',
  error: 'text-destructive',
};

/** Fixed toast viewport; rendered once by the app shell. */
export function Toaster() {
  const toasts = useToastStore((state) => state.toasts);
  const dismiss = useToastStore((state) => state.dismiss);

  return (
    <div className="pointer-events-none fixed bottom-4 right-4 z-[60] flex w-full max-w-sm flex-col gap-2">
      {toasts.map((item) => {
        const Icon = icons[item.variant];
        return (
          <div
            key={item.id}
            className="pointer-events-auto flex items-start gap-3 rounded-xl border border-border bg-card p-3.5 shadow-soft animate-slide-in-right"
          >
            <Icon className={cn('mt-0.5 h-5 w-5 shrink-0', tones[item.variant])} />
            <p className="flex-1 text-sm">{item.message}</p>
            <button
              type="button"
              aria-label="Dismiss"
              onClick={() => dismiss(item.id)}
              className="text-muted-foreground hover:text-foreground"
            >
              <X className="h-4 w-4" />
            </button>
          </div>
        );
      })}
    </div>
  );
}

/** Small wrapper so a page can offer a retry action inside a toast-style card. */
export function ToastActionButton({ onClick, children }: { onClick: () => void; children: React.ReactNode }) {
  return (
    <Button variant="outline" size="sm" onClick={onClick}>
      {children}
    </Button>
  );
}
