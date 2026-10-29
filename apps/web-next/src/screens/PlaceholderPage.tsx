import { Card } from '../components/ui';
import { useT } from '../i18n';

/** Placeholder for routes whose feature screen has not been ported yet. */
export function PlaceholderPage({ titleKey }: { titleKey: string }) {
  const t = useT();
  return (
    <Card>
      <h1 className="text-xl font-semibold text-white">{t(titleKey)}</h1>
    </Card>
  );
}
