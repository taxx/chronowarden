import { Toaster as SonnerToaster } from 'sonner';

/** Toast viewport — a thin wrapper so the theme tokens apply. */
export function Toaster() {
  return (
    <SonnerToaster
      position="bottom-right"
      toastOptions={{
        classNames: {
          toast:
            'group rounded-xl border bg-card text-card-foreground shadow-soft',
          description: 'text-muted-foreground',
          actionButton: 'bg-primary text-primary-foreground',
          cancelButton: 'bg-secondary text-secondary-foreground',
          error: 'text-destructive',
          success: 'text-success',
        },
      }}
    />
  );
}
