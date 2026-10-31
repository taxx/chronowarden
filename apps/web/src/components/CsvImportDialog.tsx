import { useState } from 'react';

import { useT } from '../i18n';
import { parseCsvTimeLogs, type ImportResult } from '../lib/domain/csv';
import { FilePickerButton } from './FilePickerButton';
import { Button, Modal, Textarea } from './ui';

/** Import time logs from a CSV file or pasted text (format in `csv.ts`). */
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
    <Modal
      open={open}
      onClose={close}
      title={t('Import CSV')}
      description={t('Paste your CSV data below.')}
      footer={
        <div className="flex justify-end gap-2">
          <Button variant="ghost" onClick={close}>
            {t('Cancel')}
          </Button>
          <Button onClick={() => void submit()} disabled={busy || !text.trim()}>
            {t('Import CSV')}
          </Button>
        </div>
      }
    >
      <div className="mb-2 flex justify-end">
        <FilePickerButton
          accept=".csv,text/csv,text/plain"
          label={t('Choose a CSV file')}
          onLoad={(content) => setText(content)}
        />
      </div>
      <Textarea
        aria-label={t('Paste your CSV data below.')}
        className="h-40 font-mono text-xs"
        value={text}
        onChange={(event) => setText(event.target.value)}
      />

      {summary ? <p className="mt-3 text-sm">{summary}</p> : null}
      {errors.length > 0 ? (
        <ul className="mt-2 max-h-32 overflow-auto text-xs text-destructive">
          {errors.map((error) => (
            <li key={error}>{error}</li>
          ))}
        </ul>
      ) : null}
    </Modal>
  );
}
