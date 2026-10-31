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

/**
 * Reload onto the newest deployment.
 *
 * Tries the service worker's update path first; if that doesn't take control we
 * drop the worker and its caches and do a hard reload, so a single click always
 * lands on the freshly served bundle.
 */
export async function reloadToUpdate(): Promise<void> {
  const update = updateServiceWorker;
  if (update) {
    try {
      await update(true);
      // `update(true)` reloads when a new worker activates; if it was already
      // current there is nothing to install, so continue to the hard reset.
    } catch {
      // fall through
    }
  }

  try {
    const registrations = (await navigator.serviceWorker?.getRegistrations?.()) ?? [];
    await Promise.all(registrations.map((registration) => registration.unregister()));
    if ('caches' in window) {
      const keys = await caches.keys();
      await Promise.all(keys.map((key) => caches.delete(key)));
    }
  } catch {
    // ignore — a plain reload is still better than nothing
  }

  window.location.reload();
}
