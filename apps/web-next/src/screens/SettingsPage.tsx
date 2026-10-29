import { useNavigate } from '@tanstack/react-router';
import { useState } from 'react';

import { Button, Card } from '../components/ui';
import { useLocaleStore, useT, type Locale } from '../i18n';
import { useAuthStore } from '../state/auth';

export function SettingsPage() {
  const t = useT();
  const navigate = useNavigate();
  const user = useAuthStore((state) => state.user);
  const logout = useAuthStore((state) => state.logout);
  const locale = useLocaleStore((state) => state.locale);
  const setLocale = useLocaleStore((state) => state.setLocale);
  const [busy, setBusy] = useState(false);

  async function onLogout() {
    setBusy(true);
    try {
      await logout();
      await navigate({ to: '/login' });
    } finally {
      setBusy(false);
    }
  }

  return (
    <Card>
      <h1 className="text-xl font-semibold text-white">{t('Settings')}</h1>

      <dl className="mt-4 space-y-2 text-sm">
        <div className="flex items-center justify-between gap-4">
          <dt className="text-slate-400">{t('Email')}</dt>
          <dd className="font-medium">{user?.email}</dd>
        </div>
      </dl>

      <div className="mt-6 max-w-xs space-y-1.5">
        <label htmlFor="locale" className="block text-sm font-medium text-slate-300">
          {t('Language')}
        </label>
        <select
          id="locale"
          value={locale}
          onChange={(event) => setLocale(event.target.value as Locale)}
          className="w-full rounded-lg border border-slate-700 bg-slate-900 px-3 py-2 text-sm text-slate-100"
        >
          <option value="en">English</option>
          <option value="sv">Svenska</option>
        </select>
      </div>

      <div className="mt-6">
        <Button variant="ghost" onClick={onLogout} disabled={busy}>
          {t('Log out')}
        </Button>
      </div>
    </Card>
  );
}
