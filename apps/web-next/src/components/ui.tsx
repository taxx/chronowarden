import { clsx } from 'clsx';
import type { ButtonHTMLAttributes, InputHTMLAttributes, ReactNode } from 'react';
import { twMerge } from 'tailwind-merge';

export function cn(...classes: Array<string | false | null | undefined>): string {
  return twMerge(clsx(classes));
}

export function Button({
  variant = 'primary',
  className,
  ...props
}: ButtonHTMLAttributes<HTMLButtonElement> & { variant?: 'primary' | 'ghost' }) {
  return (
    <button
      className={cn(
        'inline-flex items-center justify-center rounded-lg px-4 py-2 text-sm font-medium transition',
        'focus:outline-none focus-visible:ring-2 focus-visible:ring-sky-400 disabled:opacity-50',
        variant === 'primary'
          ? 'bg-sky-600 text-white hover:bg-sky-500 disabled:hover:bg-sky-600'
          : 'text-slate-300 hover:bg-slate-800 hover:text-white',
        className,
      )}
      {...props}
    />
  );
}

export function Input({ className, ...props }: InputHTMLAttributes<HTMLInputElement>) {
  return (
    <input
      className={cn(
        'w-full rounded-lg border border-slate-700 bg-slate-900 px-3 py-2 text-sm text-slate-100',
        'placeholder:text-slate-500 focus:border-sky-500 focus:outline-none',
        className,
      )}
      {...props}
    />
  );
}

export function Field({
  label,
  htmlFor,
  error,
  children,
}: {
  label: string;
  htmlFor: string;
  error?: string | null;
  children: ReactNode;
}) {
  return (
    <div className="space-y-1.5">
      <label htmlFor={htmlFor} className="block text-sm font-medium text-slate-300">
        {label}
      </label>
      {children}
      {error ? <p className="text-xs text-red-400">{error}</p> : null}
    </div>
  );
}

export function Card({ children, className }: { children: ReactNode; className?: string }) {
  return (
    <div className={cn('rounded-2xl border border-slate-800 bg-slate-900/60 p-6 shadow-xl', className)}>
      {children}
    </div>
  );
}

export function Spinner({ className }: { className?: string }) {
  return (
    <div
      role="status"
      aria-label="Loading"
      className={cn(
        'h-5 w-5 animate-spin rounded-full border-2 border-slate-600 border-t-sky-400',
        className,
      )}
    />
  );
}
