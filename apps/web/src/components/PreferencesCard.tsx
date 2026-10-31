import { useEffect, useState } from 'react';

import { useT } from '../i18n';
import { usePreferences, useSavePreferences } from '../queries/settings';
import type { Preferences } from '../services/settings';
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
 *
 * Writes go through {@link useSavePreferences} so the query cache (and therefore
 * the Overview/History views) refresh immediately.
 */
export function PreferencesCard() {
  const t = useT();
  const prefsQuery = usePreferences();
  const save = useSavePreferences();

  const [defaultFlex, setDefaultFlex] = useState('0');
  const [defaultLunch, setDefaultLunch] = useState('0');
  const [sliderStep, setSliderStep] = useState('5');
  const [initialised, setInitialised] = useState(false);

  useEffect(() => {
    if (!prefsQuery.data || initialised) return;
    setDefaultFlex(String(prefsQuery.data.defaultFlexMinutes));
    setDefaultLunch(String(prefsQuery.data.defaultLunchMinutes));
    setSliderStep(String(prefsQuery.data.sliderStepMinutes));
    setInitialised(true);
  }, [prefsQuery.data, initialised]);

  function patch(next: Partial<Preferences>) {
    void save.mutateAsync(next);
  }

  return (
    <Card>
      <CardHeader title={t('Preferences')} />
      <CardContent className="space-y-3">
        <ToggleRow
          label={t('Show weekends')}
          description={t('Weekend days are shown in history and overview.')}
          checked={prefsQuery.data?.showWeekends ?? true}
          onChange={(value) => patch({ showWeekends: value })}
        />
        <ToggleRow
          label={t('Non-work time')}
          description={t('Track time spent on errands or other non-work activities.')}
          checked={prefsQuery.data?.nonWorkEnabled ?? true}
          onChange={(value) => patch({ nonWorkEnabled: value })}
        />

        <div className="grid gap-4 pt-2 sm:grid-cols-2 lg:grid-cols-3">
          <Field label={t('Default flex minutes')} htmlFor="defaultFlex">
            <Input
              id="defaultFlex"
              type="number"
              inputMode="numeric"
              value={defaultFlex}
              onChange={(event) => setDefaultFlex(event.target.value)}
              onBlur={() => patch({ defaultFlexMinutes: Number(defaultFlex) || 0 })}
            />
          </Field>
          <Field label={t('Default lunch minutes')} htmlFor="defaultLunch">
            <Input
              id="defaultLunch"
              type="number"
              inputMode="numeric"
              value={defaultLunch}
              onChange={(event) => setDefaultLunch(event.target.value)}
              onBlur={() => patch({ defaultLunchMinutes: Number(defaultLunch) || 0 })}
            />
          </Field>
          <Field label={t('Slider step (min)')} htmlFor="sliderStep">
            <Input
              id="sliderStep"
              type="number"
              inputMode="numeric"
              value={sliderStep}
              onChange={(event) => setSliderStep(event.target.value)}
              onBlur={() => patch({ sliderStepMinutes: Number(sliderStep) || 5 })}
            />
          </Field>
        </div>
      </CardContent>
    </Card>
  );
}
