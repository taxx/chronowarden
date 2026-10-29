import { Bell, BellRing } from 'lucide-react';

import { Button, Card, CardContent, CardHeader, Field, Input } from './ui';
import { useT } from '../i18n';
import {
  audioState,
  beep,
  notificationPermission,
  primeAudio,
  requestNotificationPermission,
  showOsNotification,
  vibrate,
  vibrationSupported,
} from '../lib/notify';
import { useNotificationsStore } from '../state/notifications';
import { useToastStore } from '../state/toast';

/** Leave-time alert settings. */
export function NotificationSettingsCard() {
  const t = useT();
  const enabled = useNotificationsStore((state) => state.enabled);
  const threshold = useNotificationsStore((state) => state.thresholdMinutes);
  const snooze = useNotificationsStore((state) => state.snoozeMinutes);
  const sound = useNotificationsStore((state) => state.soundEnabled);
  const vibrateEnabled = useNotificationsStore((state) => state.vibrateEnabled);
  const setEnabled = useNotificationsStore((state) => state.setEnabled);
  const setThreshold = useNotificationsStore((state) => state.setThreshold);
  const setSnooze = useNotificationsStore((state) => state.setSnooze);
  const setSound = useNotificationsStore((state) => state.setSoundEnabled);
  const setVibrate = useNotificationsStore((state) => state.setVibrateEnabled);
  const pushToast = useToastStore((state) => state.push);

  const permission = notificationPermission();

  function sendTest() {
    primeAudio();
    if (sound) beep(2);
    if (vibrateEnabled) vibrate(300);
    showOsNotification(t('ChronoWarden'), t('Test alert fired — check for sound & vibration'));
    pushToast(t('Test alert fired — check for sound & vibration'), 'success');
  }

  return (
    <Card>
      <CardHeader
        title={
          <span className="flex items-center gap-2">
            <Bell className="h-4 w-4 text-primary" />
            {t('Notifications')}
          </span>
        }
        description={t('Permission') + ': ' + permission + ' · ' + t('Audio') + ': ' + audioState()}
      />
      <CardContent className="space-y-4">
        <label className="flex items-center gap-2 text-sm">
          <input type="checkbox" checked={enabled} onChange={(e) => setEnabled(e.target.checked)} />
          {t('Enable notifications')}
        </label>

        <div className="grid gap-4 sm:grid-cols-2">
          <Field label={t('Alert threshold (min)')} htmlFor="threshold">
            <Input
              id="threshold"
              type="number"
              inputMode="numeric"
              value={String(threshold)}
              onChange={(e) => setThreshold(Number(e.target.value) || 1)}
            />
          </Field>
          <Field label={t('Snooze (min)')} htmlFor="snooze">
            <Input
              id="snooze"
              type="number"
              inputMode="numeric"
              value={String(snooze)}
              onChange={(e) => setSnooze(Number(e.target.value) || 1)}
            />
          </Field>
        </div>

        <label className="flex items-center gap-2 text-sm">
          <input type="checkbox" checked={sound} onChange={(e) => setSound(e.target.checked)} />
          {t('Sound')}
        </label>
        <label className="flex items-center gap-2 text-sm">
          <input type="checkbox" checked={vibrateEnabled} onChange={(e) => setVibrate(e.target.checked)} />
          {t('Vibration')} {vibrationSupported() ? '' : `(${t('unsupported')})`}
        </label>

        <div className="flex flex-wrap gap-2 pt-1">
          {permission !== 'granted' ? (
            <Button variant="outline" size="sm" onClick={() => requestNotificationPermission()}>
              <Bell className="h-3.5 w-3.5" />
              {t('Allow notifications')}
            </Button>
          ) : null}
          <Button variant="secondary" size="sm" onClick={sendTest}>
            <BellRing className="h-3.5 w-3.5" />
            {t('Send test')}
          </Button>
        </div>
      </CardContent>
    </Card>
  );
}
