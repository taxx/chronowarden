import { useState } from 'react';
import { Download, NotebookPen, Pencil, Plus, Trash2, Upload } from 'lucide-react';

import { CsvImportDialog } from '../components/CsvImportDialog';
import { CsvFormatGuide } from '../components/CsvFormatGuide';
import { DayDialog, type DayFormValues } from '../components/DayDialog';
import {
  Badge,
  Button,
  Card,
  CardContent,
  CardHeader,
  ConfirmDialog,
  EmptyState,
  Spinner,
} from '../components/ui';
import { useT } from '../i18n';
import { todayStr } from '../lib/date';
import { timeLogsToCsv, type ImportResult } from '../lib/domain/csv';
import { calculateOvertimeMinutes, type TimeLog } from '../lib/domain/time-log';
import { downloadText } from '../lib/download';
import { formatDurationMinutes, formatSignedMinutes, overtimeBadgeVariant } from '../lib/format';
import { usePreferences, useWorkConfig } from '../queries/settings';
import { useSaveDay } from '../hooks/useSaveDay';
import {
  useCreateTimeLog,
  useDeleteTimeLog,
  useTimeLogs,
} from '../queries/time-logs';
import { useToastStore } from '../state/toast';

function weekdayLabel(dateStr: string): string {
  const date = new Date(`${dateStr}T00:00:00`);
  return new Intl.DateTimeFormat(undefined, { weekday: 'short', day: 'numeric', month: 'short' }).format(date);
}

export function HistoryPage() {
  const t = useT();

  const logsQuery = useTimeLogs();
  const configQuery = useWorkConfig();
  const prefsQuery = usePreferences();
  const createLog = useCreateTimeLog();
  const deleteLog = useDeleteTimeLog();
  const pushToast = useToastStore((state) => state.push);
  const { saveDay } = useSaveDay();

  const [dialogOpen, setDialogOpen] = useState(false);
  const [editing, setEditing] = useState<TimeLog | null>(null);
  const [csvOpen, setCsvOpen] = useState(false);
  const [csvGuideOpen, setCsvGuideOpen] = useState(false);
  const [deleting, setDeleting] = useState<TimeLog | null>(null);

  const showWeekends = prefsQuery.data?.showWeekends ?? true;
  const logs = [...(logsQuery.data ?? [])]
    .filter((log) => {
      if (showWeekends) return true;
      const day = new Date(`${log.date}T00:00:00`).getDay();
      return day >= 1 && day <= 5;
    })
    .sort((a, b) => b.date.localeCompare(a.date));
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
    try {
      await saveDay(values, editing);
      setDialogOpen(false);
      pushToast(t('Saved'), 'success');
    } catch {
      pushToast(t('Could not save'), 'error');
    }
  }

  function exportCsv() {
    downloadText(timeLogsToCsv(logs), `chronowarden_export_${todayStr()}.csv`, 'text/csv');
  }

  async function importCsv(result: ImportResult) {
    for (const imported of result.imported) {
      await createLog.mutateAsync({
        ...imported,
        overtimeMinutes: calculateOvertimeMinutes(imported),
      });
    }
    pushToast(t('Imported {count} day(s)', { count: result.imported.length }), 'success');
  }

  async function confirmDelete() {
    if (!deleting?.id) return;
    try {
      await deleteLog.mutateAsync(deleting.id);
      pushToast(t('Saved'), 'success');
    } catch {
      pushToast(t('Could not save'), 'error');
    } finally {
      setDeleting(null);
    }
  }

  if (logsQuery.isLoading) {
    return (
      <Card>
        <CardContent className="grid place-items-center py-10">
          <Spinner />
        </CardContent>
      </Card>
    );
  }

  return (
    <div className="space-y-4">
      <Card>
        <CardHeader
          title={t('History')}
          description={t('Download all your time logs as CSV or import from a CSV file.')}
          action={
            <div className="flex flex-wrap gap-2">
              <Button variant="outline" size="sm" onClick={exportCsv}>
                <Download className="h-3.5 w-3.5" />
                {t('Export CSV')}
              </Button>
              <Button variant="outline" size="sm" onClick={() => setCsvOpen(true)}>
                <Upload className="h-3.5 w-3.5" />
                {t('Import CSV')}
              </Button>
              <Button variant="ghost" size="sm" onClick={() => setCsvGuideOpen(true)}>
                {t('CSV format')}
              </Button>
              <Button size="sm" onClick={openAdd}>
                <Plus className="h-3.5 w-3.5" />
                {t('Add day')}
              </Button>
            </div>
          }
        />
        <CardContent>
          {logs.length === 0 ? (
            <EmptyState title={t('No days recorded yet')} description={t('Add a past day')} />
          ) : (
            <ul className="divide-y divide-border">
              {logs.map((log) => {
                const overtime = log.overtimeMinutes;
                return (
                  <li
                    key={log.id ?? log.date}
                    className="flex flex-wrap items-center gap-3 py-3 first:pt-0 last:pb-0"
                  >
                    <div className="min-w-40 flex-1">
                      <div className="flex items-center gap-2">
                        <p className="font-medium">{log.date}</p>
                        <span className="text-xs text-muted-foreground">{weekdayLabel(log.date)}</span>
                        {log.note ? <NotebookPen className="h-3.5 w-3.5 text-muted-foreground" /> : null}
                      </div>
                      <p className="text-xs text-muted-foreground">
                        {log.startTime.slice(0, 5)}
                        {log.endTime ? ` – ${log.endTime.slice(0, 5)}` : ` · ${t('active')}`}
                        {log.lunchMinutes > 0 ? ` · ${t('Lunch')} ${formatDurationMinutes(log.lunchMinutes)}` : ''}
                        {log.nonWorkMinutes > 0
                          ? ` · ${t('Non-work')} ${formatDurationMinutes(log.nonWorkMinutes)}`
                          : ''}
                      </p>
                    </div>
                    <Badge variant={overtimeBadgeVariant(overtime)}>
                      {formatSignedMinutes(overtime)}
                    </Badge>
                    <div className="flex gap-1">
                      <Button
                        variant="ghost"
                        size="icon"
                        aria-label={t('Edit day')}
                        onClick={() => openEdit(log)}
                      >
                        <Pencil className="h-4 w-4" />
                      </Button>
                      <Button
                        variant="ghost"
                        size="icon"
                        aria-label={t('Delete day')}
                        onClick={() => setDeleting(log)}
                      >
                        <Trash2 className="h-4 w-4 text-destructive" />
                      </Button>
                    </div>
                  </li>
                );
              })}
            </ul>
          )}
        </CardContent>
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

      <CsvFormatGuide open={csvGuideOpen} onClose={() => setCsvGuideOpen(false)} />

      <ConfirmDialog
        open={deleting != null}
        title={t('Delete day')}
        description={
          deleting
            ? t('Permanently delete the entry for {date}? This cannot be undone.', { date: deleting.date })
            : undefined
        }
        busy={deleteLog.isPending}
        onClose={() => setDeleting(null)}
        onConfirm={confirmDelete}
      />
    </div>
  );
}
