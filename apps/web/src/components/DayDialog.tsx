import { zodResolver } from '@hookform/resolvers/zod';
import { useEffect } from 'react';
import { useForm } from 'react-hook-form';
import { z } from 'zod';

import { useT } from '../i18n';
import { toDateStr } from '../lib/date';
import type { TimeLog } from '../lib/domain/time-log';
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
} from './ui';

export interface DayFormValues {
  date: string;
  startTime: string;
  endTime: string;
  expectedMinutes: number;
  lunchMinutes: number;
  nonWorkMinutes: number;
  note: string;
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
  });
}

type FormSchema = ReturnType<typeof makeSchema>;
type FormInput = z.infer<FormSchema>;

/** Add or edit a day — validated with Zod, wired through React Hook Form. */
export function DayDialog({
  open,
  onClose,
  initial,
  defaultDate,
  defaultExpectedMinutes,
  defaultLunchMinutes = 0,
  onSubmit,
}: {
  open: boolean;
  onClose: () => void;
  initial?: TimeLog | null;
  defaultDate?: string;
  defaultExpectedMinutes: number;
  defaultLunchMinutes?: number;
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
    },
  });

  useEffect(() => {
    if (!open) return;
    form.reset({
      date: initial?.date ?? defaultDate ?? toDateStr(new Date()),
      startTime: (initial?.startTime ?? '08:00:00').slice(0, 5),
      endTime: (initial?.endTime ?? '').slice(0, 5),
      expectedMinutes: String(initial?.expectedMinutes ?? defaultExpectedMinutes),
      lunchMinutes: String(initial?.lunchMinutes ?? defaultLunchMinutes),
      nonWorkMinutes: String(initial?.nonWorkMinutes ?? 0),
      note: initial?.note ?? '',
    });
  }, [open, initial, defaultDate, defaultExpectedMinutes, defaultLunchMinutes, form]);

  const submit = form.handleSubmit((values) =>
    onSubmit({
      date: values.date,
      startTime: `${values.startTime}:00`,
      endTime: values.endTime ? `${values.endTime}:00` : '',
      expectedMinutes: Number(values.expectedMinutes) || 0,
      lunchMinutes: Number(values.lunchMinutes) || 0,
      nonWorkMinutes: Number(values.nonWorkMinutes) || 0,
      note: values.note,
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
        <form
          id="day-form"
          onSubmit={submit}
          className="grid gap-4 sm:grid-cols-2"
        >
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
                  <Input type="time" {...field} />
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
