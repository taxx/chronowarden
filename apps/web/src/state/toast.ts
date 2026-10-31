import { create } from 'zustand';
import { toast as sonnerToast } from 'sonner';

export type ToastVariant = 'default' | 'success' | 'error';

interface ToastState {
  push: (message: string, variant?: ToastVariant) => void;
}

/**
 * Thin adapter over Sonner so call sites keep the `push(message, variant)` API.
 */
export const useToastStore = create<ToastState>(() => ({
  push: (message, variant = 'default') => {
    if (variant === 'success') sonnerToast.success(message);
    else if (variant === 'error') sonnerToast.error(message);
    else sonnerToast(message);
  },
}));

/** Convenience helpers usable outside React (services, event handlers). */
export const toast = {
  show: (message: string) => useToastStore.getState().push(message),
  success: (message: string) => useToastStore.getState().push(message, 'success'),
  error: (message: string) => useToastStore.getState().push(message, 'error'),
};
