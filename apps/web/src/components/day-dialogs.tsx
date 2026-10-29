import { useEffect, useState } from 'react';

import { useT } from '../i18n';
import type { TravelPreset } from '../lib/domain/travel-preset';
import { Button, Field, Input, Modal, Select, Slider, Textarea } from './ui';

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

export function StartDayDialog({
  open,
  onClose,
  expectedMinutes,
  presets,
  defaultPresetId,
  defaultFlex,
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
  showNonWork: boolean;
  busy?: boolean;
  onSubmit: (values: StartDayValues) => void;
}) {
  const t = useT();
  const [startTime, setStartTime] = useState('08:00');
  const [expected, setExpected] = useState(String(expectedMinutes));
  const [lunch, setLunch] = useState('0');
  const [nonWork, setNonWork] = useState('0');
  const [flex, setFlex] = useState(String(defaultFlex));
  const [presetId, setPresetId] = useState(defaultPresetId);
  const [note, setNote] = useState('');

  useEffect(() => {
    if (!open) return;
    const now = new Date();
    setStartTime(`${String(now.getHours()).padStart(2, '0')}:${String(now.getMinutes()).padStart(2, '0')}`);
    setExpected(String(expectedMinutes));
    setLunch('0');
    setNonWork('0');
    setFlex(String(defaultFlex));
    setPresetId(defaultPresetId);
    setNote('');
  }, [open, expectedMinutes, defaultFlex, defaultPresetId]);

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
          <Button
            disabled={busy}
            onClick={() =>
              onSubmit({
                startTime,
                expectedMinutes: Number(expected) || 0,
                lunchMinutes: Number(lunch) || 0,
                nonWorkMinutes: Number(nonWork) || 0,
                flexMinutes: Number(flex) || 0,
                presetId,
                note,
              })
            }
          >
            {t('Start Day')}
          </Button>
        </div>
      }
    >
      <div className="grid gap-4 sm:grid-cols-2">
        <Field label={t('Start time')} htmlFor="startTime">
          <Input id="startTime" type="time" value={startTime} onChange={(e) => setStartTime(e.target.value)} />
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
        {presets.length > 0 ? (
          <div className="sm:col-span-2">
            <Field label={t('Travel preset')} htmlFor="preset">
              <Select id="preset" value={presetId} onChange={(e) => setPresetId(e.target.value)}>
                {presets.map((preset) => (
                  <option key={preset.id ?? preset.name} value={preset.id ?? ''}>
                    {preset.name}
                  </option>
                ))}
              </Select>
            </Field>
          </div>
        ) : null}
        <Field label={t('Lunch minutes')} htmlFor="lunch">
          <Input id="lunch" type="number" inputMode="numeric" value={lunch} onChange={(e) => setLunch(e.target.value)} />
        </Field>
        {showNonWork ? (
          <Field label={t('Non-work minutes')} htmlFor="nonWork">
            <Input id="nonWork" type="number" inputMode="numeric" value={nonWork} onChange={(e) => setNonWork(e.target.value)} />
          </Field>
        ) : null}
        <Field label={t('Banked time to withdraw')} htmlFor="flex">
          <Input id="flex" type="number" inputMode="numeric" value={flex} onChange={(e) => setFlex(e.target.value)} />
        </Field>
        <div className="sm:col-span-2">
          <Field label={t('Note')} htmlFor="note">
            <Textarea id="note" placeholder={t('Optional note...')} value={note} onChange={(e) => setNote(e.target.value)} />
          </Field>
        </div>
      </div>
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
  const [endTime, setEndTime] = useState('16:00');
  const [lunch, setLunch] = useState(String(lunchMinutes));
  const [nonWork, setNonWork] = useState(String(nonWorkMinutes));
  const [comment, setComment] = useState(note);

  useEffect(() => {
    if (!open) return;
    const now = new Date();
    setEndTime(`${String(now.getHours()).padStart(2, '0')}:${String(now.getMinutes()).padStart(2, '0')}`);
    setLunch(String(lunchMinutes));
    setNonWork(String(nonWorkMinutes));
    setComment(note);
  }, [open, lunchMinutes, nonWorkMinutes, note]);

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
          <Button
            variant="destructive"
            disabled={busy}
            onClick={() =>
              onSubmit({
                endTime,
                lunchMinutes: Number(lunch) || 0,
                nonWorkMinutes: Number(nonWork) || 0,
                note: comment,
              })
            }
          >
            {t('Stop Day')}
          </Button>
        </div>
      }
    >
      <div className="grid gap-4 sm:grid-cols-2">
        <Field label={t('End time')} htmlFor="endTime">
          <Input id="endTime" type="time" value={endTime} onChange={(e) => setEndTime(e.target.value)} />
        </Field>
        <Field label={t('Lunch minutes')} htmlFor="stopLunch">
          <Input id="stopLunch" type="number" inputMode="numeric" value={lunch} onChange={(e) => setLunch(e.target.value)} />
        </Field>
        {showNonWork ? (
          <Field label={t('Non-work minutes')} htmlFor="stopNonWork">
            <Input id="stopNonWork" type="number" inputMode="numeric" value={nonWork} onChange={(e) => setNonWork(e.target.value)} />
          </Field>
        ) : null}
        <div className="sm:col-span-2">
          <Field label={t('Note')} htmlFor="stopNote">
            <Textarea id="stopNote" placeholder={t('Optional note...')} value={comment} onChange={(e) => setComment(e.target.value)} />
          </Field>
        </div>
      </div>
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
      <div className="space-y-4">
        <div className="flex items-center gap-4">
          <Slider value={minutes} min={min} max={max} step={step} onChange={setMinutes} />
          <span className="w-16 text-right font-semibold">{minutes} min</span>
        </div>
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
          <Button
            disabled={!selected}
            onClick={() => selected && onApply(selected)}
          >
            {t('Apply')}
          </Button>
        </div>
      }
    >
      {presets.length === 0 ? (
        <p className="text-sm text-muted-foreground">{t('No travel presets available. Add one in Settings.')}</p>
      ) : (
        <Field label={t('Travel preset')} htmlFor="commutePreset">
          <Select id="commutePreset" value={presetId} onChange={(e) => setPresetId(e.target.value)}>
            {presets.map((preset) => (
              <option key={preset.id ?? preset.name} value={preset.id ?? ''}>
                {preset.name}
              </option>
            ))}
          </Select>
        </Field>
      )}
    </Modal>
  );
}
