import { clsx } from 'clsx';
import type {
  ButtonHTMLAttributes,
  InputHTMLAttributes,
  ReactNode,
  SelectHTMLAttributes,
  TextareaHTMLAttributes,
} from 'react';
import { useEffect } from 'react';
import { twMerge } from 'tailwind-merge';
import { X } from 'lucide-react';

export function cn(...classes: Array<string | false | null | undefined>): string {
  return twMerge(clsx(classes));
}

/* -------------------------------------------------------------------------- */
/* Button                                                                     */
/* -------------------------------------------------------------------------- */

type ButtonVariant = 'primary' | 'secondary' | 'outline' | 'ghost' | 'destructive' | 'success';
type ButtonSize = 'sm' | 'default' | 'lg' | 'icon';

const buttonVariants: Record<ButtonVariant, string> = {
  primary: 'bg-primary text-primary-foreground hover:brightness-110 shadow-sm',
  secondary: 'bg-secondary text-secondary-foreground hover:bg-secondary/80',
  outline: 'border border-border bg-transparent hover:bg-accent hover:text-accent-foreground',
  ghost: 'hover:bg-accent hover:text-accent-foreground',
  destructive: 'bg-destructive text-destructive-foreground hover:brightness-110 shadow-sm',
  success: 'bg-success text-success-foreground hover:brightness-110 shadow-sm',
};

const buttonSizes: Record<ButtonSize, string> = {
  sm: 'h-8 px-3 text-xs',
  default: 'h-10 px-4 text-sm',
  lg: 'h-11 px-6 text-sm',
  icon: 'h-9 w-9',
};

export function Button({
  variant = 'primary',
  size = 'default',
  className,
  ...props
}: ButtonHTMLAttributes<HTMLButtonElement> & { variant?: ButtonVariant; size?: ButtonSize }) {
  return (
    <button
      className={cn(
        'inline-flex shrink-0 items-center justify-center gap-2 rounded-lg font-medium transition',
        'focus:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 focus-visible:ring-offset-background',
        'disabled:pointer-events-none disabled:opacity-50',
        buttonVariants[variant],
        buttonSizes[size],
        className,
      )}
      {...props}
    />
  );
}

/* -------------------------------------------------------------------------- */
/* Inputs                                                                     */
/* -------------------------------------------------------------------------- */

const controlClass =
  'w-full rounded-lg border border-input bg-background px-3 py-2 text-sm text-foreground shadow-sm ' +
  'placeholder:text-muted-foreground focus:border-ring focus:outline-none focus:ring-2 focus:ring-ring/30 ' +
  'disabled:cursor-not-allowed disabled:opacity-50';

export function Input({ className, ...props }: InputHTMLAttributes<HTMLInputElement>) {
  return <input className={cn(controlClass, 'h-10', className)} {...props} />;
}

export function Textarea({ className, ...props }: TextareaHTMLAttributes<HTMLTextAreaElement>) {
  return <textarea className={cn(controlClass, 'min-h-20', className)} {...props} />;
}

export function Select({ className, children, ...props }: SelectHTMLAttributes<HTMLSelectElement>) {
  return (
    <select className={cn(controlClass, 'h-10', className)} {...props}>
      {children}
    </select>
  );
}

export function Label({ htmlFor, children }: { htmlFor?: string; children: ReactNode }) {
  return (
    <label htmlFor={htmlFor} className="text-sm font-medium text-foreground">
      {children}
    </label>
  );
}

export function Field({
  label,
  htmlFor,
  error,
  hint,
  children,
}: {
  label: string;
  htmlFor: string;
  error?: string | null;
  hint?: string;
  children: ReactNode;
}) {
  return (
    <div className="space-y-1.5">
      <Label htmlFor={htmlFor}>{label}</Label>
      {children}
      {hint && !error ? <p className="text-xs text-muted-foreground">{hint}</p> : null}
      {error ? <p className="text-xs text-destructive">{error}</p> : null}
    </div>
  );
}

/* -------------------------------------------------------------------------- */
/* Card                                                                       */
/* -------------------------------------------------------------------------- */

export function Card({ children, className }: { children: ReactNode; className?: string }) {
  return (
    <div className={cn('rounded-xl border border-border bg-card text-card-foreground shadow-soft', className)}>
      {children}
    </div>
  );
}

export function CardHeader({
  title,
  description,
  action,
  className,
}: {
  title: ReactNode;
  description?: ReactNode;
  action?: ReactNode;
  className?: string;
}) {
  return (
    <div className={cn('flex flex-wrap items-start justify-between gap-3 p-5 pb-0', className)}>
      <div className="space-y-1">
        <h2 className="text-base font-semibold leading-none tracking-tight">{title}</h2>
        {description ? <p className="text-sm text-muted-foreground">{description}</p> : null}
      </div>
      {action}
    </div>
  );
}

export function CardContent({ children, className }: { children: ReactNode; className?: string }) {
  return <div className={cn('p-5', className)}>{children}</div>;
}

/* -------------------------------------------------------------------------- */
/* Badge / Separator                                                          */
/* -------------------------------------------------------------------------- */

type BadgeVariant = 'default' | 'secondary' | 'outline' | 'success' | 'warning' | 'destructive';

const badgeVariants: Record<BadgeVariant, string> = {
  default: 'bg-primary text-primary-foreground',
  secondary: 'bg-secondary text-secondary-foreground',
  outline: 'border border-border text-foreground',
  success: 'bg-success/15 text-success',
  warning: 'bg-warning/15 text-warning',
  destructive: 'bg-destructive/15 text-destructive',
};

export function Badge({
  variant = 'default',
  className,
  children,
}: {
  variant?: BadgeVariant;
  className?: string;
  children: ReactNode;
}) {
  return (
    <span
      className={cn(
        'inline-flex items-center gap-1 rounded-full px-2 py-0.5 text-xs font-medium',
        badgeVariants[variant],
        className,
      )}
    >
      {children}
    </span>
  );
}

export function Separator({ className }: { className?: string }) {
  return <div className={cn('h-px w-full bg-border', className)} />;
}

/* -------------------------------------------------------------------------- */
/* Dialog                                                                     */
/* -------------------------------------------------------------------------- */

export function Modal({
  open,
  onClose,
  title,
  description,
  footer,
  size = 'md',
  children,
}: {
  open: boolean;
  onClose: () => void;
  title: ReactNode;
  description?: ReactNode;
  footer?: ReactNode;
  size?: 'sm' | 'md' | 'lg';
  children: ReactNode;
}) {
  useEffect(() => {
    if (!open) return;
    const onKey = (event: KeyboardEvent) => {
      if (event.key === 'Escape') onClose();
    };
    document.addEventListener('keydown', onKey);
    document.body.style.overflow = 'hidden';
    return () => {
      document.removeEventListener('keydown', onKey);
      document.body.style.overflow = '';
    };
  }, [open, onClose]);

  if (!open) return null;

  const width = { sm: 'max-w-sm', md: 'max-w-lg', lg: 'max-w-2xl' }[size];

  return (
    <div className="fixed inset-0 z-50 flex items-end justify-center bg-black/50 p-0 backdrop-blur-sm sm:items-center sm:p-4 animate-fade-in">
      <div
        role="dialog"
        aria-modal="true"
        className={cn(
          'flex max-h-[92dvh] w-full flex-col rounded-t-2xl border border-border bg-card shadow-soft sm:rounded-xl',
          width,
        )}
      >
        <div className="flex items-start justify-between gap-4 p-5 pb-3">
          <div className="space-y-1">
            <h2 className="text-lg font-semibold tracking-tight">{title}</h2>
            {description ? <p className="text-sm text-muted-foreground">{description}</p> : null}
          </div>
          <Button variant="ghost" size="icon" aria-label="Close" onClick={onClose}>
            <X className="h-4 w-4" />
          </Button>
        </div>
        <div className="flex-1 overflow-y-auto px-5 pb-5">{children}</div>
        {footer ? <div className="border-t border-border p-4">{footer}</div> : null}
      </div>
    </div>
  );
}

export function ConfirmDialog({
  open,
  title,
  description,
  confirmLabel = 'Delete',
  cancelLabel = 'Cancel',
  destructive = true,
  busy = false,
  onConfirm,
  onClose,
}: {
  open: boolean;
  title: ReactNode;
  description?: ReactNode;
  confirmLabel?: string;
  cancelLabel?: string;
  destructive?: boolean;
  busy?: boolean;
  onConfirm: () => void;
  onClose: () => void;
}) {
  return (
    <Modal
      open={open}
      onClose={onClose}
      title={title}
      description={description}
      size="sm"
      footer={
        <div className="flex justify-end gap-2">
          <Button variant="ghost" onClick={onClose}>
            {cancelLabel}
          </Button>
          <Button variant={destructive ? 'destructive' : 'primary'} onClick={onConfirm} disabled={busy}>
            {confirmLabel}
          </Button>
        </div>
      }
    >
      <div />
    </Modal>
  );
}

/* -------------------------------------------------------------------------- */
/* Tabs                                                                       */
/* -------------------------------------------------------------------------- */

export function Tabs<T extends string>({
  value,
  onChange,
  items,
  className,
}: {
  value: T;
  onChange: (value: T) => void;
  items: Array<{ value: T; label: string }>;
  className?: string;
}) {
  return (
    <div className={cn('inline-flex flex-wrap gap-1 rounded-lg bg-muted p-1', className)}>
      {items.map((item) => (
        <button
          key={item.value}
          type="button"
          onClick={() => onChange(item.value)}
          className={cn(
            'rounded-md px-3 py-1.5 text-sm font-medium transition',
            value === item.value
              ? 'bg-card text-foreground shadow-sm'
              : 'text-muted-foreground hover:text-foreground',
          )}
        >
          {item.label}
        </button>
      ))}
    </div>
  );
}

/* -------------------------------------------------------------------------- */
/* Slider / Progress / Spinner / Skeleton / EmptyState                        */
/* -------------------------------------------------------------------------- */

export function Slider({
  value,
  min = 0,
  max = 100,
  step = 1,
  onChange,
  id,
}: {
  value: number;
  min?: number;
  max?: number;
  step?: number;
  onChange: (value: number) => void;
  id?: string;
}) {
  return (
    <input
      id={id}
      type="range"
      min={min}
      max={max}
      step={step}
      value={value}
      onChange={(event) => onChange(Number(event.target.value))}
    />
  );
}

export function Progress({ value }: { value: number }) {
  return (
    <div className="h-2 w-full overflow-hidden rounded-full bg-secondary">
      <div
        className="h-full rounded-full bg-primary transition-all"
        style={{ width: `${Math.min(100, Math.max(0, value))}%` }}
      />
    </div>
  );
}

export function Spinner({ className }: { className?: string }) {
  return (
    <div
      role="status"
      aria-label="Loading"
      className={cn('h-5 w-5 animate-spin rounded-full border-2 border-border border-t-primary', className)}
    />
  );
}

export function Skeleton({ className }: { className?: string }) {
  return <div className={cn('animate-pulse rounded-md bg-muted', className)} />;
}

export function EmptyState({
  icon,
  title,
  description,
  action,
}: {
  icon?: ReactNode;
  title: string;
  description?: string;
  action?: ReactNode;
}) {
  return (
    <div className="flex flex-col items-center justify-center gap-2 py-10 text-center">
      {icon ? <div className="text-muted-foreground">{icon}</div> : null}
      <p className="font-medium">{title}</p>
      {description ? <p className="max-w-sm text-sm text-muted-foreground">{description}</p> : null}
      {action ? <div className="mt-3">{action}</div> : null}
    </div>
  );
}
