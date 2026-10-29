import { useState } from 'react';

import { backupApi } from '../api/backup';
import { useT } from '../i18n';
import { downloadJson } from '../lib/download';
import { useAuthStore } from '../state/auth';
import { Button, Card, Modal } from './ui';

/** Full encrypted backup export / restore (data portability between instances). */
export function BackupCard() {
  const t = useT();
  const onBackupRestored = useAuthStore((state) => state.onBackupRestored);

  const [busy, setBusy] = useState(false);
  const [restoreOpen, setRestoreOpen] = useState(false);
  const [bundleText, setBundleText] = useState('');
  const [message, setMessage] = useState<string | null>(null);

  async function exportBackup() {
    setBusy(true);
    setMessage(null);
    try {
      const bundle = await backupApi.export();
      const date = new Date().toISOString().split('T')[0];
      downloadJson(bundle, `chronowarden_backup_${date}.json`);
      setMessage(t('Backup downloaded'));
    } catch {
      setMessage(t('Could not save'));
    } finally {
      setBusy(false);
    }
  }

  async function restoreBackup() {
    setBusy(true);
    setMessage(null);
    try {
      await backupApi.import(JSON.parse(bundleText));
      setRestoreOpen(false);
      setBundleText('');
      onBackupRestored();
    } catch {
      setMessage(t('Invalid backup file'));
    } finally {
      setBusy(false);
    }
  }

  return (
    <Card>
      <h2 className="text-lg font-semibold text-white">{t('Backup & Restore')}</h2>
      <p className="mt-1 text-sm text-slate-400">
        {t(
          'Download a complete, encrypted backup you can restore on any ChronoWarden instance.',
        )}
      </p>

      <div className="mt-4 flex flex-wrap gap-2">
        <Button onClick={() => void exportBackup()} disabled={busy}>
          {t('Download backup')}
        </Button>
        <Button variant="ghost" onClick={() => setRestoreOpen(true)}>
          {t('Restore backup')}
        </Button>
      </div>

      {message ? <p className="mt-3 text-sm text-slate-400">{message}</p> : null}

      <Modal open={restoreOpen} onClose={() => setRestoreOpen(false)} title={t('Restore backup')}>
        <p className="text-sm text-slate-400">
          {t(
            'Restoring replaces all data in this account. Use the encryption passphrase from the backup.',
          )}
        </p>
        <textarea
          aria-label={t('Paste your backup JSON below.')}
          className="mt-3 h-40 w-full rounded-lg border border-slate-700 bg-slate-950 p-3 font-mono text-xs text-slate-100"
          value={bundleText}
          onChange={(event) => setBundleText(event.target.value)}
        />
        <div className="mt-4 flex justify-end gap-2">
          <Button variant="ghost" onClick={() => setRestoreOpen(false)}>
            {t('Cancel')}
          </Button>
          <Button onClick={() => void restoreBackup()} disabled={busy || !bundleText.trim()}>
            {t('Restore')}
          </Button>
        </div>
      </Modal>
    </Card>
  );
}
