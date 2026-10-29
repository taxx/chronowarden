import { useEffect, useState } from 'react';

import { useT } from '../i18n';
import { readSettings, writeSettings } from '../services/settings';
import { useDek } from '../state/auth';
import { Card, Field, Input } from './ui';

/**
 * Local preferences stored inside the encrypted settings payload:
 * weekend visibility, default flex minutes, slider step and non-work toggle.
 */
export function PreferencesCard() {
  const t = useT();
  const dek = useDek();

  const [weekend, setWeekend] = useState(true);
  const [defaultFlex, setDefaultFlex] = useState('0');
  const [sliderStep, setSliderStep] = useState('5');
  const [nonWork, setNonWork] = useState(true);
  const [loaded, setLoaded] = useState(false);

  useEffect(() => {
    if (!dek || loaded) return;
    let cancelled = false;
    void readSettings(dek).then((settings) => {
      if (cancelled) return;
      setWeekend((settings['show_weekends'] as boolean | null) ?? true);
      setDefaultFlex(String((settings['default_flex_minutes'] as number | null) ?? 0));
      setSliderStep(String((settings['slider_step_minutes'] as number | null) ?? 5));
      setNonWork((settings['non_work_enabled'] as boolean | null) ?? true);
      setLoaded(true);
    });
    return () => {
      cancelled = true;
    };
  }, [dek, loaded]);

  async function persist(patch: Record<string, unknown>) {
    if (!dek) return;
    const settings = await readSettings(dek);
    Object.assign(settings, patch);
    await writeSettings(settings, dek);
  }

  return (
    <Card>
      <h2 className="text-lg font-semibold text-foreground">{t('Preferences')}</h2>

      <label className="mt-4 flex items-center gap-2 text-sm text-foreground">
        <input
          type="checkbox"
          checked={weekend}
          onChange={(event) => {
            setWeekend(event.target.checked);
            void persist({ show_weekends: event.target.checked });
          }}
        />
        {t('Show weekends')}
      </label>

      <label className="mt-2 flex items-center gap-2 text-sm text-foreground">
        <input
          type="checkbox"
          checked={nonWork}
          onChange={(event) => {
            setNonWork(event.target.checked);
            void persist({ non_work_enabled: event.target.checked });
          }}
        />
        {t('Non-work time')}
      </label>

      <div className="mt-4 grid gap-4 sm:grid-cols-2">
        <Field label={t('Default flex minutes')} htmlFor="defaultFlex">
          <Input
            id="defaultFlex"
            type="number"
            inputMode="numeric"
            value={defaultFlex}
            onChange={(event) => setDefaultFlex(event.target.value)}
            onBlur={() => void persist({ default_flex_minutes: Number(defaultFlex) || 0 })}
          />
        </Field>
        <Field label={t('Slider step (min)')} htmlFor="sliderStep">
          <Input
            id="sliderStep"
            type="number"
            inputMode="numeric"
            value={sliderStep}
            onChange={(event) => setSliderStep(event.target.value)}
            onBlur={() => void persist({ slider_step_minutes: Number(sliderStep) || 5 })}
          />
        </Field>
      </div>
    </Card>
  );
}
