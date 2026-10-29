import type { PinnedJourney } from '../lib/domain/pinned-journey';

const STORAGE_KEY = 'cw_pinned_journey';

export function loadPinnedJourney(): PinnedJourney | null {
  try {
    const raw = localStorage.getItem(STORAGE_KEY);
    return raw ? (JSON.parse(raw) as PinnedJourney) : null;
  } catch {
    return null;
  }
}

export function savePinnedJourney(pin: PinnedJourney): void {
  localStorage.setItem(STORAGE_KEY, JSON.stringify(pin));
}

export function clearPinnedJourney(): void {
  localStorage.removeItem(STORAGE_KEY);
}
