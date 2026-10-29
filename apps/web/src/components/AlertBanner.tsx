import { Button } from './ui';
import { useT } from '../i18n';
import { useNotificationsStore } from '../state/notifications';

/** In-app leave-time alert with snooze/dismiss. */
export function AlertBanner() {
  const t = useT();
  const alert = useNotificationsStore((state) => state.currentAlert);
  const snooze = useNotificationsStore((state) => state.snooze);
  const dismiss = useNotificationsStore((state) => state.dismiss);

  if (!alert) return null;

  const minutes = Math.round(Math.abs(alert.remainingMinutes));
  const message =
    alert.kind === 'wrapUp'
      ? t('You have {minutes} min left before your planned leave time.', { minutes })
      : t('You are {minutes} min past your planned leave time.', { minutes });

  return (
    <div
      role="alert"
      className={
        'mb-4 flex flex-wrap items-center justify-between gap-3 rounded-xl border p-4 ' +
        (alert.kind === 'wrapUp'
          ? 'border-sky-700 bg-sky-950/50 text-sky-100'
          : 'border-amber-700 bg-amber-950/50 text-amber-100')
      }
    >
      <div>
        <p className="font-medium">
          {alert.kind === 'wrapUp' ? t('Wrap up and head out') : t('Finish up and stop the day')}
        </p>
        <p className="text-sm opacity-90">{message}</p>
      </div>
      <div className="flex gap-2">
        <Button variant="ghost" onClick={() => snooze()}>
          {t('Snooze')}
        </Button>
        <Button variant="ghost" onClick={() => dismiss()}>
          {t('Dismiss')}
        </Button>
      </div>
    </div>
  );
}
