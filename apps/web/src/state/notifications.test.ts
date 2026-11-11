import { beforeEach, describe, expect, test, vi } from 'vitest';

vi.mock('../lib/notify', () => ({
  beep: vi.fn(),
  installAudioPrimer: vi.fn(),
  primeAudio: vi.fn(),
  requestNotificationPermission: vi.fn(),
  showOsNotification: vi.fn(),
  vibrate: vi.fn(),
}));

import { showOsNotification } from '../lib/notify';
import { useNotificationsStore } from './notifications';

const NOW = new Date('2026-01-15T12:00:00');

function resetStore() {
  localStorage.clear();
  useNotificationsStore.setState({
    enabled: false,
    thresholdMinutes: 30,
    snoozeMinutes: 10,
    soundEnabled: true,
    vibrateEnabled: true,
    wrapUpAlertedDate: null,
    overtimeAlertedDate: null,
    dismissedDate: null,
    snoozedUntil: null,
    currentAlert: null,
    isTestAlert: false,
  });
}

beforeEach(() => {
  vi.clearAllMocks();
  resetStore();
});

describe('notifications store', () => {
  test('fires wrap-up and then overtime (both phases, once each)', () => {
    const store = useNotificationsStore.getState();
    store.setEnabled(true);

    useNotificationsStore.getState().check(30, NOW);
    expect(useNotificationsStore.getState().currentAlert?.kind).toBe('wrapUp');
    expect(showOsNotification).toHaveBeenCalledTimes(1);

    // A second in-threshold tick must not repeat the wrap-up alert.
    useNotificationsStore.getState().check(20, NOW);
    expect(showOsNotification).toHaveBeenCalledTimes(1);

    // Past leave time the overtime alert fires even though wrap-up did.
    useNotificationsStore.getState().check(-5, NOW);
    expect(useNotificationsStore.getState().currentAlert?.kind).toBe('overtime');
    expect(showOsNotification).toHaveBeenCalledTimes(2);

    expect(localStorage.getItem('notified_wrapup_date')).toBe('2026-01-15');
    expect(localStorage.getItem('notified_overtime_date')).toBe('2026-01-15');
  });

  test('does nothing while disabled', () => {
    useNotificationsStore.getState().check(30, NOW);
    expect(useNotificationsStore.getState().currentAlert).toBeNull();
    expect(showOsNotification).not.toHaveBeenCalled();
  });

  test('does not alert beyond the overtime window', () => {
    useNotificationsStore.getState().setEnabled(true);
    useNotificationsStore.getState().check(-61, NOW);
    expect(useNotificationsStore.getState().currentAlert).toBeNull();
  });

  test('snooze re-arms the alert for the phase that follows', () => {
    const store = useNotificationsStore.getState();
    store.setEnabled(true);

    useNotificationsStore.getState().check(30, NOW);
    expect(useNotificationsStore.getState().currentAlert?.kind).toBe('wrapUp');

    useNotificationsStore.getState().snooze(NOW);
    expect(useNotificationsStore.getState().currentAlert).toBeNull();

    // While snoozed: nothing.
    useNotificationsStore.getState().check(-2, NOW);
    expect(useNotificationsStore.getState().currentAlert).toBeNull();

    // After the snooze expires the overtime alert fires.
    const later = new Date(NOW.getTime() + 11 * 60_000);
    useNotificationsStore.getState().check(-2, later);
    expect(useNotificationsStore.getState().currentAlert?.kind).toBe('overtime');
  });

  test('dismiss suppresses alerts for the rest of the day', () => {
    const store = useNotificationsStore.getState();
    store.setEnabled(true);

    useNotificationsStore.getState().check(30, NOW);
    useNotificationsStore.getState().dismiss(NOW);
    expect(useNotificationsStore.getState().currentAlert).toBeNull();

    useNotificationsStore.getState().check(20, NOW);
    useNotificationsStore.getState().check(-5, NOW);
    expect(showOsNotification).toHaveBeenCalledTimes(1);
  });

  test('date rollover resets the delivered phases', () => {
    useNotificationsStore.getState().setEnabled(true);
    useNotificationsStore.getState().check(30, NOW);
    expect(showOsNotification).toHaveBeenCalledTimes(1);

    const tomorrow = new Date('2026-01-16T12:00:00');
    useNotificationsStore.getState().check(30, tomorrow);
    expect(useNotificationsStore.getState().currentAlert?.kind).toBe('wrapUp');
    expect(showOsNotification).toHaveBeenCalledTimes(2);
  });

  test('test alerts use the real delivery path without touching the day', () => {
    useNotificationsStore.getState().setEnabled(true);

    useNotificationsStore.getState().sendTestAlert('overtime');
    expect(showOsNotification).toHaveBeenCalledTimes(1);
    expect(useNotificationsStore.getState().currentAlert?.kind).toBe('overtime');
    expect(useNotificationsStore.getState().isTestAlert).toBe(true);
    // The real per-day flags stay clean.
    expect(localStorage.getItem('notified_overtime_date')).toBeNull();

    // Dismissing the test banner must not dismiss real alerts.
    useNotificationsStore.getState().dismiss(NOW);
    expect(useNotificationsStore.getState().dismissedDate).toBeNull();
    expect(useNotificationsStore.getState().currentAlert).toBeNull();

    useNotificationsStore.getState().check(-5, NOW);
    expect(useNotificationsStore.getState().currentAlert?.kind).toBe('overtime');
    expect(showOsNotification).toHaveBeenCalledTimes(2);
  });

  test('clearAlert hides a real alert but keeps a test banner', () => {
    useNotificationsStore.getState().setEnabled(true);
    useNotificationsStore.getState().check(30, NOW);
    expect(useNotificationsStore.getState().currentAlert?.kind).toBe('wrapUp');

    useNotificationsStore.getState().clearAlert();
    expect(useNotificationsStore.getState().currentAlert).toBeNull();

    useNotificationsStore.getState().sendTestAlert('overtime');
    expect(useNotificationsStore.getState().isTestAlert).toBe(true);
    useNotificationsStore.getState().clearAlert();
    expect(useNotificationsStore.getState().currentAlert?.kind).toBe('overtime');
  });
});
