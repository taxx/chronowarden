import { registerSW } from 'virtual:pwa-register';

type UpdateFn = (reloadPage?: boolean) => Promise<void>;

let updateServiceWorker: UpdateFn | null = null;

/**
 * Register the service worker and keep a handle to its update function.
 *
 * The PWA caches the app shell, so a plain `location.reload()` can serve the
 * *old* bundle from the cache. The register config is `registerType: 'prompt'`
 * with `workbox.clientsClaim`, so `update(true)` activates a waiting worker
 * (`SKIP_WAITING`) and reloads once it claims this client.
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

/** Resolve `true` once a new worker controls this client, or `false` after `ms`. */
function waitForControllerChange(ms: number): Promise<boolean> {
  if (!('serviceWorker' in navigator)) return Promise.resolve(false);
  return new Promise((resolve) => {
    const onChange = () => {
      clearTimeout(timer);
      resolve(true);
    };
    const timer = setTimeout(() => {
      navigator.serviceWorker.removeEventListener('controllerchange', onChange);
      resolve(false);
    }, ms);
    navigator.serviceWorker.addEventListener('controllerchange', onChange, { once: true });
  });
}

/**
 * Reload onto the newest deployment.
 *
 * Prefers the service-worker update path: a waiting worker is activated and,
 * because it claims clients, the page reloads onto the fresh precache. Only if
 * there is no updateable worker do we drop the registration and its caches and
 * hard-reload, so we never discard a just-installed worker mid-update.
 */
export async function reloadToUpdate(): Promise<void> {
  const update = updateServiceWorker;
  const registration =
    'serviceWorker' in navigator ? await navigator.serviceWorker.getRegistration() : undefined;

  if (update && registration) {
    try {
      // Make sure we have the latest `sw.js` before asking it to take over.
      if (!registration.waiting) await registration.update();

      if (registration.waiting) {
        await update(true); // posts SKIP_WAITING; this client is then claimed
        if (await waitForControllerChange(3000)) {
          window.location.reload();
          return;
        }
      }
    } catch {
      // fall through to the hard reset
    }
  }

  // Last resort: no updateable worker — remove registrations + caches so the
  // next load is served from the network.
  try {
    const registrations = (await navigator.serviceWorker?.getRegistrations?.()) ?? [];
    await Promise.all(registrations.map((r) => r.unregister()));
    if ('caches' in window) {
      const keys = await caches.keys();
      await Promise.all(keys.map((key) => caches.delete(key)));
    }
  } catch {
    // ignore — a plain reload is still better than nothing
  }

  window.location.reload();
}
