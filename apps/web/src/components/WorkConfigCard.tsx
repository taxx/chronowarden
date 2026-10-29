import { useEffect, useState } from 'react';

import { Button, Card, Field, Input, Spinner } from '../components/ui';
import { useT } from '../i18n';
import { useSaveWorkConfig, useWorkConfig } from '../queries/settings';

/** Edit the per-user expected work time, including the seasonal reduced period. */
export function WorkConfigCard() {
  const t = useT();
  const query = useWorkConfig();
  const save = useSaveWorkConfig();

  const [defaultMinutes, setDefaultMinutes] = useState('480');
  const [reducedMinutes, setReducedMinutes] = useState('');
  const [startWeek, setStartWeek] = useState('');
  const [endWeek, setEndWeek] = useState('');
  const [saved, setSaved] = useState(false);

  useEffect(() => {
    const config = query.data;
    setDefaultMinutes(String(config?.defaultExpectedMinutes ?? 480));
    setReducedMinutes(config?.reducedExpectedMinutes != null ? String(config.reducedExpectedMinutes) : '');
    setStartWeek(config?.reducedStartWeek != null ? String(config.reducedStartWeek) : '');
    setEndWeek(config?.reducedEndWeek != null ? String(config.reducedEndWeek) : '');
  }, [query.data]);

  async function onSave() {
    setSaved(false);
    await save.mutateAsync({
      defaultExpectedMinutes: Number(defaultMinutes) || 480,
      reducedExpectedMinutes: reducedMinutes ? Number(reducedMinutes) : null,
      reducedStartWeek: startWeek ? Number(startWeek) : null,
      reducedEndWeek: endWeek ? Number(endWeek) : null,
    });
    setSaved(true);
  }

  if (query.isLoading) {
    return (
      <Card>
        <div className="flex justify-center py-6">
          <Spinner />
        </div>
      </Card>
    );
  }

  return (
    <Card>
      <h2 className="text-lg font-semibold text-foreground">{t('Work hours')}</h2>

      <div className="mt-4 grid gap-4 sm:grid-cols-2">
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
        <Field label={t('Reduced start week')} htmlFor="startWeek">
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

      <div className="mt-4 flex items-center gap-3">
        <Button onClick={() => void onSave()} disabled={save.isPending}>
          {t('Save')}
        </Button>
        {saved ? <span className="text-sm text-success">{t('Saved')}</span> : null}
      </div>
    </Card>
  );
}
