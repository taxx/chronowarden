import { zodResolver } from '@hookform/resolvers/zod';
import { useEffect, useRef } from 'react';
import { useForm } from 'react-hook-form';
import { z } from 'zod';

import { useT } from '../i18n';
import { toDateStr } from '../lib/date';
import type { TimeLog } from '../lib/domain/time-log';
import {
  defaultOverheadMinutes,
  findPresetForLog,
  type TravelPreset,
} from '../lib/domain/travel-preset';
import { formatDurationMinutes } from '../lib/format';
import { CommuteSummary } from './CommuteSummary';
import { MinutesSliderField } from './MinutesSliderField';
import {
  Button,
  DatePicker,
  Form,
  FormControl,
  FormField,
  FormItem,
  FormLabel,
  FormMessage,
  Input,
  Modal,
  SelectField,
  TimePicker,
} from './ui';

export interface DayFormValues {
  date: string;
  startTime: string;
  endTime: string;
  expectedMinutes: number;
  lunchMinutes: number;
  nonWorkMinutes: number;
  note: string;
  presetId: string;
  morningOverheadMinutes: number;
  morningProductiveCommuteMinutes: number;
  eveningOverheadMinutes: number;
  eveningProductiveCommuteMinutes: number;
}

const DATE_RE = /^\d{4}-\d{2}-\d{2}$/;
const NUM_RE = /^\d+$/;

function makeSchema(t: (key: string) => string) {
  return z.object({
    date: z.string().regex(DATE_RE, t('Required')),
    startTime: z.string().min(1, t('Required')),
    endTime: z.string(),
    expectedMinutes: z.string().regex(NUM_RE, t('Enter a number')),
    lunchMinutes: z.string().regex(NUM_RE, t('Enter a number')),
    nonWorkMinutes: z.string().regex(NUM_RE, t('Enter a number')),
    note: z.string(),
    presetId: z.string(),
    morningOverheadMinutes: z.string().regex(NUM_RE, t('Enter a number')),
    morningProductiveCommuteMinutes: z.string().regex(NUM_RE, t('Enter a number')),
    eveningOverheadMinutes: z.string().regex(NUM_RE, t('Enter a number')),
    eveningProductiveCommuteMinutes: z.string().regex(NUM_RE, t('Enter a number')),
  });
}

type FormSchema = ReturnType<typeof makeSchema>;
type FormInput = z.infer<FormSchema>;

const COMMUTE_NAMES = [
  'morningOverheadMinutes',
  'morningProductiveCommuteMinutes',
  'eveningOverheadMinutes',
  'eveningProductiveCommuteMinutes',
] as const;

/** Add or edit a day — validated with Zod, wired through React Hook Form. */
export function DayDialog({
  open,
  onClose,
  initial,
  defaultDate,
  defaultExpectedMinutes,
  defaultLunchMinutes = 0,
  defaultPresetId = '',
  presets = [],
  sliderStep = 5,
  onSubmit,
}: {
  open: boolean;
  onClose: () => void;
  initial?: TimeLog | null;
  defaultDate?: string;
  defaultExpectedMinutes: number;
  defaultLunchMinutes?: number;
  defaultPresetId?: string;
  presets?: TravelPreset[];
  sliderStep?: number;
  onSubmit: (values: DayFormValues) => void | Promise<void>;
}) {
  const t = useT();

  const form = useForm<FormInput>({
    resolver: zodResolver(makeSchema(t)),
    defaultValues: {
      date: '',
      startTime: '08:00',
      endTime: '',
      expectedMinutes: '480',
      lunchMinutes: '0',
      nonWorkMinutes: '0',
      note: '',
      presetId: '',
      morningOverheadMinutes: '0',
      morningProductiveCommuteMinutes: '0',
      eveningOverheadMinutes: '0',
      eveningProductiveCommuteMinutes: '0',
    },
  });

  const wasOpen = useRef(false);
  useEffect(() => {
    if (!open) {
      wasOpen.current = false;
      return;
    }
    if (!wasOpen.current) {
      wasOpen.current = true;
      const matched = initial ? findPresetForLog(presets, initial) : null;
      const preset =
        matched ??
        presets.find((p) => p.id === defaultPresetId) ??
        (initial ? null : presets[0]) ??
        null;
      form.reset({
        date: initial?.date ?? defaultDate ?? toDateStr(new Date()),
        startTime: (initial?.startTime ?? '08:00:00').slice(0, 5),
        endTime: (initial?.endTime ?? '').slice(0, 5),
        expectedMinutes: String(initial?.expectedMinutes ?? defaultExpectedMinutes),
        lunchMinutes: String(initial?.lunchMinutes ?? defaultLunchMinutes),
        nonWorkMinutes: String(initial?.nonWorkMinutes ?? 0),
        note: initial?.note ?? '',
        presetId: preset?.id ?? '',
        morningOverheadMinutes: String(initial?.morningOverheadMinutes ?? preset?.morningOverheadMinutes ?? 0),
        morningProductiveCommuteMinutes: String(
          initial?.morningProductiveCommuteMinutes ?? preset?.morningProductiveCommuteMinutes ?? 0,
        ),
        eveningOverheadMinutes: String(initial?.eveningOverheadMinutes ?? preset?.eveningOverheadMinutes ?? 0),
        eveningProductiveCommuteMinutes: String(
          initial?.eveningProductiveCommuteMinutes ?? preset?.eveningProductiveCommuteMinutes ?? 0,
        ),
      });
      return;
    }
    const current = form.getValues('presetId');
    if (presets.length > 0 && !presets.some((preset) => preset.id === current)) {
      form.setValue('presetId', defaultPresetId || presets[0]!.id || '');
    }
  }, [open, initial, presets, defaultDate, defaultExpectedMinutes, defaultLunchMinutes, defaultPresetId, form]);

  const watchedPresetId = form.watch('presetId');
  const commute = {
    morningOverhead: Number(form.watch('morningOverheadMinutes')) || 0,
    morningProductive: Number(form.watch('morningProductiveCommuteMinutes')) || 0,
    eveningOverhead: Number(form.watch('eveningOverheadMinutes')) || 0,
    eveningProductive: Number(form.watch('eveningProductiveCommuteMinutes')) || 0,
  };

  function applyPreset(presetId: string) {
    form.setValue('presetId', presetId);
    const preset = presets.find((candidate) => candidate.id === presetId);
    if (!preset) return;
    for (const name of COMMUTE_NAMES) form.setValue(name, '0');
    form.setValue('morningOverheadMinutes', String(preset.morningOverheadMinutes));
    form.setValue('morningProductiveCommuteMinutes', String(preset.morningProductiveCommuteMinutes));
    form.setValue('eveningOverheadMinutes', String(preset.eveningOverheadMinutes));
    form.setValue('eveningProductiveCommuteMinutes', String(preset.eveningProductiveCommuteMinutes));
  }

  const submit = form.handleSubmit((values) =>
    onSubmit({
      date: values.date,
      startTime: `${values.startTime}:00`,
      endTime: values.endTime ? `${values.endTime}:00` : '',
      expectedMinutes: Number(values.expectedMinutes) || 0,
      lunchMinutes: Number(values.lunchMinutes) || 0,
      nonWorkMinutes: Number(values.nonWorkMinutes) || 0,
      note: values.note,
      presetId: values.presetId,
      morningOverheadMinutes: Number(values.morningOverheadMinutes) || 0,
      morningProductiveCommuteMinutes: Number(values.morningProductiveCommuteMinutes) || 0,
      eveningOverheadMinutes: Number(values.eveningOverheadMinutes) || 0,
      eveningProductiveCommuteMinutes: Number(values.eveningProductiveCommuteMinutes) || 0,
    }),
  );

  return (
    <Modal
      open={open}
      onClose={onClose}
      title={initial ? t('Edit day') : t('Add day')}
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
        <form id="day-form" onSubmit={submit} className="grid gap-4 sm:grid-cols-2">
          <FormField
            control={form.control}
            name="date"
            render={({ field }) => (
              <FormItem>
                <FormLabel>{t('Date')}</FormLabel>
                <FormControl>
                  <DatePicker value={field.value} onChange={field.onChange} />
                </FormControl>
                <FormMessage />
              </FormItem>
            )}
          />
          <FormField
            control={form.control}
            name="expectedMinutes"
            render={({ field }) => (
              <FormItem>
                <FormLabel>{t('Expected minutes')}</FormLabel>
                <FormControl>
                  <Input type="number" inputMode="numeric" {...field} />
                </FormControl>
                <FormMessage />
              </FormItem>
            )}
          />
          <FormField
            control={form.control}
            name="startTime"
            render={({ field }) => (
              <FormItem>
                <FormLabel>{t('Start')}</FormLabel>
                <FormControl>
                  <TimePicker value={field.value} onChange={field.onChange} />
                </FormControl>
                <FormMessage />
              </FormItem>
            )}
          />
          <FormField
            control={form.control}
            name="endTime"
            render={({ field }) => (
              <FormItem>
                <FormLabel>{t('Stop')}</FormLabel>
                <FormControl>
                  <TimePicker value={field.value} onChange={field.onChange} />
                </FormControl>
                <FormMessage />
              </FormItem>
            )}
          />
          {presets.length > 0 ? (
            <>
              <div className="sm:col-span-2">
                <label htmlFor="day-preset" className="text-sm font-medium">
                  {t('Travel preset')}
                </label>
                <SelectField
                  id="day-preset"
                  className="mt-1.5"
                  value={watchedPresetId}
                  onValueChange={applyPreset}
                  options={presets.map((preset) => ({
                    value: preset.id ?? '',
                    label: `${preset.name} (+${formatDurationMinutes(defaultOverheadMinutes(preset))})`,
                  }))}
                />
              </div>
              <div className="sm:col-span-2">
                <CommuteSummary {...commute} />
              </div>
            </>
          ) : null}
          <MinutesSliderField
            control={form.control}
            name="lunchMinutes"
            label={t('Lunch minutes')}
            step={sliderStep}
          />
          <MinutesSliderField
            control={form.control}
            name="nonWorkMinutes"
            label={t('Non-work minutes')}
            step={sliderStep}
          />
          <div className="sm:col-span-2">
            <FormField
              control={form.control}
              name="note"
              render={({ field }) => (
                <FormItem>
                  <FormLabel>{t('Note')}</FormLabel>
                  <FormControl>
                    <Input {...field} />
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
