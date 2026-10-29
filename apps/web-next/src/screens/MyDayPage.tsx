import { Card } from '../components/ui';
import { useT } from '../i18n';
import { useAuthStore } from '../state/auth';

export function MyDayPage() {
  const t = useT();
  const user = useAuthStore((state) => state.user);

  return (
    <Card>
      <h1 className="text-xl font-semibold text-white">{t('My Day')}</h1>
      <p className="mt-1 text-sm text-slate-400">{user?.email}</p>
    </Card>
  );
}
