import { useEffect, useState } from 'react';

import { useT } from '../i18n';
import { toDateStr } from '../lib/date';
import type { TimeLog } from '../lib/domain/time-log';
import { Button, Field, Input, Modal } from './ui';

export interface DayFormValues {
  date: string;
  startTime: string;
  endTime: string;
  expectedMinutes: number;
  lunchMinutes: number;
  nonWorkMinutes: number;
  note: string;
}

/** Add or edit a day (times are local "HH:MM"). */
export function DayDialog({
  open,
  onClose,
  initial,
  defaultExpectedMinutes,
  onSubmit,
}: {
  open: boolean;
  onClose: () => void;
  initial?: TimeLog | null;
  defaultExpectedMinutes: number;
  onSubmit: (values: DayFormValues) => void | Promise<void>;
}) {
  const t = useT();

  const [date, setDate] = useState('');
  const [startTime, setStartTime] = useState('08:00');
  const [endTime, setEndTime] = useState('');
  const [expected, setExpected] = useState('480');
  const [lunch, setLunch] = useState('0');
  const [nonWork, setNonWork] = useState('0');
  const [note, setNote] = useState('');
  const [busy, setBusy] = useState(false);

  useEffect(() => {
    if (!open) return;
    setDate(initial?.date ?? toDateStr(new Date()));
    setStartTime((initial?.startTime ?? '08:00:00').slice(0, 5));
    setEndTime((initial?.endTime ?? '').slice(0, 5));
    setExpected(String(initial?.expectedMinutes ?? defaultExpectedMinutes));
    setLunch(String(initial?.lunchMinutes ?? 0));
    setNonWork(String(initial?.nonWorkMinutes ?? 0));
    setNote(initial?.note ?? '');
  }, [open, initial, defaultExpectedMinutes]);

  async function submit() {
    setBusy(true);
    try {
      await onSubmit({
        date,
        startTime: `${startTime}:00`,
        endTime: endTime ? `${endTime}:00` : '',
        expectedMinutes: Number(expected) || 0,
        lunchMinutes: Number(lunch) || 0,
        nonWorkMinutes: Number(nonWork) || 0,
        note,
      });
    } finally {
      setBusy(false);
    }
  }

  return (
    <Modal open={open} onClose={onClose} title={initial ? t('Edit day') : t('Add day')}>
      <div className="grid gap-4 sm:grid-cols-2">
        <Field label={t('Date')} htmlFor="date">
          <Input id="date" type="date" value={date} onChange={(e) => setDate(e.target.value)} />
        </Field>
        <Field label={t('Expected minutes')} htmlFor="expected">
          <Input
            id="expected"
            type="number"
            inputMode="numeric"
            value={expected}
            onChange={(e) => setExpected(e.target.value)}
          />
        </Field>
        <Field label={t('Start')} htmlFor="start">
          <Input id="start" type="time" value={startTime} onChange={(e) => setStartTime(e.target.value)} />
        </Field>
        <Field label={t('Stop')} htmlFor="stop">
          <Input id="stop" type="time" value={endTime} onChange={(e) => setEndTime(e.target.value)} />
        </Field>
        <Field label={t('Lunch minutes')} htmlFor="lunch">
          <Input
            id="lunch"
            type="number"
            inputMode="numeric"
            value={lunch}
            onChange={(e) => setLunch(e.target.value)}
          />
        </Field>
        <Field label={t('Non-work minutes')} htmlFor="nonWork">
          <Input
            id="nonWork"
            type="number"
            inputMode="numeric"
            value={nonWork}
            onChange={(e) => setNonWork(e.target.value)}
          />
        </Field>
        <div className="sm:col-span-2">
          <Field label={t('Note')} htmlFor="note">
            <Input id="note" value={note} onChange={(e) => setNote(e.target.value)} />
          </Field>
        </div>
      </div>

      <div className="mt-6 flex justify-end gap-2">
        <Button variant="ghost" onClick={onClose}>
          {t('Cancel')}
        </Button>
        <Button onClick={() => void submit()} disabled={busy}>
          {t('Save')}
        </Button>
      </div>
    </Modal>
  );
}
