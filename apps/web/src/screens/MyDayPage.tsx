import { useEffect, useState, type ReactNode } from 'react';
import { Briefcase, Coffee, NotebookPen, Pencil, Play, Route, Square, Trash2 } from 'lucide-react';

import { DayDialog, type DayFormValues } from '../components/DayDialog';
import {
  CommuteDialog,
  MinutesDialog,
  NoteDialog,
  StartDayDialog,
  StopDayDialog,
  type StartDayValues,
  type StopDayValues,
} from '../components/day-dialogs';
import { Badge, Button, Card, CardContent, CardHeader, ConfirmDialog, Progress } from '../components/ui';
import { useNow } from '../hooks/useNow';
import { useT } from '../i18n';
import { formatClock, toDateStr } from '../lib/date';
import type { TravelPreset } from '../lib/domain/travel-preset';
import {
  calculateOvertimeMinutes,
  copyWithTimeLog,
  leaveTimeWithBreaks,
  overheadMinutes,
  productiveCommuteMinutes,
  type TimeLog,
} from '../lib/domain/time-log';
import { expectedMinutesForDate, type WorkConfig } from '../lib/domain/work-config';
import { formatDurationMinutes, formatSignedMinutes } from '../lib/format';
import { usePreferences, useWorkConfig } from '../queries/settings';
import {
  useCreateTimeLog,
  useDeleteTimeLog,
  useTimeLogs,
  useTodayLog,
  useUpdateTimeLog,
} from '../queries/time-logs';
import { useTravelPresets } from '../queries/travel-presets';
import { useNotificationsStore } from '../state/notifications';
import { useToastStore } from '../state/toast';

const DEFAULT_CONFIG: WorkConfig = { defaultExpectedMinutes: 480 };
const LAST_PRESET_KEY = 'cw_last_preset';

function minutesSince(iso: string, now: Date): number {
  return Math.max(0, Math.round((now.getTime() - new Date(iso).getTime()) / 60_000));
}

function secondsSince(start: Date, now: Date): number {
  return Math.max(0, Math.floor((now.getTime() - start.getTime()) / 1000));
}

function formatHms(seconds: number): string {
  const h = Math.floor(seconds / 3600);
  const m = Math.floor((seconds % 3600) / 60);
  const s = seconds % 60;
  return [h, m, s].map((part) => String(part).padStart(2, '0')).join(':');
}

function Stat({ label, value, tone }: { label: string; value: string; tone?: string }) {
  return (
    <div>
      <dt className="text-xs uppercase tracking-wide text-muted-foreground">{label}</dt>
      <dd className={'mt-0.5 text-lg font-semibold ' + (tone ?? '')}>{value}</dd>
    </div>
  );
}

type DialogKind =
  | null
  | 'start'
  | 'stop'
  | 'lunch'
  | 'nonwork'
  | 'flex'
  | 'note'
  | 'commute'
  | 'edit'
  | 'delete';

export function MyDayPage() {
  const t = useT();
  const now = useNow(1000);

  const todayQuery = useTodayLog();
  const logsQuery = useTimeLogs();
  const workConfigQuery = useWorkConfig();
  const prefsQuery = usePreferences();
  const createLog = useCreateTimeLog();
  const updateLog = useUpdateTimeLog();
  const deleteLog = useDeleteTimeLog();
  const presetsQuery = useTravelPresets();
  const checkNotifications = useNotificationsStore((state) => state.check);
  const pushToast = useToastStore((state) => state.push);

  const [dialog, setDialog] = useState<DialogKind>(null);
  const [selectedPresetId, setSelectedPresetId] = useState(
    () => localStorage.getItem(LAST_PRESET_KEY) ?? '',
  );

  const today = todayQuery.data ?? null;
  const logs = logsQuery.data ?? [];
  const config = workConfigQuery.data ?? DEFAULT_CONFIG;
  const prefs = prefsQuery.data ?? { showWeekends: true, nonWorkEnabled: true, defaultFlexMinutes: 0, sliderStepMinutes: 5 };
  const timeBank = logs.reduce((sum, log) => sum + log.overtimeMinutes, 0);
  const presets = presetsQuery.data ?? [];
  const selectedPreset = presets.find((preset) => preset.id === selectedPresetId) ?? presets[0] ?? null;

  if (todayQuery.isLoading) {
    return (
      <Card>
        <CardContent className="grid place-items-center py-10">
          <div className="h-6 w-6 animate-spin rounded-full border-2 border-border border-t-primary" />
        </CardContent>
      </Card>
    );
  }

  const lunchActive =
    today?.lunchStartedAt != null
      ? Math.max(today.lunchMinutes, minutesSince(today.lunchStartedAt, now))
      : (today?.lunchMinutes ?? 0);
  const nonWorkActive =
    today?.nonWorkStartedAt != null
      ? Math.max(today.nonWorkMinutes, minutesSince(today.nonWorkStartedAt, now))
      : (today?.nonWorkMinutes ?? 0);

  const leave = today
    ? leaveTimeWithBreaks(today, { lunchMinutes: lunchActive, nonWorkMinutes: nonWorkActive })
    : null;

  // Feed the leave-time alert evaluator once a second while the day is active.
  useEffect(() => {
    if (!today || today.endTime != null || !leave) return;
    checkNotifications((leave.getTime() - now.getTime()) / 60_000, now);
  }, [now, today, leave, checkNotifications]);

  async function run(action: () => Promise<unknown>, successMessage?: string) {
    try {
      await action();
      if (successMessage) pushToast(successMessage, 'success');
    } catch {
      pushToast(t('Could not save'), 'error');
    } finally {
      setDialog(null);
    }
  }

  function startDay(values: StartDayValues) {
    const preset = presets.find((p) => p.id === values.presetId) ?? selectedPreset;
    localStorage.setItem(LAST_PRESET_KEY, values.presetId);
    setSelectedPresetId(values.presetId);
    void run(
      () =>
        createLog.mutateAsync({
          date: toDateStr(now),
          startTime: `${values.startTime}:00`,
          expectedMinutes: values.expectedMinutes,
          lunchMinutes: values.lunchMinutes,
          nonWorkMinutes: values.nonWorkMinutes,
          flexMinutes: values.flexMinutes,
          morningOverheadMinutes: preset?.morningOverheadMinutes ?? 0,
          morningProductiveCommuteMinutes: preset?.morningProductiveCommuteMinutes ?? 0,
          eveningOverheadMinutes: preset?.eveningOverheadMinutes ?? 0,
          eveningProductiveCommuteMinutes: preset?.eveningProductiveCommuteMinutes ?? 0,
          overtimeMinutes: 0,
          note: values.note,
        }),
      t('Saved'),
    );
  }

  const id = today?.id ?? null;
  const patch = (fields: Record<string, unknown>) => {
    if (!id) return Promise.resolve();
    return updateLog.mutateAsync({ id, fields });
  };

  function stopDay(values: StopDayValues) {
    if (!today) return;
    const next = copyWithTimeLog(today, {
      endTime: `${values.endTime}:00`,
      lunchMinutes: values.lunchMinutes,
      nonWorkMinutes: values.nonWorkMinutes,
      note: values.note,
      lunchStartedAt: null,
      nonWorkStartedAt: null,
    });
    void run(
      () =>
        patch({
          end_time: next.endTime,
          lunch_minutes: values.lunchMinutes,
          non_work_minutes: values.nonWorkMinutes,
          note: values.note,
          lunch_started_at: null,
          non_work_started_at: null,
          overtime_minutes: calculateOvertimeMinutes(next),
        }),
      t('Saved'),
    );
  }

  function editDay(values: DayFormValues) {
    if (!today) return;
    const endTime = values.endTime || null;
    const next = copyWithTimeLog(today, {
      startTime: values.startTime,
      endTime,
      expectedMinutes: values.expectedMinutes,
      lunchMinutes: values.lunchMinutes,
      nonWorkMinutes: values.nonWorkMinutes,
      note: values.note,
    });
    void run(
      () =>
        patch({
          start_time: values.startTime,
          end_time: endTime,
          expected_minutes: values.expectedMinutes,
          lunch_minutes: values.lunchMinutes,
          non_work_minutes: values.nonWorkMinutes,
          note: values.note,
          overtime_minutes: calculateOvertimeMinutes(next),
        }),
      t('Saved'),
    );
  }

  const startBreak = (field: 'lunch_started_at' | 'non_work_started_at') =>
    void run(() => patch({ [field]: now.toISOString() }));

  function stopBreak(
    startedAt: string | null | undefined,
    minutesField: 'lunch_minutes' | 'non_work_minutes',
    startedField: 'lunch_started_at' | 'non_work_started_at',
  ) {
    const minutes = startedAt ? minutesSince(startedAt, now) : 0;
    void run(() => patch({ [minutesField]: minutes, [startedField]: null }));
  }

  function applyCommute(preset: TravelPreset) {
    localStorage.setItem(LAST_PRESET_KEY, preset.id ?? '');
    setSelectedPresetId(preset.id ?? '');
    void run(
      () =>
        patch({
          morning_overhead_minutes: preset.morningOverheadMinutes,
          morning_productive_commute_minutes: preset.morningProductiveCommuteMinutes,
          evening_overhead_minutes: preset.eveningOverheadMinutes,
          evening_productive_commute_minutes: preset.eveningProductiveCommuteMinutes,
        }),
      t('Saved'),
    );
  }

  const expectedToday = expectedMinutesForDate(config, now);

  return (
    <div className="space-y-4">
      {!today ? (
        <Card>
          <CardContent className="text-center">
            <div className="mx-auto grid h-12 w-12 place-items-center rounded-full bg-primary/10 text-primary">
              <Play className="h-5 w-5" />
            </div>
            <h1 className="mt-3 text-xl font-semibold">{t('Today has not started')}</h1>
            <p className="mt-1 text-sm text-muted-foreground">
              {t('Expected today')}: {formatDurationMinutes(expectedToday)}
              {selectedPreset ? ` · ${selectedPreset.name}` : ''}
            </p>
            <Button className="mt-5 w-full sm:w-auto" onClick={() => setDialog('start')}>
              <Play className="h-4 w-4" />
              {t('Start Day')}
            </Button>
          </CardContent>
        </Card>
      ) : today.endTime == null ? (
        <ActiveDayCard
          log={today}
          now={now}
          leave={leave!}
          lunchActive={lunchActive}
          nonWorkActive={nonWorkActive}
          showNonWork={prefs.nonWorkEnabled}
          onStartLunch={() => startBreak('lunch_started_at')}
          onStopLunch={() => stopBreak(today.lunchStartedAt, 'lunch_minutes', 'lunch_started_at')}
          onStartNonWork={() => startBreak('non_work_started_at')}
          onStopNonWork={() => stopBreak(today.nonWorkStartedAt, 'non_work_minutes', 'non_work_started_at')}
          onAdjustLunch={() => setDialog('lunch')}
          onAdjustNonWork={() => setDialog('nonwork')}
          onAdjustFlex={() => setDialog('flex')}
          onEditNote={() => setDialog('note')}
          onChangeCommute={() => setDialog('commute')}
          onStopDay={() => setDialog('stop')}
        />
      ) : (
        <CompletedDayCard
          log={today}
          onEdit={() => setDialog('edit')}
          onDelete={() => setDialog('delete')}
        />
      )}

      <Card>
        <CardContent className="flex items-center justify-between gap-4">
          <div>
            <p className="text-sm text-muted-foreground">{t('Time bank')}</p>
            <p className={'text-2xl font-semibold ' + (timeBank >= 0 ? 'text-success' : 'text-warning')}>
              {formatSignedMinutes(timeBank)}
            </p>
          </div>
          <Progress value={Math.min(100, Math.abs(timeBank) / 8)} />
        </CardContent>
      </Card>

      <StartDayDialog
        open={dialog === 'start'}
        onClose={() => setDialog(null)}
        expectedMinutes={expectedToday}
        presets={presets}
        defaultPresetId={selectedPreset?.id ?? ''}
        defaultFlex={prefs.defaultFlexMinutes}
        showNonWork={prefs.nonWorkEnabled}
        busy={createLog.isPending}
        onSubmit={startDay}
      />

      {today ? (
        <StopDayDialog
          open={dialog === 'stop'}
          onClose={() => setDialog(null)}
          lunchMinutes={today.lunchMinutes}
          nonWorkMinutes={today.nonWorkMinutes}
          note={today.note ?? ''}
          showNonWork={prefs.nonWorkEnabled}
          busy={updateLog.isPending}
          onSubmit={stopDay}
        />
      ) : null}

      {today ? (
        <>
          <MinutesDialog
            open={dialog === 'lunch'}
            onClose={() => setDialog(null)}
            title={t('Adjust lunch')}
            value={today.lunchMinutes}
            max={240}
            step={prefs.sliderStepMinutes}
            onSave={(minutes) => void run(() => patch({ lunch_minutes: minutes }), t('Saved'))}
          />
          <MinutesDialog
            open={dialog === 'nonwork'}
            onClose={() => setDialog(null)}
            title={t('Adjust non-work time')}
            value={today.nonWorkMinutes}
            max={240}
            step={prefs.sliderStepMinutes}
            onSave={(minutes) => void run(() => patch({ non_work_minutes: minutes }), t('Saved'))}
          />
          <MinutesDialog
            open={dialog === 'flex'}
            onClose={() => setDialog(null)}
            title={t('Banked time to withdraw')}
            value={today.flexMinutes}
            max={240}
            step={prefs.sliderStepMinutes}
            onSave={(minutes) => void run(() => patch({ flex_minutes: minutes }), t('Saved'))}
          />
          <NoteDialog
            open={dialog === 'note'}
            onClose={() => setDialog(null)}
            value={today.note ?? ''}
            onSave={(note) => void run(() => patch({ note }), t('Saved'))}
          />
          <CommuteDialog
            open={dialog === 'commute'}
            onClose={() => setDialog(null)}
            presets={presets}
            onApply={applyCommute}
          />
          <DayDialog
            open={dialog === 'edit'}
            onClose={() => setDialog(null)}
            initial={today}
            defaultExpectedMinutes={expectedToday}
            onSubmit={editDay}
          />
          <ConfirmDialog
            open={dialog === 'delete'}
            title={t('Delete day')}
            description={t('Permanently delete the entry for {date}? This cannot be undone.', { date: today.date })}
            onClose={() => setDialog(null)}
            busy={deleteLog.isPending}
            onConfirm={() => {
              if (!today.id) return;
              void run(() => deleteLog.mutateAsync(today.id!), t('Saved'));
            }}
          />
        </>
      ) : null}
    </div>
  );
}

/* -------------------------------------------------------------------------- */
/* Active day                                                                 */
/* -------------------------------------------------------------------------- */

function ActiveDayCard({
  log,
  now,
  leave,
  lunchActive,
  nonWorkActive,
  showNonWork,
  onStartLunch,
  onStopLunch,
  onStartNonWork,
  onStopNonWork,
  onAdjustLunch,
  onAdjustNonWork,
  onAdjustFlex,
  onEditNote,
  onChangeCommute,
  onStopDay,
}: {
  log: TimeLog;
  now: Date;
  leave: Date;
  lunchActive: number;
  nonWorkActive: number;
  showNonWork: boolean;
  onStartLunch: () => void;
  onStopLunch: () => void;
  onStartNonWork: () => void;
  onStopNonWork: () => void;
  onAdjustLunch: () => void;
  onAdjustNonWork: () => void;
  onAdjustFlex: () => void;
  onEditNote: () => void;
  onChangeCommute: () => void;
  onStopDay: () => void;
}) {
  const t = useT();
  const start = new Date(`${log.date}T${log.startTime}`);
  const elapsedSeconds = secondsSince(start, now);
  const remainingMinutes = Math.round((leave.getTime() - now.getTime()) / 60_000);
  const isPast = remainingMinutes < 0;
  const netLeave = new Date(leave.getTime() - (lunchActive + nonWorkActive) * 60_000);
  const netRemaining = Math.round((netLeave.getTime() - now.getTime()) / 60_000);

  return (
    <Card>
      <CardContent>
        <div className="flex items-center justify-between gap-3">
          <h1 className="text-xl font-semibold">
            {isPast ? t("You're free to go!") : t('Day is active')}
          </h1>
          <Badge variant={isPast ? 'success' : 'secondary'}>{isPast ? t('Done') : t('Working')}</Badge>
        </div>

        <p className="mt-3 font-mono text-4xl font-semibold tabular-nums">{formatHms(elapsedSeconds)}</p>
        <p className="mt-1 text-xs text-muted-foreground">
          {t('Started at {time}', { time: log.startTime.slice(0, 5) })}
        </p>

        <div className="mt-5 grid grid-cols-2 gap-4 sm:grid-cols-4">
          <Stat label={t('Leave time')} value={formatClock(leave)} tone="text-primary" />
          <Stat
            label={t('Remaining')}
            value={isPast ? '—' : formatDurationMinutes(remainingMinutes)}
          />
          <Stat label={t('Expected')} value={formatDurationMinutes(log.expectedMinutes)} />
          <Stat label={t('Time bank')} value={formatSignedMinutes(log.overtimeMinutes)} tone="text-muted-foreground" />
        </div>

        {(lunchActive + nonWorkActive > 0) && !isPast ? (
          <p className="mt-2 text-xs text-muted-foreground">
            {t('net: {value}', { value: netRemaining <= 0 ? t('✓ done') : formatDurationMinutes(netRemaining) })}
          </p>
        ) : null}

        <div className="mt-6 space-y-3">
          <BreakRow
            icon={<Coffee className="h-4 w-4" />}
            label={t('Lunch')}
            minutes={lunchActive}
            active={log.lunchStartedAt != null}
            startedAt={log.lunchStartedAt}
            now={now}
            onStart={onStartLunch}
            onStop={onStopLunch}
            onAdjust={onAdjustLunch}
          />
          {showNonWork ? (
            <BreakRow
              icon={<Briefcase className="h-4 w-4" />}
              label={t('Non-work time')}
              minutes={nonWorkActive}
              active={log.nonWorkStartedAt != null}
              startedAt={log.nonWorkStartedAt}
              now={now}
              onStart={onStartNonWork}
              onStop={onStopNonWork}
              onAdjust={onAdjustNonWork}
            />
          ) : null}
        </div>

        <div className="mt-5 grid gap-2 sm:grid-cols-2">
          <button
            type="button"
            onClick={onAdjustFlex}
            className="flex items-center justify-between rounded-lg border border-border px-3 py-2 text-sm transition hover:bg-accent"
          >
            <span className="text-muted-foreground">{t('Banked time to withdraw')}</span>
            <span className="font-medium">{formatDurationMinutes(log.flexMinutes)}</span>
          </button>
          <button
            type="button"
            onClick={onEditNote}
            className="flex items-center justify-between rounded-lg border border-border px-3 py-2 text-sm transition hover:bg-accent"
          >
            <span className="flex items-center gap-2 text-muted-foreground">
              <NotebookPen className="h-4 w-4" />
              {t('Note')}
            </span>
            <span className="max-w-40 truncate font-medium">{log.note || t('Add')}</span>
          </button>
        </div>

        <div className="mt-5 flex flex-wrap gap-2">
          <Button variant="outline" onClick={onChangeCommute}>
            <Route className="h-4 w-4" />
            {t('Change commute pattern')}
          </Button>
          <Button variant="destructive" onClick={onStopDay}>
            <Square className="h-4 w-4" />
            {t('Stop Day')}
          </Button>
        </div>
      </CardContent>
    </Card>
  );
}

function BreakRow({
  icon,
  label,
  minutes,
  active,
  startedAt,
  now,
  onStart,
  onStop,
  onAdjust,
}: {
  icon: ReactNode;
  label: string;
  minutes: number;
  active: boolean;
  startedAt?: string | null;
  now: Date;
  onStart: () => void;
  onStop: () => void;
  onAdjust: () => void;
}) {
  const t = useT();
  const elapsed = active && startedAt ? secondsSince(new Date(startedAt), now) : 0;

  return (
    <div
      className={
        'flex flex-wrap items-center justify-between gap-2 rounded-lg border px-3 py-2 ' +
        (active ? 'border-primary/40 bg-primary/5' : 'border-border')
      }
    >
      <div className="flex items-center gap-2 text-sm">
        <span className="text-muted-foreground">{icon}</span>
        <span className="font-medium">{label}</span>
      </div>
      <div className="flex items-center gap-2">
        {active ? (
          <span className="font-mono text-sm tabular-nums text-primary">{formatHms(elapsed)}</span>
        ) : (
          <span className="text-sm font-medium">{formatDurationMinutes(minutes)}</span>
        )}
        {active ? (
          <Button size="sm" variant="destructive" onClick={onStop}>
            <Square className="h-3 w-3" />
            {t('Stop')}
          </Button>
        ) : (
          <>
            <Button size="sm" variant="secondary" onClick={onStart}>
              <Play className="h-3 w-3" />
              {t('Start')}
            </Button>
            <Button size="sm" variant="ghost" onClick={onAdjust}>
              <Pencil className="h-3 w-3" />
              {t('Edit')}
            </Button>
          </>
        )}
      </div>
    </div>
  );
}

/* -------------------------------------------------------------------------- */
/* Completed day                                                              */
/* -------------------------------------------------------------------------- */

function CompletedDayCard({
  log,
  onEdit,
  onDelete,
}: {
  log: TimeLog;
  onEdit: () => void;
  onDelete: () => void;
}) {
  const t = useT();
  const overtime = log.overtimeMinutes;

  return (
    <Card>
      <CardHeader
        title={t('Day completed')}
        description={t('Total: {minutes} min commute', { minutes: overheadMinutes(log) + productiveCommuteMinutes(log) })}
        action={
          <div className="flex gap-2">
            <Button size="sm" variant="outline" onClick={onEdit}>
              <Pencil className="h-3 w-3" />
              {t('Edit')}
            </Button>
            <Button size="sm" variant="ghost" onClick={onDelete}>
              <Trash2 className="h-3 w-3" />
              {t('Delete')}
            </Button>
          </div>
        }
      />
      <CardContent>
        <div className="grid grid-cols-2 gap-4 sm:grid-cols-4">
          <Stat label={t('Started')} value={log.startTime.slice(0, 5)} />
          <Stat label={t('Ended')} value={(log.endTime ?? '—').slice(0, 5)} />
          <Stat
            label={overtime < 0 ? t('Undertime') : t('Overtime')}
            value={formatSignedMinutes(overtime)}
            tone={overtime >= 0 ? 'text-success' : 'text-warning'}
          />
          <Stat label={t('Lunch')} value={formatDurationMinutes(log.lunchMinutes)} />
          {log.nonWorkMinutes > 0 ? (
            <Stat label={t('Non-work')} value={formatDurationMinutes(log.nonWorkMinutes)} />
          ) : null}
          {overheadMinutes(log) > 0 ? (
            <Stat label={t('Overhead')} value={formatDurationMinutes(overheadMinutes(log))} />
          ) : null}
        </div>
        {log.note ? (
          <p className="mt-4 rounded-lg bg-muted px-3 py-2 text-sm text-muted-foreground">{log.note}</p>
        ) : null}
      </CardContent>
    </Card>
  );
}
