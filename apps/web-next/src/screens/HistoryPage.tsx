import { useState } from 'react';

import { CsvImportDialog } from '../components/CsvImportDialog';
import { DayDialog, type DayFormValues } from '../components/DayDialog';
import { Button, Card, Spinner } from '../components/ui';
import { useT } from '../i18n';
import { todayStr } from '../lib/date';
import { timeLogsToCsv, type ImportResult } from '../lib/domain/csv';
import { calculateOvertimeMinutes, copyWithTimeLog, type TimeLog } from '../lib/domain/time-log';
import { downloadText } from '../lib/download';
import { formatSignedMinutes } from '../lib/format';
import { useWorkConfig } from '../queries/settings';
import { useCreateTimeLog, useDeleteTimeLog, useTimeLogs, useUpdateTimeLog } from '../queries/time-logs';

export function HistoryPage() {
  const t = useT();

  const logsQuery = useTimeLogs();
  const configQuery = useWorkConfig();
  const createLog = useCreateTimeLog();
  const updateLog = useUpdateTimeLog();
  const deleteLog = useDeleteTimeLog();

  const [dialogOpen, setDialogOpen] = useState(false);
  const [editing, setEditing] = useState<TimeLog | null>(null);
  const [csvOpen, setCsvOpen] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const logs = [...(logsQuery.data ?? [])].sort((a, b) => b.date.localeCompare(a.date));
  const defaultExpected = configQuery.data?.defaultExpectedMinutes ?? 480;

  function openAdd() {
    setEditing(null);
    setDialogOpen(true);
  }

  function openEdit(log: TimeLog) {
    setEditing(log);
    setDialogOpen(true);
  }

  async function submit(values: DayFormValues) {
    setError(null);
    try {
      if (editing?.id) {
        const endTime = values.endTime || null;
        const overtime = endTime
          ? calculateOvertimeMinutes(copyWithTimeLog(editing, { endTime }))
          : 0;
        await updateLog.mutateAsync({
          id: editing.id,
          fields: {
            start_time: values.startTime,
            end_time: endTime,
            expected_minutes: values.expectedMinutes,
            lunch_minutes: values.lunchMinutes,
            non_work_minutes: values.nonWorkMinutes,
            note: values.note,
            overtime_minutes: overtime,
          },
        });
      } else {
        const log: TimeLog = {
          date: values.date,
          startTime: values.startTime,
          endTime: values.endTime || null,
          expectedMinutes: values.expectedMinutes,
          lunchMinutes: values.lunchMinutes,
          nonWorkMinutes: values.nonWorkMinutes,
          flexMinutes: 0,
          morningOverheadMinutes: 0,
          morningProductiveCommuteMinutes: 0,
          eveningOverheadMinutes: 0,
          eveningProductiveCommuteMinutes: 0,
          overtimeMinutes: 0,
          note: values.note,
        };
        await createLog.mutateAsync({
          ...log,
          overtimeMinutes: calculateOvertimeMinutes(log),
        });
      }
      setDialogOpen(false);
    } catch {
      setError(t('Could not save'));
    }
  }

  function exportCsv() {
    downloadText(timeLogsToCsv(logs), `chronowarden_export_${todayStr()}.csv`, 'text/csv');
  }

  async function importCsv(result: ImportResult) {
    setError(null);
    for (const imported of result.imported) {
      await createLog.mutateAsync({
        ...imported,
        overtimeMinutes: calculateOvertimeMinutes(imported),
      });
    }
  }

  async function remove(log: TimeLog) {
    if (!log.id) return;
    if (!window.confirm(t('Delete this day?'))) return;
    setError(null);
    try {
      await deleteLog.mutateAsync(log.id);
    } catch {
      setError(t('Could not save'));
    }
  }

  if (logsQuery.isLoading) {
    return (
      <Card>
        <div className="flex justify-center py-8">
          <Spinner />
        </div>
      </Card>
    );
  }

  return (
    <>
      <Card>
        <div className="flex flex-wrap items-center justify-between gap-4">
          <h1 className="text-xl font-semibold text-white">{t('History')}</h1>
          <div className="flex flex-wrap gap-2">
            <Button variant="ghost" onClick={exportCsv}>
              {t('Export CSV')}
            </Button>
            <Button variant="ghost" onClick={() => setCsvOpen(true)}>
              {t('Import CSV')}
            </Button>
            <Button onClick={openAdd}>{t('Add day')}</Button>
          </div>
        </div>

        {logs.length === 0 ? (
          <p className="mt-4 text-sm text-slate-400">{t('No days recorded yet')}</p>
        ) : (
          <ul className="mt-4 divide-y divide-slate-800">
            {logs.map((log) => (
              <li key={log.id ?? log.date} className="flex flex-wrap items-center justify-between gap-3 py-3">
                <div>
                  <p className="font-medium text-white">{log.date}</p>
                  <p className="text-xs text-slate-400">
                    {log.startTime.slice(0, 5)}
                    {log.endTime ? ` – ${log.endTime.slice(0, 5)}` : ''}
                  </p>
                </div>
                <div className="flex items-center gap-2">
                  <span
                    className={
                      log.overtimeMinutes >= 0 ? 'text-sm text-emerald-400' : 'text-sm text-amber-400'
                    }
                  >
                    {formatSignedMinutes(log.overtimeMinutes)}
                  </span>
                  <Button variant="ghost" onClick={() => openEdit(log)}>
                    {t('Edit day')}
                  </Button>
                  <Button variant="ghost" onClick={() => void remove(log)}>
                    {t('Delete')}
                  </Button>
                </div>
              </li>
            ))}
          </ul>
        )}

        {error ? <p className="mt-3 text-sm text-red-400">{error}</p> : null}
      </Card>

      <DayDialog
        open={dialogOpen}
        onClose={() => setDialogOpen(false)}
        initial={editing}
        defaultExpectedMinutes={defaultExpected}
        onSubmit={submit}
      />

      <CsvImportDialog
        open={csvOpen}
        onClose={() => setCsvOpen(false)}
        existingDates={new Set(logs.map((log) => log.date))}
        onImport={importCsv}
      />
    </>
  );
}
