import { zodResolver } from '@hookform/resolvers/zod';
import { useEffect, useState } from 'react';
import { useForm } from 'react-hook-form';
import { z } from 'zod';

import { useT } from '../i18n';
import type { TravelPreset } from '../lib/domain/travel-preset';
import {
  Button,
  Form,
  FormControl,
  FormField,
  FormItem,
  FormLabel,
  FormMessage,
  Input,
  Modal,
  SelectField,
  Slider,
  Textarea,
} from './ui';

const NUM_RE = /^\d+$/;

function numberField(t: (key: string) => string) {
  return z.string().regex(NUM_RE, t('Enter a number'));
}

/* -------------------------------------------------------------------------- */
/* Start Day                                                                  */
/* -------------------------------------------------------------------------- */

export interface StartDayValues {
  startTime: string;
  expectedMinutes: number;
  lunchMinutes: number;
  nonWorkMinutes: number;
  flexMinutes: number;
  presetId: string;
  note: string;
}

function makeStartSchema(t: (key: string) => string) {
  return z.object({
    startTime: z.string().min(1, t('Required')),
    expectedMinutes: numberField(t),
    presetId: z.string(),
    lunchMinutes: numberField(t),
    nonWorkMinutes: numberField(t),
    flexMinutes: numberField(t),
    note: z.string(),
  });
}

export function StartDayDialog({
  open,
  onClose,
  expectedMinutes,
  presets,
  defaultPresetId,
  defaultFlex,
  defaultLunch,
  showNonWork,
  busy,
  onSubmit,
}: {
  open: boolean;
  onClose: () => void;
  expectedMinutes: number;
  presets: TravelPreset[];
  defaultPresetId: string;
  defaultFlex: number;
  defaultLunch: number;
  showNonWork: boolean;
  busy?: boolean;
  onSubmit: (values: StartDayValues) => void;
}) {
  const t = useT();
  const form = useForm<z.infer<ReturnType<typeof makeStartSchema>>>({
    resolver: zodResolver(makeStartSchema(t)),
    defaultValues: {
      startTime: '08:00',
      expectedMinutes: String(expectedMinutes),
      presetId: defaultPresetId,
      lunchMinutes: String(defaultLunch ?? 0),
      nonWorkMinutes: '0',
      flexMinutes: String(defaultFlex ?? 0),
      note: '',
    },
  });

  useEffect(() => {
    if (!open) return;
    const now = new Date();
    form.reset({
      startTime: `${String(now.getHours()).padStart(2, '0')}:${String(now.getMinutes()).padStart(2, '0')}`,
      expectedMinutes: String(expectedMinutes),
      presetId: defaultPresetId,
      lunchMinutes: String(defaultLunch ?? 0),
      nonWorkMinutes: '0',
      flexMinutes: String(defaultFlex ?? 0),
      note: '',
    });
  }, [open, expectedMinutes, defaultLunch, defaultFlex, defaultPresetId, form]);

  const submit = form.handleSubmit((values) =>
    onSubmit({
      startTime: values.startTime,
      expectedMinutes: Number(values.expectedMinutes) || 0,
      lunchMinutes: Number(values.lunchMinutes) || 0,
      nonWorkMinutes: Number(values.nonWorkMinutes) || 0,
      flexMinutes: Number(values.flexMinutes) || 0,
      presetId: values.presetId,
      note: values.note,
    }),
  );

  return (
    <Modal
      open={open}
      onClose={onClose}
      title={t('Start Day')}
      description={t('Adjust if needed:')}
      footer={
        <div className="flex justify-end gap-2">
          <Button variant="ghost" onClick={onClose}>
            {t('Cancel')}
          </Button>
          <Button type="button" onClick={submit} disabled={busy}>
            {t('Start Day')}
          </Button>
        </div>
      }
    >
      <Form {...form}>
        <form id="start-day-form" onSubmit={submit} className="grid gap-4 sm:grid-cols-2">
          <FormField
            control={form.control}
            name="startTime"
            render={({ field }) => (
              <FormItem>
                <FormLabel>{t('Start time')}</FormLabel>
                <FormControl>
                  <Input type="time" {...field} />
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
          {presets.length > 0 ? (
            <div className="sm:col-span-2">
              <FormField
                control={form.control}
                name="presetId"
                render={({ field }) => (
                  <FormItem>
                    <FormLabel>{t('Travel preset')}</FormLabel>
                    <FormControl>
                      <SelectField
                        value={field.value}
                        onValueChange={field.onChange}
                        options={presets.map((preset) => ({
                          value: preset.id ?? '',
                          label: preset.name,
                        }))}
                      />
                    </FormControl>
                    <FormMessage />
                  </FormItem>
                )}
              />
            </div>
          ) : null}
          <FormField
            control={form.control}
            name="lunchMinutes"
            render={({ field }) => (
              <FormItem>
                <FormLabel>{t('Lunch minutes')}</FormLabel>
                <FormControl>
                  <Input type="number" inputMode="numeric" {...field} />
                </FormControl>
                <FormMessage />
              </FormItem>
            )}
          />
          {showNonWork ? (
            <FormField
              control={form.control}
              name="nonWorkMinutes"
              render={({ field }) => (
                <FormItem>
                  <FormLabel>{t('Non-work minutes')}</FormLabel>
                  <FormControl>
                    <Input type="number" inputMode="numeric" {...field} />
                  </FormControl>
                  <FormMessage />
                </FormItem>
              )}
            />
          ) : null}
          <FormField
            control={form.control}
            name="flexMinutes"
            render={({ field }) => (
              <FormItem>
                <FormLabel>{t('Banked time to withdraw')}</FormLabel>
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
              name="note"
              render={({ field }) => (
                <FormItem>
                  <FormLabel>{t('Note')}</FormLabel>
                  <FormControl>
                    <Textarea placeholder={t('Optional note...')} {...field} />
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

/* -------------------------------------------------------------------------- */
/* Stop Day                                                                   */
/* -------------------------------------------------------------------------- */

export interface StopDayValues {
  endTime: string;
  lunchMinutes: number;
  nonWorkMinutes: number;
  note: string;
}

function makeStopSchema(t: (key: string) => string) {
  return z.object({
    endTime: z.string().min(1, t('Required')),
    lunchMinutes: numberField(t),
    nonWorkMinutes: numberField(t),
    note: z.string(),
  });
}

export function StopDayDialog({
  open,
  onClose,
  lunchMinutes,
  nonWorkMinutes,
  note,
  showNonWork,
  busy,
  onSubmit,
}: {
  open: boolean;
  onClose: () => void;
  lunchMinutes: number;
  nonWorkMinutes: number;
  note: string;
  showNonWork: boolean;
  busy?: boolean;
  onSubmit: (values: StopDayValues) => void;
}) {
  const t = useT();
  const form = useForm<z.infer<ReturnType<typeof makeStopSchema>>>({
    resolver: zodResolver(makeStopSchema(t)),
    defaultValues: {
      endTime: '16:00',
      lunchMinutes: String(lunchMinutes),
      nonWorkMinutes: String(nonWorkMinutes),
      note,
    },
  });

  useEffect(() => {
    if (!open) return;
    const now = new Date();
    form.reset({
      endTime: `${String(now.getHours()).padStart(2, '0')}:${String(now.getMinutes()).padStart(2, '0')}`,
      lunchMinutes: String(lunchMinutes),
      nonWorkMinutes: String(nonWorkMinutes),
      note,
    });
  }, [open, lunchMinutes, nonWorkMinutes, note, form]);

  const submit = form.handleSubmit((values) =>
    onSubmit({
      endTime: values.endTime,
      lunchMinutes: Number(values.lunchMinutes) || 0,
      nonWorkMinutes: Number(values.nonWorkMinutes) || 0,
      note: values.note,
    }),
  );

  return (
    <Modal
      open={open}
      onClose={onClose}
      title={t('Stop Day')}
      description={t('Adjust if needed:')}
      footer={
        <div className="flex justify-end gap-2">
          <Button variant="ghost" onClick={onClose}>
            {t('Cancel')}
          </Button>
          <Button type="button" onClick={submit} variant="destructive" disabled={busy}>
            {t('Stop Day')}
          </Button>
        </div>
      }
    >
      <Form {...form}>
        <form id="stop-day-form" onSubmit={submit} className="grid gap-4 sm:grid-cols-2">
          <FormField
            control={form.control}
            name="endTime"
            render={({ field }) => (
              <FormItem>
                <FormLabel>{t('End time')}</FormLabel>
                <FormControl>
                  <Input type="time" {...field} />
                </FormControl>
                <FormMessage />
              </FormItem>
            )}
          />
          <FormField
            control={form.control}
            name="lunchMinutes"
            render={({ field }) => (
              <FormItem>
                <FormLabel>{t('Lunch minutes')}</FormLabel>
                <FormControl>
                  <Input type="number" inputMode="numeric" {...field} />
                </FormControl>
                <FormMessage />
              </FormItem>
            )}
          />
          {showNonWork ? (
            <FormField
              control={form.control}
              name="nonWorkMinutes"
              render={({ field }) => (
                <FormItem>
                  <FormLabel>{t('Non-work minutes')}</FormLabel>
                  <FormControl>
                    <Input type="number" inputMode="numeric" {...field} />
                  </FormControl>
                  <FormMessage />
                </FormItem>
              )}
            />
          ) : null}
          <div className="sm:col-span-2">
            <FormField
              control={form.control}
              name="note"
              render={({ field }) => (
                <FormItem>
                  <FormLabel>{t('Note')}</FormLabel>
                  <FormControl>
                    <Textarea placeholder={t('Optional note...')} {...field} />
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

/* -------------------------------------------------------------------------- */
/* Minute slider                                                              */
/* -------------------------------------------------------------------------- */

export function MinutesDialog({
  open,
  onClose,
  title,
  value,
  min = 0,
  max = 240,
  step = 5,
  onSave,
}: {
  open: boolean;
  onClose: () => void;
  title: string;
  value: number;
  min?: number;
  max?: number;
  step?: number;
  onSave: (value: number) => void;
}) {
  const t = useT();
  const [minutes, setMinutes] = useState(value);

  useEffect(() => {
    if (open) setMinutes(value);
  }, [open, value]);

  return (
    <Modal
      open={open}
      onClose={onClose}
      title={title}
      size="sm"
      footer={
        <div className="flex justify-end gap-2">
          <Button variant="ghost" onClick={onClose}>
            {t('Cancel')}
          </Button>
          <Button onClick={() => onSave(minutes)}>{t('Save')}</Button>
        </div>
      }
    >
      <div className="flex items-center gap-4">
        <Slider value={minutes} min={min} max={max} step={step} onChange={setMinutes} />
        <span className="w-16 text-right font-semibold">{minutes} min</span>
      </div>
    </Modal>
  );
}

/* -------------------------------------------------------------------------- */
/* Note                                                                       */
/* -------------------------------------------------------------------------- */

export function NoteDialog({
  open,
  onClose,
  value,
  onSave,
}: {
  open: boolean;
  onClose: () => void;
  value: string;
  onSave: (value: string) => void;
}) {
  const t = useT();
  const [note, setNote] = useState(value);

  useEffect(() => {
    if (open) setNote(value);
  }, [open, value]);

  return (
    <Modal
      open={open}
      onClose={onClose}
      title={t('Note')}
      size="sm"
      footer={
        <div className="flex justify-end gap-2">
          <Button variant="ghost" onClick={onClose}>
            {t('Cancel')}
          </Button>
          <Button onClick={() => onSave(note)}>{t('Save')}</Button>
        </div>
      }
    >
      <Textarea autoFocus placeholder={t('Optional note...')} value={note} onChange={(e) => setNote(e.target.value)} />
    </Modal>
  );
}

/* -------------------------------------------------------------------------- */
/* Commute pattern                                                            */
/* -------------------------------------------------------------------------- */

export function CommuteDialog({
  open,
  onClose,
  presets,
  onApply,
}: {
  open: boolean;
  onClose: () => void;
  presets: TravelPreset[];
  onApply: (preset: TravelPreset) => void;
}) {
  const t = useT();
  const [presetId, setPresetId] = useState(presets[0]?.id ?? '');

  useEffect(() => {
    if (open) setPresetId(presets[0]?.id ?? '');
  }, [open, presets]);

  const selected = presets.find((preset) => preset.id === presetId) ?? presets[0] ?? null;

  return (
    <Modal
      open={open}
      onClose={onClose}
      title={t('Change commute pattern')}
      footer={
        <div className="flex justify-end gap-2">
          <Button variant="ghost" onClick={onClose}>
            {t('Cancel')}
          </Button>
          <Button disabled={!selected} onClick={() => selected && onApply(selected)}>
            {t('Apply')}
          </Button>
        </div>
      }
    >
      {presets.length === 0 ? (
        <p className="text-sm text-muted-foreground">{t('No travel presets available. Add one in Settings.')}</p>
      ) : (
        <div className="space-y-1.5">
          <label className="text-sm font-medium">{t('Travel preset')}</label>
          <SelectField
            value={presetId}
            onValueChange={setPresetId}
            options={presets.map((preset) => ({ value: preset.id ?? '', label: preset.name }))}
          />
        </div>
      )}
    </Modal>
  );
}
