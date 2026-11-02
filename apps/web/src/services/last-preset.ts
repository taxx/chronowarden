/**
 * The last travel preset the user picked when starting a day.
 *
 * Stored per-device in localStorage (the Flutter app kept it in shared
 * preferences). It drives the default selection in the start/add-day dialogs.
 */
const LAST_PRESET_KEY = 'cw_last_preset';

export function getLastPresetId(): string {
  try {
    return localStorage.getItem(LAST_PRESET_KEY) ?? '';
  } catch {
    return '';
  }
}

export function setLastPresetId(id: string | null | undefined): void {
  try {
    if (id) localStorage.setItem(LAST_PRESET_KEY, id);
  } catch {
    // localStorage can be unavailable (private mode); the default is harmless.
  }
}
