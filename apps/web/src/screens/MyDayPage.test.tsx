import { render, screen, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { beforeEach, describe, expect, test, vi } from 'vitest';

import type { TimeLog } from '../lib/domain/time-log';
import { MyDayPage } from './MyDayPage';
import { useCreateTimeLog, useTimeLogs, useTodayLog, useUpdateTimeLog } from '../queries/time-logs';
import { useWorkConfig } from '../queries/settings';
import { useTravelPresets } from '../queries/travel-presets';

vi.mock('../queries/time-logs', () => ({
  useTodayLog: vi.fn(),
  useTimeLogs: vi.fn(),
  useCreateTimeLog: vi.fn(),
  useUpdateTimeLog: vi.fn(),
}));
vi.mock('../queries/settings', () => ({
  useWorkConfig: vi.fn(),
}));
vi.mock('../queries/travel-presets', () => ({
  useTravelPresets: vi.fn(),
}));

const mocked = {
  useTodayLog: vi.mocked(useTodayLog),
  useTimeLogs: vi.mocked(useTimeLogs),
  useCreateTimeLog: vi.mocked(useCreateTimeLog),
  useUpdateTimeLog: vi.mocked(useUpdateTimeLog),
  useWorkConfig: vi.mocked(useWorkConfig),
};

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
  vi.clearAllMocks();
  mocked.useTimeLogs.mockReturnValue({ data: [], isLoading: false } as never);
  mocked.useWorkConfig.mockReturnValue({
    data: { defaultExpectedMinutes: 480 },
  } as never);
  vi.mocked(useTravelPresets).mockReturnValue({ data: [], isLoading: false } as never);
  mocked.useCreateTimeLog.mockReturnValue({
    mutateAsync: vi.fn().mockResolvedValue({}),
    isPending: false,
  } as never);
  mocked.useUpdateTimeLog.mockReturnValue({
    mutateAsync: vi.fn().mockResolvedValue({}),
    isPending: false,
  } as never);
});

describe('MyDayPage', () => {
  test('starts the day when there is no log', async () => {
    mocked.useTodayLog.mockReturnValue({ data: null, isLoading: false } as never);
    const mutateAsync = vi.fn().mockResolvedValue({});
    mocked.useCreateTimeLog.mockReturnValue({ mutateAsync, isPending: false } as never);

    render(<MyDayPage />);
    await userEvent.click(screen.getByRole('button', { name: 'Start Day' }));

    await waitFor(() => expect(mutateAsync).toHaveBeenCalledTimes(1));
    const payload = mutateAsync.mock.calls[0]![0] as TimeLog;
    expect(payload.expectedMinutes).toBe(480);
    expect(payload.date).toMatch(/^\d{4}-\d{2}-\d{2}$/);
    expect(payload.startTime).toMatch(/^\d{2}:\d{2}:\d{2}$/);
  });

  test('shows the leave time and stops the day with computed overtime', async () => {
    mocked.useTodayLog.mockReturnValue({ data: baseLog, isLoading: false } as never);
    const mutateAsync = vi.fn().mockResolvedValue({});
    mocked.useUpdateTimeLog.mockReturnValue({ mutateAsync, isPending: false } as never);

    render(<MyDayPage />);

    expect(screen.getByText('Leave time')).toBeTruthy();
    expect(screen.getByText('16:00')).toBeTruthy();

    await userEvent.click(screen.getByRole('button', { name: 'Stop Day' }));

    await waitFor(() => expect(mutateAsync).toHaveBeenCalledTimes(1));
    const call = mutateAsync.mock.calls[0]![0] as { id: string; fields: Record<string, unknown> };
    expect(call.id).toBe('log-1');
    expect(call.fields['end_time']).toMatch(/^\d{2}:\d{2}:\d{2}$/);
    expect(typeof call.fields['overtime_minutes']).toBe('number');
  });

  test('shows the time bank total from all logs', () => {
    mocked.useTodayLog.mockReturnValue({ data: baseLog, isLoading: false } as never);
    mocked.useTimeLogs.mockReturnValue({
      data: [
        { ...baseLog, id: 'a', overtimeMinutes: 30 },
        { ...baseLog, id: 'b', overtimeMinutes: -15 },
      ],
      isLoading: false,
    } as never);

    render(<MyDayPage />);
    expect(screen.getByText('+15 min')).toBeTruthy();
  });
});
