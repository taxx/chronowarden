import { render } from '@testing-library/react';
import { beforeEach, describe, expect, test, vi } from 'vitest';

vi.mock('../queries/time-logs', () => ({ useTodayLog: vi.fn() }));
vi.mock('../lib/notify', () => ({
  beep: vi.fn(),
  installAudioPrimer: vi.fn(),
  primeAudio: vi.fn(),
  requestNotificationPermission: vi.fn(),
  showOsNotification: vi.fn(),
  vibrate: vi.fn(),
}));

import type { TimeLog } from '../lib/domain/time-log';
import { useTodayLog } from '../queries/time-logs';
import { useNotificationsStore } from '../state/notifications';
import { NotificationWatcher } from './NotificationWatcher';

const mocked = { useTodayLog: vi.mocked(useTodayLog) };

const baseLog: TimeLog = {
  id: 'log-1',
  date: '2026-01-15',
  startTime: '08:00:00',
  expectedMinutes: 480,
  lunchMinutes: 0,
  nonWorkMinutes: 0,
  flexMinutes: 0,
  morningOverheadMinutes: 0,
  morningProductiveCommuteMinutes: 0,
  eveningOverheadMinutes: 0,
  eveningProductiveCommuteMinutes: 0,
  overtimeMinutes: 0,
};

beforeEach(() => {
  localStorage.clear();
  vi.clearAllMocks();
  mocked.useTodayLog.mockReturnValue({ data: null } as never);
  useNotificationsStore.setState({
    enabled: true,
    thresholdMinutes: 30,
    snoozeMinutes: 10,
    soundEnabled: false,
    vibrateEnabled: false,
    wrapUpAlertedDate: null,
    overtimeAlertedDate: null,
    dismissedDate: null,
    snoozedUntil: null,
    currentAlert: { kind: 'wrapUp', remainingMinutes: 10 },
    isTestAlert: false,
  });
});

describe('NotificationWatcher', () => {
  test('clears a lingering alert once the day has ended', () => {
    mocked.useTodayLog.mockReturnValue({ data: baseLog } as never);
    const { rerender } = render(<NotificationWatcher />);
    expect(useNotificationsStore.getState().currentAlert).not.toBeNull();

    // The day ended elsewhere; the query refetch delivers the completed log.
    mocked.useTodayLog.mockReturnValue({ data: { ...baseLog, endTime: '17:00:00' } } as never);
    rerender(<NotificationWatcher />);
    expect(useNotificationsStore.getState().currentAlert).toBeNull();
  });

  test('clears a lingering alert when the day is gone', () => {
    mocked.useTodayLog.mockReturnValue({ data: baseLog } as never);
    const { rerender } = render(<NotificationWatcher />);
    expect(useNotificationsStore.getState().currentAlert).not.toBeNull();

    mocked.useTodayLog.mockReturnValue({ data: null } as never);
    rerender(<NotificationWatcher />);
    expect(useNotificationsStore.getState().currentAlert).toBeNull();
  });

  test('keeps a test banner while no day is active', () => {
    useNotificationsStore.setState({
      currentAlert: { kind: 'overtime', remainingMinutes: -1 },
      isTestAlert: true,
    });
    render(<NotificationWatcher />);
    expect(useNotificationsStore.getState().currentAlert?.kind).toBe('overtime');
  });
});
