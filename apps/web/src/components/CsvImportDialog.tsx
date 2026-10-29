import { useState } from 'react';

import { useT } from '../i18n';
import { parseCsvTimeLogs, type ImportResult } from '../lib/domain/csv';
import { Button, Modal } from './ui';

/** Paste-a-CSV dialog (the export/import format is documented in `csv.ts`). */
export function CsvImportDialog({
  open,
  onClose,
  existingDates,
  onImport,
}: {
  open: boolean;
  onClose: () => void;
  existingDates: Set<string>;
  onImport: (result: ImportResult) => Promise<void>;
}) {
  const t = useT();
  const [text, setText] = useState('');
  const [busy, setBusy] = useState(false);
  const [summary, setSummary] = useState<string | null>(null);
  const [errors, setErrors] = useState<string[]>([]);

  async function submit() {
    const result = parseCsvTimeLogs(text, existingDates);
    setBusy(true);
    try {
      await onImport(result);
      const skipped = result.skipped
        ? t(', {count} skipped (duplicates)', { count: result.skipped })
        : '';
      const errorCount = result.errors.length
        ? t(', {count} error(s)', { count: result.errors.length })
        : '';
      setSummary(
        t('Imported {count} day(s)', { count: result.imported.length }) + skipped + errorCount,
      );
      setErrors(result.errors);
    } finally {
      setBusy(false);
    }
  }

  function close() {
    setText('');
    setSummary(null);
    setErrors([]);
    onClose();
  }

  return (
    <Modal open={open} onClose={close} title={t('Import CSV')}>
      <p className="text-sm text-muted-foreground">{t('Paste your CSV data below.')}</p>
      <textarea
        aria-label={t('Paste your CSV data below.')}
        className="mt-2 h-40 w-full rounded-lg border border-input bg-background p-3 font-mono text-xs text-foreground"
        value={text}
        onChange={(event) => setText(event.target.value)}
      />

      {summary ? <p className="mt-3 text-sm text-foreground">{summary}</p> : null}
      {errors.length > 0 ? (
        <ul className="mt-2 max-h-32 overflow-auto text-xs text-destructive">
          {errors.map((error) => (
            <li key={error}>{error}</li>
          ))}
        </ul>
      ) : null}

      <div className="mt-4 flex justify-end gap-2">
        <Button variant="ghost" onClick={close}>
          {t('Cancel')}
        </Button>
        <Button onClick={() => void submit()} disabled={busy || !text.trim()}>
          {t('Import CSV')}
        </Button>
      </div>
    </Modal>
  );
}
