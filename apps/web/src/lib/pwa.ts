import { registerSW } from 'virtual:pwa-register';

type UpdateFn = (reloadPage?: boolean) => Promise<void>;

let updateServiceWorker: UpdateFn | null = null;

/**
 * Register the service worker and keep a handle to its update function.
 *
 * The PWA caches the app shell, so a plain `location.reload()` can serve the
 * *old* bundle from the cache. Calling the SW's update function installs the
 * new worker and only reloads once it is in control.
 */
export function registerServiceWorker(): void {
  updateServiceWorker = registerSW({
    immediate: true,
    onRegisteredSW(_url, registration) {
      // Check for a new deployment at most once an hour while the tab is open.
      if (registration) setInterval(() => void registration.update(), 60 * 60_000);
    },
  });
}

/** Reload onto the newest deployment (falls back to a hard refresh). */
export async function reloadToUpdate(): Promise<void> {
  const update = updateServiceWorker;
  if (update) {
    try {
      // `true` reloads the page once the new service worker has taken control.
      await update(true);
      return;
    } catch {
      // fall through
    }
  }
  window.location.reload();
}
