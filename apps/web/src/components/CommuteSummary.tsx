import { useT } from '../i18n';

/**
 * The "Commute breakdown" panel shown in the start/add/edit day dialogs.
 * Renders nothing when every commute value is zero (e.g. working from home).
 */
export function CommuteSummary({
  morningOverhead,
  morningProductive,
  eveningOverhead,
  eveningProductive,
}: {
  morningOverhead: number;
  morningProductive: number;
  eveningOverhead: number;
  eveningProductive: number;
}) {
  const t = useT();
  const total = morningOverhead + morningProductive + eveningOverhead + eveningProductive;
  if (total === 0) return null;

  return (
    <div className="rounded-lg bg-muted/50 p-3">
      <p className="text-xs uppercase tracking-wide text-muted-foreground">{t('Commute breakdown')}</p>
      <p className="mt-1 text-xs">
        {t('Morning: {overhead} min walk, {productive} min train work', {
          overhead: morningOverhead,
          productive: morningProductive,
        })}
      </p>
      <p className="text-xs">
        {t('Evening: {overhead} min walk, {productive} min train work', {
          overhead: eveningOverhead,
          productive: eveningProductive,
        })}
      </p>
      <p className="text-xs font-semibold">{t('Total: {minutes} min commute', { minutes: total })}</p>
    </div>
  );
}
