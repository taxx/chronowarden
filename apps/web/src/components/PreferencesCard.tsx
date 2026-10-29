import { useEffect, useState } from 'react';

import { useT } from '../i18n';
import { readSettings, writeSettings } from '../services/settings';
import { useDek } from '../state/auth';
import { Card, CardContent, CardHeader, Field, Input, Switch } from './ui';

function ToggleRow({
  label,
  description,
  checked,
  onChange,
}: {
  label: string;
  description?: string;
  checked: boolean;
  onChange: (value: boolean) => void;
}) {
  return (
    <div className="flex items-center justify-between gap-4 py-1">
      <div>
        <p className="text-sm font-medium">{label}</p>
        {description ? <p className="text-xs text-muted-foreground">{description}</p> : null}
      </div>
      <Switch checked={checked} onCheckedChange={onChange} />
    </div>
  );
}

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
      <CardHeader title={t('Preferences')} />
      <CardContent className="space-y-3">
        <ToggleRow
          label={t('Show weekends')}
          checked={weekend}
          onChange={(value) => {
            setWeekend(value);
            void persist({ show_weekends: value });
          }}
        />
        <ToggleRow
          label={t('Non-work time')}
          description={t('Track time spent on errands or other non-work activities.')}
          checked={nonWork}
          onChange={(value) => {
            setNonWork(value);
            void persist({ non_work_enabled: value });
          }}
        />

        <div className="grid gap-4 pt-2 sm:grid-cols-2">
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
      </CardContent>
    </Card>
  );
}
