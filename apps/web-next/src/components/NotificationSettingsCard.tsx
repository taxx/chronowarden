import { Card, Field, Input } from './ui';
import { useT } from '../i18n';
import { audioState, notificationPermission, vibrationSupported } from '../lib/notify';
import { useNotificationsStore } from '../state/notifications';

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

  return (
    <Card>
      <h2 className="text-lg font-semibold text-white">{t('Notifications')}</h2>

      <label className="mt-4 flex items-center gap-2 text-sm text-slate-300">
        <input type="checkbox" checked={enabled} onChange={(e) => setEnabled(e.target.checked)} />
        {t('Enable notifications')}
      </label>

      <div className="mt-4 grid gap-4 sm:grid-cols-2">
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

      <label className="mt-4 flex items-center gap-2 text-sm text-slate-300">
        <input type="checkbox" checked={sound} onChange={(e) => setSound(e.target.checked)} />
        {t('Sound')}
      </label>
      <label className="mt-2 flex items-center gap-2 text-sm text-slate-300">
        <input type="checkbox" checked={vibrateEnabled} onChange={(e) => setVibrate(e.target.checked)} />
        {t('Vibration')}
      </label>

      <p className="mt-4 text-xs text-slate-500">
        {t('Permission')}: {notificationPermission()} · {t('Audio')}: {audioState()} ·{' '}
        {t('Vibration')}: {vibrationSupported() ? t('Yes') : t('No')}
      </p>
    </Card>
  );
}
