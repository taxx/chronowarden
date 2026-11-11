import { create } from 'zustand';

import { translate, useLocaleStore } from '../i18n';
import { toDateStr } from '../lib/date';
import { evaluateLeaveAlert, type LeaveAlert, type LeaveAlertKind } from '../lib/domain/leave-alert';
import {
  beep,
  installAudioPrimer,
  primeAudio,
  requestNotificationPermission,
  showOsNotification,
  vibrate,
} from '../lib/notify';

const KEYS = {
  enabled: 'notifications_enabled',
  threshold: 'notification_threshold_minutes',
  snooze: 'notification_snooze_minutes',
  sound: 'notification_sound_enabled',
  vibrate: 'notification_vibrate_enabled',
  wrapUpAlertedDate: 'notified_wrapup_date',
  overtimeAlertedDate: 'notified_overtime_date',
  dismissedDate: 'notified_dismissed_date',
  snoozedUntil: 'notified_snoozed_until',
} as const;

function readBool(key: string, fallback: boolean): boolean {
  const value = localStorage.getItem(key);
  return value === null ? fallback : value === 'true';
}

function readInt(key: string, fallback: number): number {
  const value = localStorage.getItem(key);
  const parsed = value === null ? NaN : Number.parseInt(value, 10);
  return Number.isFinite(parsed) ? parsed : fallback;
}

/**
 * Deliver one alert through every channel (OS notification, beep, vibration).
 * Shared by `check` and `sendTestAlert` so the test exercises the real path.
 */
function deliver(
  alert: LeaveAlert,
  remainingMinutes: number,
  soundEnabled: boolean,
  vibrateEnabled: boolean,
): void {
  const t = (key: string, params?: Record<string, string | number>) =>
    translate(useLocaleStore.getState().locale, key, params);
  const minutes = Math.max(0, Math.round(Math.abs(remainingMinutes)));

  if (alert.kind === 'wrapUp') {
    showOsNotification(
      t('Wrap up and head out'),
      t('You have {minutes} min left before your planned leave time.', { minutes }),
      'chronowarden-wrapup',
    );
  } else {
    showOsNotification(
      t('Finish up and stop the day'),
      t('You are {minutes} min past your planned leave time.', { minutes }),
      'chronowarden-overtime',
    );
  }

  if (soundEnabled) beep(2);
  if (vibrateEnabled) vibrate(alert.kind === 'wrapUp' ? 400 : 600);
}

interface NotificationsState {
  enabled: boolean;
  thresholdMinutes: number;
  snoozeMinutes: number;
  soundEnabled: boolean;
  vibrateEnabled: boolean;
  /** Date ("YYYY-MM-DD") the wrap-up alert fired, or null. */
  wrapUpAlertedDate: string | null;
  /** Date the overtime alert fired, or null. */
  overtimeAlertedDate: string | null;
  dismissedDate: string | null;
  snoozedUntil: number | null;
  currentAlert: LeaveAlert | null;
  /** True while the banner shows a manually fired test alert. */
  isTestAlert: boolean;

  init: () => void;
  setEnabled: (value: boolean) => void;
  setThreshold: (value: number) => void;
  setSnooze: (value: number) => void;
  setSoundEnabled: (value: boolean) => void;
  setVibrateEnabled: (value: boolean) => void;
  /** Re-evaluate and deliver an alert when one is due. */
  check: (remainingMinutes: number, now?: Date) => void;
  /** Hide a real alert (e.g. the day ended or was deleted elsewhere). */
  clearAlert: () => void;
  /** Fire an alert through the real delivery path without affecting the day. */
  sendTestAlert: (kind?: LeaveAlertKind) => void;
  snooze: (now?: Date) => void;
  dismiss: (now?: Date) => void;
  resetForToday: () => void;
}

export const useNotificationsStore = create<NotificationsState>((set, get) => ({
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

  init: () => {
    const snoozeIso = localStorage.getItem(KEYS.snoozedUntil);
    set({
      enabled: readBool(KEYS.enabled, false),
      thresholdMinutes: readInt(KEYS.threshold, 30),
      snoozeMinutes: readInt(KEYS.snooze, 10),
      soundEnabled: readBool(KEYS.sound, true),
      vibrateEnabled: readBool(KEYS.vibrate, true),
      wrapUpAlertedDate: localStorage.getItem(KEYS.wrapUpAlertedDate),
      overtimeAlertedDate: localStorage.getItem(KEYS.overtimeAlertedDate),
      dismissedDate: localStorage.getItem(KEYS.dismissedDate),
      snoozedUntil: snoozeIso ? Number.parseInt(snoozeIso, 10) : null,
    });
    primeAudio();
    installAudioPrimer();
  },

  setEnabled: (value) => {
    localStorage.setItem(KEYS.enabled, String(value));
    if (value) {
      requestNotificationPermission();
      primeAudio();
    }
    set({ enabled: value });
  },

  setThreshold: (value) => {
    const clamped = Math.min(Math.max(value, 1), 120);
    localStorage.setItem(KEYS.threshold, String(clamped));
    set({ thresholdMinutes: clamped });
  },

  setSnooze: (value) => {
    const clamped = Math.min(Math.max(value, 1), 60);
    localStorage.setItem(KEYS.snooze, String(clamped));
    set({ snoozeMinutes: clamped });
  },

  setSoundEnabled: (value) => {
    localStorage.setItem(KEYS.sound, String(value));
    set({ soundEnabled: value });
  },

  setVibrateEnabled: (value) => {
    localStorage.setItem(KEYS.vibrate, String(value));
    set({ vibrateEnabled: value });
  },

  check: (remainingMinutes, now = new Date()) => {
    const state = get();
    if (!state.enabled) return;

    const today = toDateStr(now);
    const snoozed = state.snoozedUntil !== null && now.getTime() < state.snoozedUntil;

    if (state.snoozedUntil !== null && !snoozed) {
      localStorage.removeItem(KEYS.snoozedUntil);
      set({ snoozedUntil: null });
    }

    const alert = evaluateLeaveAlert({
      remainingMinutes,
      thresholdMinutes: state.thresholdMinutes,
      dismissed: state.dismissedDate === today,
      snoozed,
      wrapUpAlreadyAlerted: state.wrapUpAlertedDate === today,
      overtimeAlreadyAlerted: state.overtimeAlertedDate === today,
    });
    if (!alert) return;

    const firedKey = alert.kind === 'wrapUp' ? KEYS.wrapUpAlertedDate : KEYS.overtimeAlertedDate;
    localStorage.setItem(firedKey, today);
    set({
      currentAlert: alert,
      isTestAlert: false,
      ...(alert.kind === 'wrapUp' ? { wrapUpAlertedDate: today } : { overtimeAlertedDate: today }),
    });

    // The permission prompt needs a user gesture, so it is requested from the
    // settings toggle only. Here we just deliver if permission is already granted.
    deliver(alert, remainingMinutes, state.soundEnabled, state.vibrateEnabled);
  },

  clearAlert: () => {
    const { currentAlert, isTestAlert } = get();
    // Manually fired test banners stay until the user dismisses them.
    if (currentAlert === null || isTestAlert) return;
    set({ currentAlert: null });
  },

  sendTestAlert: (kind = 'wrapUp') => {
    const state = get();
    requestNotificationPermission();
    const remainingMinutes = kind === 'wrapUp' ? state.thresholdMinutes : -1;
    const alert: LeaveAlert = { kind, remainingMinutes };
    set({ currentAlert: alert, isTestAlert: true });
    deliver(alert, remainingMinutes, state.soundEnabled, state.vibrateEnabled);
  },

  snooze: (now = new Date()) => {
    // A test banner is not tied to the day, so just hide it.
    if (get().isTestAlert) {
      set({ currentAlert: null, isTestAlert: false });
      return;
    }
    const until = now.getTime() + get().snoozeMinutes * 60_000;
    localStorage.setItem(KEYS.snoozedUntil, String(until));
    // Clearing both fired flags re-arms whichever phase follows the snooze.
    localStorage.removeItem(KEYS.wrapUpAlertedDate);
    localStorage.removeItem(KEYS.overtimeAlertedDate);
    set({
      snoozedUntil: until,
      wrapUpAlertedDate: null,
      overtimeAlertedDate: null,
      currentAlert: null,
    });
  },

  dismiss: (now = new Date()) => {
    // A test banner is not tied to the day, so just hide it.
    if (get().isTestAlert) {
      set({ currentAlert: null, isTestAlert: false });
      return;
    }
    const today = toDateStr(now);
    localStorage.setItem(KEYS.dismissedDate, today);
    set({ dismissedDate: today, currentAlert: null });
  },

  resetForToday: () => {
    localStorage.removeItem(KEYS.wrapUpAlertedDate);
    localStorage.removeItem(KEYS.overtimeAlertedDate);
    localStorage.removeItem(KEYS.dismissedDate);
    localStorage.removeItem(KEYS.snoozedUntil);
    set({
      wrapUpAlertedDate: null,
      overtimeAlertedDate: null,
      dismissedDate: null,
      snoozedUntil: null,
      currentAlert: null,
      isTestAlert: false,
    });
  },
}));
