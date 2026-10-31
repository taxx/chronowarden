import { Modal } from './ui';
import { useT } from '../i18n';

const ROWS = [
  ['date', 'YYYY-MM-DD'],
  ['start_time', 'HH:MM:SS'],
  ['end_time', 'HH:MM:SS (empty while the day is open)'],
  ['expected_minutes', '480'],
  ['overhead_minutes', '60'],
  ['lunch_minutes', '45'],
  ['productive_commute_minutes', '30'],
  ['note', 'Free text (quoted if it contains a comma)'],
  ['non_work_minutes', 'Errands — optional, last column'],
];

export function CsvFormatGuide({ open, onClose }: { open: boolean; onClose: () => void }) {
  const t = useT();

  return (
    <Modal open={open} onClose={onClose} title={t('CSV format guide')} size="lg">
      <p className="text-sm text-muted-foreground">
        {t('One row per day. The header row must be present and the date must be YYYY-MM-DD.')}
      </p>
      <div className="mt-4 overflow-x-auto">
        <table className="w-full text-left text-sm">
          <thead>
            <tr className="border-b border-border text-xs uppercase tracking-wide text-muted-foreground">
              <th className="py-2 pr-4">{t('Column')}</th>
              <th className="py-2">{t('Example')}</th>
            </tr>
          </thead>
          <tbody>
            {ROWS.map(([col, example]) => (
              <tr key={col} className="border-b border-border last:border-0">
                <td className="py-2 pr-4 font-mono text-xs">{col}</td>
                <td className="py-2 text-muted-foreground">{example}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
      <p className="mt-4 text-xs text-muted-foreground">
        {t('Totals are computed on import; existing dates are skipped to avoid duplicates.')}
      </p>
    </Modal>
  );
}
