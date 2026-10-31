import { useEffect, useState } from 'react';
import { Pencil, Plus, Trash2 } from 'lucide-react';

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
import { useToastStore } from '../state/toast';
import {
  Button,
  Card,
  CardContent,
  CardHeader,
  ConfirmDialog,
  EmptyState,
  Field,
  Input,
  Modal,
  SelectField,
  Spinner,
} from './ui';

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
    setValues((prev) => ({ ...prev, [key]: Number(value) || 0 }));

  return (
    <Modal
      open={open}
      onClose={onClose}
      title={initial ? t('Edit preset') : t('Add preset')}
      footer={
        <div className="flex justify-end gap-2">
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
      }
    >
      <div className="grid gap-4 sm:grid-cols-2">
        <div className="sm:col-span-2">
          <Field label={t('Name')} htmlFor="presetName">
            <Input
              id="presetName"
              value={values.name}
              onChange={(event) => setValues((prev) => ({ ...prev, name: event.target.value }))}
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
            <SelectField
              id="commuteMode"
              value={values.commuteMode}
              onValueChange={(value) =>
                setValues((prev) => ({ ...prev, commuteMode: value as CommuteMode }))
              }
              options={[
                { value: 'none', label: t('None') },
                { value: 'transit', label: t('Transit') },
                { value: 'car', label: t('Car') },
                { value: 'vespa', label: t('Vespa') },
              ]}
            />
          </Field>
        </div>
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
  const pushToast = useToastStore((state) => state.push);

  const [open, setOpen] = useState(false);
  const [editing, setEditing] = useState<TravelPreset | null>(null);
  const [deleting, setDeleting] = useState<TravelPreset | null>(null);

  const presets = query.data ?? [];

  async function submit(values: FormValues) {
    try {
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
      pushToast(t('Saved'), 'success');
    } catch {
      pushToast(t('Could not save'), 'error');
    }
  }

  async function confirmDelete() {
    if (!deleting?.id) return;
    try {
      await remove.mutateAsync(deleting.id);
      pushToast(t('Saved'), 'success');
    } catch {
      pushToast(t('Could not save'), 'error');
    } finally {
      setDeleting(null);
    }
  }

  return (
    <Card>
      <CardHeader
        title={t('Travel presets')}
        description={t('Commute scenarios with overhead buffer.')}
        action={
          <Button
            size="sm"
            onClick={() => {
              setEditing(null);
              setOpen(true);
            }}
          >
            <Plus className="h-3.5 w-3.5" />
            {t('Add preset')}
          </Button>
        }
      />
      <CardContent>
        {query.isLoading ? (
          <div className="flex justify-center py-6">
            <Spinner />
          </div>
        ) : presets.length === 0 ? (
          <EmptyState title={t('No presets yet')} />
        ) : (
          <ul className="divide-y divide-border">
            {presets.map((preset) => (
              <li
                key={preset.id ?? preset.name}
                className="flex flex-wrap items-center justify-between gap-3 py-3 first:pt-0 last:pb-0"
              >
                <div>
                  <p className="font-medium">{preset.name}</p>
                  <p className="text-xs text-muted-foreground">
                    {t('Overhead')}: {defaultOverheadMinutes(preset)} min · {t('Productive')}:{' '}
                    {productiveCommuteMinutes(preset)} min · {preset.commuteMode}
                  </p>
                </div>
                <div className="flex gap-1">
                  <Button
                    variant="ghost"
                    size="icon"
                    aria-label={t('Edit preset')}
                    onClick={() => {
                      setEditing(preset);
                      setOpen(true);
                    }}
                  >
                    <Pencil className="h-4 w-4" />
                  </Button>
                  <Button
                    variant="ghost"
                    size="icon"
                    aria-label={t('Delete preset?')}
                    onClick={() => setDeleting(preset)}
                  >
                    <Trash2 className="h-4 w-4 text-destructive" />
                  </Button>
                </div>
              </li>
            ))}
          </ul>
        )}
      </CardContent>

      <PresetDialog open={open} initial={editing} onClose={() => setOpen(false)} onSubmit={submit} />

      <ConfirmDialog
        open={deleting != null}
        title={t('Delete preset?')}
        description={t('Delete "{name}"?', { name: deleting?.name ?? '' })}
        busy={remove.isPending}
        onClose={() => setDeleting(null)}
        onConfirm={confirmDelete}
      />
    </Card>
  );
}
