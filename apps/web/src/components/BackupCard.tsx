import { useState } from 'react';

import { backupApi } from '../api/backup';
import { useT } from '../i18n';
import { downloadJson } from '../lib/download';
import { useAuthStore } from '../state/auth';
import { useToastStore } from '../state/toast';
import { Button, Card, CardContent, CardHeader, Modal, Textarea } from './ui';

/** Full encrypted backup export / restore (data portability between instances). */
export function BackupCard() {
  const t = useT();
  const onBackupRestored = useAuthStore((state) => state.onBackupRestored);
  const pushToast = useToastStore((state) => state.push);

  const [busy, setBusy] = useState(false);
  const [restoreOpen, setRestoreOpen] = useState(false);
  const [bundleText, setBundleText] = useState('');

  async function exportBackup() {
    setBusy(true);
    try {
      const bundle = await backupApi.export();
      const date = new Date().toISOString().split('T')[0];
      downloadJson(bundle, `chronowarden_backup_${date}.json`);
      pushToast(t('Backup downloaded'), 'success');
    } catch {
      pushToast(t('Could not save'), 'error');
    } finally {
      setBusy(false);
    }
  }

  async function restoreBackup() {
    setBusy(true);
    try {
      await backupApi.import(JSON.parse(bundleText));
      setRestoreOpen(false);
      setBundleText('');
      onBackupRestored();
    } catch {
      pushToast(t('Invalid backup file'), 'error');
    } finally {
      setBusy(false);
    }
  }

  return (
    <Card>
      <CardHeader
        title={t('Backup & Restore')}
        description={t(
          'Download a complete, encrypted backup you can restore on any ChronoWarden instance.',
        )}
      />
      <CardContent className="flex flex-wrap gap-2">
        <Button onClick={() => void exportBackup()} disabled={busy}>
          {t('Download backup')}
        </Button>
        <Button variant="outline" onClick={() => setRestoreOpen(true)}>
          {t('Restore backup')}
        </Button>
      </CardContent>

      <Modal
        open={restoreOpen}
        onClose={() => setRestoreOpen(false)}
        title={t('Restore backup')}
        description={t(
          'Restoring replaces all data in this account. Use the encryption passphrase from the backup.',
        )}
        footer={
          <div className="flex justify-end gap-2">
            <Button variant="ghost" onClick={() => setRestoreOpen(false)}>
              {t('Cancel')}
            </Button>
            <Button onClick={() => void restoreBackup()} disabled={busy || !bundleText.trim()}>
              {t('Restore')}
            </Button>
          </div>
        }
      >
        <Textarea
          aria-label={t('Paste your backup JSON below.')}
          className="h-40 font-mono text-xs"
          value={bundleText}
          onChange={(event) => setBundleText(event.target.value)}
        />
      </Modal>
    </Card>
  );
}
