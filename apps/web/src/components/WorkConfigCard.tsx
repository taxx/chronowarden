import { useEffect, useState } from 'react';

import { Button, Card, CardContent, CardHeader, Field, Input } from '../components/ui';
import { useT } from '../i18n';
import { useSaveWorkConfig, useWorkConfig } from '../queries/settings';
import { useToastStore } from '../state/toast';

/** Edit the per-user expected work time, including the seasonal reduced period. */
export function WorkConfigCard() {
  const t = useT();
  const query = useWorkConfig();
  const save = useSaveWorkConfig();
  const pushToast = useToastStore((state) => state.push);

  const [defaultMinutes, setDefaultMinutes] = useState('480');
  const [reducedMinutes, setReducedMinutes] = useState('');
  const [startWeek, setStartWeek] = useState('');
  const [endWeek, setEndWeek] = useState('');

  useEffect(() => {
    const config = query.data;
    setDefaultMinutes(String(config?.defaultExpectedMinutes ?? 480));
    setReducedMinutes(config?.reducedExpectedMinutes != null ? String(config.reducedExpectedMinutes) : '');
    setStartWeek(config?.reducedStartWeek != null ? String(config.reducedStartWeek) : '');
    setEndWeek(config?.reducedEndWeek != null ? String(config.reducedEndWeek) : '');
  }, [query.data]);

  async function onSave() {
    try {
      await save.mutateAsync({
        defaultExpectedMinutes: Number(defaultMinutes) || 480,
        reducedExpectedMinutes: reducedMinutes ? Number(reducedMinutes) : null,
        reducedStartWeek: startWeek ? Number(startWeek) : null,
        reducedEndWeek: endWeek ? Number(endWeek) : null,
      });
      pushToast(t('Saved'), 'success');
    } catch {
      pushToast(t('Could not save'), 'error');
    }
  }

  return (
    <Card>
      <CardHeader
        title={t('Work hours')}
        description={t('Configure your expected work time per day.')}
      />
      <CardContent className="space-y-4">
        <div className="grid gap-4 sm:grid-cols-2">
          <Field label={t('Default expected minutes')} htmlFor="defaultMinutes">
            <Input
              id="defaultMinutes"
              type="number"
              inputMode="numeric"
              value={defaultMinutes}
              onChange={(event) => setDefaultMinutes(event.target.value)}
            />
          </Field>
          <Field label={t('Reduced expected minutes')} htmlFor="reducedMinutes">
            <Input
              id="reducedMinutes"
              type="number"
              inputMode="numeric"
              value={reducedMinutes}
              onChange={(event) => setReducedMinutes(event.target.value)}
            />
          </Field>
          <Field
            label={t('Reduced start week')}
            htmlFor="startWeek"
            hint={t('Leave reduced fields empty to disable the reduced period.')}
          >
            <Input
              id="startWeek"
              type="number"
              inputMode="numeric"
              value={startWeek}
              onChange={(event) => setStartWeek(event.target.value)}
            />
          </Field>
          <Field label={t('Reduced end week')} htmlFor="endWeek">
            <Input
              id="endWeek"
              type="number"
              inputMode="numeric"
              value={endWeek}
              onChange={(event) => setEndWeek(event.target.value)}
            />
          </Field>
        </div>
        <div>
          <Button onClick={() => void onSave()} disabled={save.isPending}>
            {t('Save')}
          </Button>
        </div>
      </CardContent>
    </Card>
  );
}
