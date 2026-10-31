import { zodResolver } from '@hookform/resolvers/zod';
import { useEffect, useState } from 'react';
import { useForm } from 'react-hook-form';
import { z } from 'zod';
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
  Form,
  FormControl,
  FormField,
  FormItem,
  FormLabel,
  FormMessage,
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

const NUM_RE = /^\d+$/;

function makeSchema(t: (key: string) => string) {
  const num = z.string().regex(NUM_RE, t('Enter a number'));
  return z.object({
    name: z.string().trim().min(1, t('Required')),
    morningOverheadMinutes: num,
    morningProductiveCommuteMinutes: num,
    eveningOverheadMinutes: num,
    eveningProductiveCommuteMinutes: num,
    commuteMode: z.enum(['none', 'transit', 'car', 'vespa']),
  });
}

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
  const form = useForm<z.infer<ReturnType<typeof makeSchema>>>({
    resolver: zodResolver(makeSchema(t)),
    defaultValues: {
      name: '',
      morningOverheadMinutes: '0',
      morningProductiveCommuteMinutes: '0',
      eveningOverheadMinutes: '0',
      eveningProductiveCommuteMinutes: '0',
      commuteMode: 'none',
    },
  });

  useEffect(() => {
    if (!open) return;
    form.reset({
      name: initial?.name ?? '',
      morningOverheadMinutes: String(initial?.morningOverheadMinutes ?? 0),
      morningProductiveCommuteMinutes: String(initial?.morningProductiveCommuteMinutes ?? 0),
      eveningOverheadMinutes: String(initial?.eveningOverheadMinutes ?? 0),
      eveningProductiveCommuteMinutes: String(initial?.eveningProductiveCommuteMinutes ?? 0),
      commuteMode: initial?.commuteMode ?? 'none',
    });
  }, [open, initial, form]);

  const submit = form.handleSubmit((values) =>
    onSubmit({
      name: values.name,
      morningOverheadMinutes: Number(values.morningOverheadMinutes) || 0,
      morningProductiveCommuteMinutes: Number(values.morningProductiveCommuteMinutes) || 0,
      eveningOverheadMinutes: Number(values.eveningOverheadMinutes) || 0,
      eveningProductiveCommuteMinutes: Number(values.eveningProductiveCommuteMinutes) || 0,
      commuteMode: values.commuteMode,
    }),
  );

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
          <Button type="button" onClick={submit} disabled={form.formState.isSubmitting}>
            {t('Save')}
          </Button>
        </div>
      }
    >
      <Form {...form}>
        <form id="preset-form" onSubmit={submit} className="grid gap-4 sm:grid-cols-2">
          <div className="sm:col-span-2">
            <FormField
              control={form.control}
              name="name"
              render={({ field }) => (
                <FormItem>
                  <FormLabel>{t('Name')}</FormLabel>
                  <FormControl>
                    <Input {...field} />
                  </FormControl>
                  <FormMessage />
                </FormItem>
              )}
            />
          </div>
          <FormField
            control={form.control}
            name="morningOverheadMinutes"
            render={({ field }) => (
              <FormItem>
                <FormLabel>{t('Morning overhead')}</FormLabel>
                <FormControl>
                  <Input type="number" inputMode="numeric" {...field} />
                </FormControl>
                <FormMessage />
              </FormItem>
            )}
          />
          <FormField
            control={form.control}
            name="morningProductiveCommuteMinutes"
            render={({ field }) => (
              <FormItem>
                <FormLabel>{t('Morning productive')}</FormLabel>
                <FormControl>
                  <Input type="number" inputMode="numeric" {...field} />
                </FormControl>
                <FormMessage />
              </FormItem>
            )}
          />
          <FormField
            control={form.control}
            name="eveningOverheadMinutes"
            render={({ field }) => (
              <FormItem>
                <FormLabel>{t('Evening overhead')}</FormLabel>
                <FormControl>
                  <Input type="number" inputMode="numeric" {...field} />
                </FormControl>
                <FormMessage />
              </FormItem>
            )}
          />
          <FormField
            control={form.control}
            name="eveningProductiveCommuteMinutes"
            render={({ field }) => (
              <FormItem>
                <FormLabel>{t('Evening productive')}</FormLabel>
                <FormControl>
                  <Input type="number" inputMode="numeric" {...field} />
                </FormControl>
                <FormMessage />
              </FormItem>
            )}
          />
          <div className="sm:col-span-2">
            <FormField
              control={form.control}
              name="commuteMode"
              render={({ field }) => (
                <FormItem>
                  <FormLabel>{t('Commute mode')}</FormLabel>
                  <FormControl>
                    <SelectField
                      value={field.value}
                      onValueChange={field.onChange}
                      options={[
                        { value: 'none', label: t('None') },
                        { value: 'transit', label: t('Transit') },
                        { value: 'car', label: t('Car') },
                        { value: 'vespa', label: t('Vespa') },
                      ]}
                    />
                  </FormControl>
                  <FormMessage />
                </FormItem>
              )}
            />
          </div>
        </form>
      </Form>
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
