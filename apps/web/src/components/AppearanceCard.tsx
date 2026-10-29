import { Monitor, Moon, Sun } from 'lucide-react';

import { useT } from '../i18n';
import { useThemeStore, type ThemePreference } from '../state/theme';
import { Card, CardContent, CardHeader, cn } from './ui';

export function AppearanceCard() {
  const t = useT();
  const preference = useThemeStore((state) => state.preference);
  const setPreference = useThemeStore((state) => state.setPreference);

  const options: Array<{ value: ThemePreference; label: string; icon: typeof Sun }> = [
    { value: 'light', label: t('Light'), icon: Sun },
    { value: 'dark', label: t('Dark'), icon: Moon },
    { value: 'system', label: t('System'), icon: Monitor },
  ];

  return (
    <Card>
      <CardHeader title={t('Appearance')} description={t('Choose the theme used across the app.')} />
      <CardContent>
        <div className="grid grid-cols-3 gap-3">
          {options.map((option) => {
            const Icon = option.icon;
            const active = preference === option.value;
            return (
              <button
                key={option.value}
                type="button"
                onClick={() => setPreference(option.value)}
                className={cn(
                  'flex flex-col items-center gap-2 rounded-xl border p-4 text-sm transition',
                  active
                    ? 'border-primary bg-primary/10 text-foreground'
                    : 'border-border text-muted-foreground hover:bg-accent hover:text-foreground',
                )}
              >
                <Icon className="h-5 w-5" />
                {option.label}
              </button>
            );
          })}
        </div>
      </CardContent>
    </Card>
  );
}
