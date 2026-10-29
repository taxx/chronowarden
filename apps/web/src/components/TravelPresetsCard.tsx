import { useEffect, useState } from 'react';

import { useT } from '../i18n';
import {
  defaultOverheadMinutes,
  productiveCommuteMinutes,
  type CommuteMode,
  type TravelPreset,
} from '../lib/domain/travel-preset';
import {
  useCreateTravelPreset,
  useDeleteTravelPreset,
  useTravelPresets,
  useUpdateTravelPreset,
} from '../queries/travel-presets';
import { Button, Card, Field, Input, Modal, Spinner } from './ui';

interface FormValues {
  name: string;
  morningOverheadMinutes: number;
  morningProductiveCommuteMinutes: number;
  eveningOverheadMinutes: number;
  eveningProductiveCommuteMinutes: number;
  commuteMode: CommuteMode;
}

const EMPTY: FormValues = {
  name: '',
  morningOverheadMinutes: 0,
  morningProductiveCommuteMinutes: 0,
  eveningOverheadMinutes: 0,
  eveningProductiveCommuteMinutes: 0,
  commuteMode: 'none',
};

function PresetDialog({
  open,
  initial,
  onClose,
  onSubmit,
}: {
  open: boolean;
  initial: TravelPreset | null;
  onClose: () => void;
  onSubmit: (values: FormValues) => Promise<void>;
}) {
  const t = useT();
  const [values, setValues] = useState<FormValues>(EMPTY);
  const [busy, setBusy] = useState(false);

  useEffect(() => {
    if (!open) return;
    setValues(
      initial
        ? {
            name: initial.name,
            morningOverheadMinutes: initial.morningOverheadMinutes,
            morningProductiveCommuteMinutes: initial.morningProductiveCommuteMinutes,
            eveningOverheadMinutes: initial.eveningOverheadMinutes,
            eveningProductiveCommuteMinutes: initial.eveningProductiveCommuteMinutes,
            commuteMode: initial.commuteMode,
          }
        : EMPTY,
    );
  }, [open, initial]);

  const setNumber = (key: keyof FormValues) => (value: string) =>
    setValues({ ...values, [key]: Number(value) || 0 });

  return (
    <Modal open={open} onClose={onClose} title={initial ? t('Edit preset') : t('Add preset')}>
      <div className="grid gap-4 sm:grid-cols-2">
        <div className="sm:col-span-2">
          <Field label={t('Name')} htmlFor="presetName">
            <Input
              id="presetName"
              value={values.name}
              onChange={(event) => setValues({ ...values, name: event.target.value })}
            />
          </Field>
        </div>
        <Field label={t('Morning overhead')} htmlFor="morningOverhead">
          <Input
            id="morningOverhead"
            type="number"
            inputMode="numeric"
            value={String(values.morningOverheadMinutes)}
            onChange={(event) => setNumber('morningOverheadMinutes')(event.target.value)}
          />
        </Field>
        <Field label={t('Morning productive')} htmlFor="morningProductive">
          <Input
            id="morningProductive"
            type="number"
            inputMode="numeric"
            value={String(values.morningProductiveCommuteMinutes)}
            onChange={(event) => setNumber('morningProductiveCommuteMinutes')(event.target.value)}
          />
        </Field>
        <Field label={t('Evening overhead')} htmlFor="eveningOverhead">
          <Input
            id="eveningOverhead"
            type="number"
            inputMode="numeric"
            value={String(values.eveningOverheadMinutes)}
            onChange={(event) => setNumber('eveningOverheadMinutes')(event.target.value)}
          />
        </Field>
        <Field label={t('Evening productive')} htmlFor="eveningProductive">
          <Input
            id="eveningProductive"
            type="number"
            inputMode="numeric"
            value={String(values.eveningProductiveCommuteMinutes)}
            onChange={(event) => setNumber('eveningProductiveCommuteMinutes')(event.target.value)}
          />
        </Field>
        <div className="sm:col-span-2">
          <Field label={t('Commute mode')} htmlFor="commuteMode">
            <select
              id="commuteMode"
              className="w-full rounded-lg border border-input bg-card px-3 py-2 text-sm text-foreground"
              value={values.commuteMode}
              onChange={(event) =>
                setValues({ ...values, commuteMode: event.target.value as CommuteMode })
              }
            >
              <option value="none">{t('None')}</option>
              <option value="transit">{t('Transit')}</option>
              <option value="car">{t('Car')}</option>
              <option value="vespa">{t('Vespa')}</option>
            </select>
          </Field>
        </div>
      </div>

      <div className="mt-6 flex justify-end gap-2">
        <Button variant="ghost" onClick={onClose}>
          {t('Cancel')}
        </Button>
        <Button
          disabled={busy || !values.name.trim()}
          onClick={() => {
            setBusy(true);
            void onSubmit(values).finally(() => setBusy(false));
          }}
        >
          {t('Save')}
        </Button>
      </div>
    </Modal>
  );
}

export function TravelPresetsCard() {
  const t = useT();
  const query = useTravelPresets();
  const create = useCreateTravelPreset();
  const update = useUpdateTravelPreset();
  const remove = useDeleteTravelPreset();

  const [open, setOpen] = useState(false);
  const [editing, setEditing] = useState<TravelPreset | null>(null);
  const [error, setError] = useState<string | null>(null);

  const presets = query.data ?? [];

  async function run(action: () => Promise<unknown>) {
    setError(null);
    try {
      await action();
    } catch {
      setError(t('Could not save'));
    }
  }

  async function submit(values: FormValues) {
    await run(async () => {
      if (editing?.id) {
        await update.mutateAsync({
          id: editing.id,
          fields: {
            name: values.name,
            morning_overhead_minutes: values.morningOverheadMinutes,
            morning_productive_commute_minutes: values.morningProductiveCommuteMinutes,
            evening_overhead_minutes: values.eveningOverheadMinutes,
            evening_productive_commute_minutes: values.eveningProductiveCommuteMinutes,
            commute_mode: values.commuteMode,
          },
        });
      } else {
        await create.mutateAsync({
          name: values.name,
          morningOverheadMinutes: values.morningOverheadMinutes,
          morningProductiveCommuteMinutes: values.morningProductiveCommuteMinutes,
          eveningOverheadMinutes: values.eveningOverheadMinutes,
          eveningProductiveCommuteMinutes: values.eveningProductiveCommuteMinutes,
          commuteMode: values.commuteMode,
        });
      }
      setOpen(false);
    });
  }

  return (
    <Card>
      <div className="flex items-center justify-between gap-4">
        <h2 className="text-lg font-semibold text-foreground">{t('Travel presets')}</h2>
        <Button
          onClick={() => {
            setEditing(null);
            setOpen(true);
          }}
        >
          {t('Add preset')}
        </Button>
      </div>

      {query.isLoading ? (
        <div className="flex justify-center py-6">
          <Spinner />
        </div>
      ) : presets.length === 0 ? (
        <p className="mt-4 text-sm text-muted-foreground">{t('No presets yet')}</p>
      ) : (
        <ul className="mt-4 divide-y divide-border">
          {presets.map((preset) => (
            <li
              key={preset.id ?? preset.name}
              className="flex flex-wrap items-center justify-between gap-3 py-3"
            >
              <div>
                <p className="font-medium text-foreground">{preset.name}</p>
                <p className="text-xs text-muted-foreground">
                  {t('Overhead')}: {defaultOverheadMinutes(preset)} min · {t('Productive')}:{' '}
                  {productiveCommuteMinutes(preset)} min · {preset.commuteMode}
                </p>
              </div>
              <div className="flex gap-2">
                <Button
                  variant="ghost"
                  onClick={() => {
                    setEditing(preset);
                    setOpen(true);
                  }}
                >
                  {t('Edit preset')}
                </Button>
                <Button
                  variant="ghost"
                  onClick={() => {
                    if (preset.id && window.confirm(t('Delete preset?'))) {
                      void run(() => remove.mutateAsync(preset.id!));
                    }
                  }}
                >
                  {t('Delete')}
                </Button>
              </div>
            </li>
          ))}
        </ul>
      )}

      {error ? <p className="mt-3 text-sm text-destructive">{error}</p> : null}

      <PresetDialog open={open} initial={editing} onClose={() => setOpen(false)} onSubmit={submit} />
    </Card>
  );
}
