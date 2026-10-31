import { useState } from 'react';
import { ArrowDown, ArrowUp, ArrowUpDown, Download, NotebookPen, Pencil, Plus, Trash2, Upload } from 'lucide-react';

import { CsvFormatGuide } from '../components/CsvFormatGuide';
import { TableSkeleton } from '../components/skeletons';
import { CsvImportDialog } from '../components/CsvImportDialog';
import { DayDialog, type DayFormValues } from '../components/DayDialog';
import {
  Badge,
  Button,
  Card,
  CardContent,
  CardHeader,
  ConfirmDialog,
  EmptyState,
  
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
  Tooltip,
  TooltipContent,
  TooltipTrigger,
} from '../components/ui';
import { useSaveDay } from '../hooks/useSaveDay';
import { useT } from '../i18n';
import { todayStr } from '../lib/date';
import { timeLogsToCsv, type ImportResult } from '../lib/domain/csv';
import { calculateOvertimeMinutes, type TimeLog } from '../lib/domain/time-log';
import { downloadText } from '../lib/download';
import { formatDurationMinutes, formatSignedMinutes, overtimeBadgeVariant } from '../lib/format';
import { useCreateTimeLog, useDeleteTimeLog, useTimeLogs } from '../queries/time-logs';
import { usePreferences, useWorkConfig } from '../queries/settings';
import { useToastStore } from '../state/toast';

type SortKey = 'date' | 'startTime' | 'lunchMinutes' | 'nonWorkMinutes' | 'overtimeMinutes';

function compare(a: TimeLog, b: TimeLog, key: SortKey): number {
  if (key === 'date' || key === 'startTime') return a[key].localeCompare(b[key]);
  return a[key] - b[key];
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
  const [sort, setSort] = useState<{ key: SortKey; desc: boolean }>({ key: 'date', desc: true });

  const showWeekends = prefsQuery.data?.showWeekends ?? true;
  const logs = [...(logsQuery.data ?? [])]
    .filter((log) => {
      if (showWeekends) return true;
      const day = new Date(`${log.date}T00:00:00`).getDay();
      return day >= 1 && day <= 5;
    })
    .sort((a, b) => compare(a, b, sort.key) * (sort.desc ? -1 : 1));
  const defaultExpected = configQuery.data?.defaultExpectedMinutes ?? 480;

  function toggleSort(key: SortKey) {
    setSort((prev) =>
      prev.key === key ? { key, desc: !prev.desc } : { key, desc: key === 'date' },
    );
  }

  function SortHeader({ label, sortKey }: { label: string; sortKey: SortKey }) {
    const active = sort.key === sortKey;
    const Icon = !active ? ArrowUpDown : sort.desc ? ArrowDown : ArrowUp;
    return (
      <button
        type="button"
        onClick={() => toggleSort(sortKey)}
        className={'inline-flex items-center gap-1 transition hover:text-foreground ' + (active ? 'text-foreground' : '')}
      >
        {label}
        <Icon className="h-3 w-3" />
      </button>
    );
  }

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
      await createLog.mutateAsync({ ...imported, overtimeMinutes: calculateOvertimeMinutes(imported) });
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
    return <TableSkeleton />;
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
            <Table>
              <TableHeader>
                <TableRow className="hover:bg-transparent">
                  <TableHead>
                    <SortHeader label={t('Date')} sortKey="date" />
                  </TableHead>
                  <TableHead>
                    <SortHeader label={t('Start')} sortKey="startTime" />
                  </TableHead>
                  <TableHead>{t('Stop')}</TableHead>
                  <TableHead>
                    <SortHeader label={t('Lunch')} sortKey="lunchMinutes" />
                  </TableHead>
                  <TableHead>
                    <SortHeader label={t('Non-work')} sortKey="nonWorkMinutes" />
                  </TableHead>
                  <TableHead>
                    <SortHeader label={t('Overtime')} sortKey="overtimeMinutes" />
                  </TableHead>
                  <TableHead className="text-right" />
                </TableRow>
              </TableHeader>
              <TableBody>
                {logs.map((log) => (
                  <TableRow key={log.id ?? log.date}>
                    <TableCell>
                      <div className="flex items-center gap-2">
                        <span className="font-medium">{log.date}</span>
                        {log.note ? <NotebookPen className="h-3.5 w-3.5 text-muted-foreground" /> : null}
                      </div>
                    </TableCell>
                    <TableCell>
                      <span className="font-mono text-xs">{log.startTime.slice(0, 5)}</span>
                    </TableCell>
                    <TableCell>
                      {log.endTime ? (
                        <span className="font-mono text-xs">{log.endTime.slice(0, 5)}</span>
                      ) : (
                        <Badge variant="secondary">{t('active')}</Badge>
                      )}
                    </TableCell>
                    <TableCell>{formatDurationMinutes(log.lunchMinutes)}</TableCell>
                    <TableCell>{formatDurationMinutes(log.nonWorkMinutes)}</TableCell>
                    <TableCell>
                      <Badge variant={overtimeBadgeVariant(log.overtimeMinutes)}>
                        {formatSignedMinutes(log.overtimeMinutes)}
                      </Badge>
                    </TableCell>
                    <TableCell>
                      <div className="flex justify-end gap-1">
                        <Tooltip>
                          <TooltipTrigger asChild>
                            <Button variant="ghost" size="icon" aria-label={t('Edit day')} onClick={() => openEdit(log)}>
                              <Pencil className="h-4 w-4" />
                            </Button>
                          </TooltipTrigger>
                          <TooltipContent>{t('Edit day')}</TooltipContent>
                        </Tooltip>
                        <Tooltip>
                          <TooltipTrigger asChild>
                            <Button
                              variant="ghost"
                              size="icon"
                              aria-label={t('Delete day')}
                              onClick={() => setDeleting(log)}
                            >
                              <Trash2 className="h-4 w-4 text-destructive" />
                            </Button>
                          </TooltipTrigger>
                          <TooltipContent>{t('Delete day')}</TooltipContent>
                        </Tooltip>
                      </div>
                    </TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          )}
        </CardContent>
      </Card>

      <DayDialog
        open={dialogOpen}
        onClose={() => setDialogOpen(false)}
        initial={editing}
        defaultExpectedMinutes={defaultExpected}
        defaultLunchMinutes={prefsQuery.data?.defaultLunchMinutes ?? 0}
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
