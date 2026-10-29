import { create } from 'zustand';

import { translate, useLocaleStore } from '../i18n';
import { toDateStr } from '../lib/date';
import { evaluateLeaveAlert, type LeaveAlert } from '../lib/domain/leave-alert';
import { beep, primeAudio, requestNotificationPermission, showOsNotification, vibrate } from '../lib/notify';

const KEYS = {
  enabled: 'notifications_enabled',
  threshold: 'notification_threshold_minutes',
  snooze: 'notification_snooze_minutes',
  sound: 'notification_sound_enabled',
  vibrate: 'notification_vibrate_enabled',
  alertedDate: 'notified_date',
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

interface NotificationsState {
  enabled: boolean;
  thresholdMinutes: number;
  snoozeMinutes: number;
  soundEnabled: boolean;
  vibrateEnabled: boolean;
  alertedDate: string | null;
  dismissedDate: string | null;
  snoozedUntil: number | null;
  currentAlert: LeaveAlert | null;

  init: () => void;
  setEnabled: (value: boolean) => void;
  setThreshold: (value: number) => void;
  setSnooze: (value: number) => void;
  setSoundEnabled: (value: boolean) => void;
  setVibrateEnabled: (value: boolean) => void;
  /** Re-evaluate and deliver an alert when one is due. */
  check: (remainingMinutes: number, now?: Date) => void;
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
  alertedDate: null,
  dismissedDate: null,
  snoozedUntil: null,
  currentAlert: null,

  init: () => {
    const snoozeIso = localStorage.getItem(KEYS.snoozedUntil);
    set({
      enabled: readBool(KEYS.enabled, false),
      thresholdMinutes: readInt(KEYS.threshold, 30),
      snoozeMinutes: readInt(KEYS.snooze, 10),
      soundEnabled: readBool(KEYS.sound, true),
      vibrateEnabled: readBool(KEYS.vibrate, true),
      alertedDate: localStorage.getItem(KEYS.alertedDate),
      dismissedDate: localStorage.getItem(KEYS.dismissedDate),
      snoozedUntil: snoozeIso ? Number.parseInt(snoozeIso, 10) : null,
    });
    primeAudio();
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
      alreadyAlerted: state.alertedDate === today,
    });
    if (!alert) return;

    localStorage.setItem(KEYS.alertedDate, today);
    set({ currentAlert: alert, alertedDate: today });

    requestNotificationPermission();
    if (state.soundEnabled) beep(2);
    if (state.vibrateEnabled) vibrate(400);

    const t = (key: string, params?: Record<string, string | number>) =>
      translate(useLocaleStore.getState().locale, key, params);
    const minutes = Math.round(Math.abs(remainingMinutes));
    if (alert.kind === 'wrapUp') {
      showOsNotification(
        t('Wrap up and head out'),
        t('You have {minutes} min left before your planned leave time.', { minutes }),
      );
    } else {
      showOsNotification(
        t('Finish up and stop the day'),
        t('You are {minutes} min past your planned leave time.', { minutes }),
      );
    }
  },

  snooze: (now = new Date()) => {
    const until = now.getTime() + get().snoozeMinutes * 60_000;
    localStorage.setItem(KEYS.snoozedUntil, String(until));
    // Clearing the delivered date re-arms the alert once the snooze expires.
    localStorage.removeItem(KEYS.alertedDate);
    set({ snoozedUntil: until, alertedDate: null, currentAlert: null });
  },

  dismiss: (now = new Date()) => {
    const today = toDateStr(now);
    localStorage.setItem(KEYS.dismissedDate, today);
    set({ dismissedDate: today, currentAlert: null });
  },

  resetForToday: () => {
    localStorage.removeItem(KEYS.alertedDate);
    localStorage.removeItem(KEYS.dismissedDate);
    localStorage.removeItem(KEYS.snoozedUntil);
    set({ alertedDate: null, dismissedDate: null, snoozedUntil: null, currentAlert: null });
  },
}));
