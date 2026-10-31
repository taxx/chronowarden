import { Link, useNavigate } from '@tanstack/react-router';
import { useState } from 'react';
import { Languages, LogOut, Sparkles, User } from 'lucide-react';

import { AboutCard } from '../components/AboutCard';
import { AppearanceCard } from '../components/AppearanceCard';
import { BackupCard } from '../components/BackupCard';
import { ChangePassphraseCard } from '../components/ChangePassphraseCard';
import { ConfirmDialog } from '../components/ui';
import { NotificationSettingsCard } from '../components/NotificationSettingsCard';
import { PreferencesCard } from '../components/PreferencesCard';
import { RecoveryPhraseCard } from '../components/RecoveryPhraseCard';
import { TravelPresetsCard } from '../components/TravelPresetsCard';
import { WorkConfigCard } from '../components/WorkConfigCard';
import { Button, Card, CardContent, CardHeader, SelectField } from '../components/ui';
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
  const [confirmingLogout, setConfirmingLogout] = useState(false);

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
    <div className="space-y-4">
      <Card>
        <CardHeader
          title={
            <span className="flex items-center gap-2">
              <User className="h-4 w-4 text-primary" />
              {t('Settings')}
            </span>
          }
          description={user?.email}
          action={
            <Link
              to="/changelog"
              className="inline-flex items-center gap-2 text-sm text-primary hover:underline"
            >
              <Sparkles className="h-3.5 w-3.5" />
              {t("What's New")}
            </Link>
          }
        />
        <CardContent className="space-y-4">
          <div className="flex items-center gap-2 text-sm">
            <Languages className="h-4 w-4 text-muted-foreground" />
            <label htmlFor="locale" className="text-muted-foreground">
              {t('Language')}
            </label>
            <SelectField
              id="locale"
              className="ml-auto w-40"
              value={locale}
              onValueChange={(value) => setLocale(value as Locale)}
              options={[
                { value: 'en', label: 'English' },
                { value: 'sv', label: 'Svenska' },
              ]}
            />
          </div>
          <Button variant="outline" onClick={() => setConfirmingLogout(true)}>
            <LogOut className="h-4 w-4" />
            {t('Log out')}
          </Button>
        </CardContent>
      </Card>

      <AppearanceCard />
      <WorkConfigCard />
      <PreferencesCard />
      <TravelPresetsCard />
      <NotificationSettingsCard />
      <ChangePassphraseCard />
      <RecoveryPhraseCard />
      <BackupCard />
      <AboutCard />

      <ConfirmDialog
        open={confirmingLogout}
        title={t('Log out?')}
        description={t('You will need your password and passphrase to sign in again.')}
        confirmLabel={t('Log out')}
        busy={busy}
        onClose={() => setConfirmingLogout(false)}
        onConfirm={() => void onLogout()}
      />
    </div>
  );
}
