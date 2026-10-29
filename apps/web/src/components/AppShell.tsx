import { Link, Outlet, useNavigate } from '@tanstack/react-router';
import {
  CalendarDays,
  History,
  Home,
  LogOut,
  Monitor,
  Moon,
  Settings as SettingsIcon,
  ShieldCheck,
  Sun,
  TrainFront,
  TrendingUp,
} from 'lucide-react';

import { useT } from '../i18n';
import { useAuthStore } from '../state/auth';
import { useThemeStore, type ThemePreference } from '../state/theme';
import { AlertBanner } from './AlertBanner';
import { RealtimeBridge } from './RealtimeBridge';
import { Toaster } from './Toaster';
import { UpdateBanner } from './UpdateBanner';
import { Button, cn } from './ui';

/** Nav entries with literal routes + literal translation keys (i18n guard). */
function useNav() {
  const t = useT();
  const isAdmin = useAuthStore((state) => state.user?.role === 'admin');
  return [
    { to: '/' as const, label: t('My Day'), icon: Home, exact: true },
    { to: '/overview' as const, label: t('Overview'), icon: CalendarDays, exact: false },
    { to: '/history' as const, label: t('History'), icon: History, exact: false },
    { to: '/projection' as const, label: t('Projection'), icon: TrendingUp, exact: false },
    { to: '/transit' as const, label: t('Transit'), icon: TrainFront, exact: false },
    { to: '/settings' as const, label: t('Settings'), icon: SettingsIcon, exact: false },
    ...(isAdmin
      ? [{ to: '/admin' as const, label: t('Admin'), icon: ShieldCheck, exact: false }]
      : []),
  ];
}

const THEME_ORDER: ThemePreference[] = ['light', 'dark', 'system'];

/** One compact button that cycles light → dark → system. */
function ThemeToggle() {
  const t = useT();
  const preference = useThemeStore((state) => state.preference);
  const setPreference = useThemeStore((state) => state.setPreference);

  const label =
    preference === 'light' ? t('Light') : preference === 'dark' ? t('Dark') : t('System');
  const Icon = preference === 'light' ? Sun : preference === 'dark' ? Moon : Monitor;
  const next = THEME_ORDER[(THEME_ORDER.indexOf(preference) + 1) % THEME_ORDER.length]!;

  return (
    <Button
      variant="ghost"
      size="icon"
      aria-label={`${t('Appearance')}: ${label}`}
      title={`${t('Appearance')}: ${label}`}
      onClick={() => setPreference(next)}
      className="h-8 w-8"
    >
      <Icon className="h-4 w-4" />
    </Button>
  );
}

export function AppShell() {
  const t = useT();
  const navigate = useNavigate();
  const user = useAuthStore((state) => state.user);
  const logout = useAuthStore((state) => state.logout);
  const nav = useNav();

  async function onLogout() {
    await logout();
    await navigate({ to: '/login' });
  }

  return (
    <div className="min-h-dvh bg-background text-foreground">
      {/* Desktop sidebar */}
      <aside className="fixed inset-y-0 left-0 z-40 hidden w-60 flex-col border-r border-border bg-card/60 backdrop-blur lg:flex">
        <div className="flex h-16 items-center gap-2 px-5">
          <div className="grid h-8 w-8 place-items-center rounded-lg bg-primary text-primary-foreground">
            <ShieldCheck className="h-4 w-4" />
          </div>
          <span className="font-semibold tracking-tight">{t('ChronoWarden')}</span>
        </div>
        <nav className="flex-1 space-y-1 px-3">
          {nav.map((item) => {
            const Icon = item.icon;
            return (
              <Link
                key={item.to}
                to={item.to}
                className="flex items-center gap-3 rounded-lg px-3 py-2 text-sm font-medium text-muted-foreground transition hover:bg-accent hover:text-foreground"
                activeProps={{ className: 'bg-accent text-foreground' }}
                activeOptions={{ exact: item.exact }}
              >
                <Icon className="h-4 w-4" />
                {item.label}
              </Link>
            );
          })}
        </nav>
        <div className="border-t border-border p-3">
          <div className="flex items-center justify-between gap-2 px-2">
            <p className="min-w-0 truncate text-xs text-muted-foreground">{user?.email}</p>
            <ThemeToggle />
          </div>
          <Button variant="ghost" className="mt-1 w-full justify-start" onClick={onLogout}>
            <LogOut className="h-4 w-4" />
            {t('Log out')}
          </Button>
        </div>
      </aside>

      {/* Mobile top bar */}
      <header className="sticky top-0 z-40 flex h-14 items-center justify-between border-b border-border bg-card/80 px-4 backdrop-blur lg:hidden">
        <div className="flex items-center gap-2">
          <div className="grid h-7 w-7 place-items-center rounded-lg bg-primary text-primary-foreground">
            <ShieldCheck className="h-3.5 w-3.5" />
          </div>
          <span className="font-semibold tracking-tight">{t('ChronoWarden')}</span>
        </div>
        <ThemeToggle />
      </header>

      <main className="lg:pl-60">
        <div className="mx-auto max-w-4xl px-4 py-6 pb-24 lg:pb-10">
          <RealtimeBridge />
          <UpdateBanner />
          <AlertBanner />
          <Outlet />
        </div>
      </main>

      {/* Mobile bottom nav */}
      <nav className="fixed inset-x-0 bottom-0 z-40 flex border-t border-border bg-card/90 backdrop-blur lg:hidden">
        {nav.map((item) => {
          const Icon = item.icon;
          return (
            <Link
              key={item.to}
              to={item.to}
              className={cn(
                'flex flex-1 flex-col items-center gap-1 py-2 text-[11px] font-medium text-muted-foreground',
              )}
              activeProps={{ className: 'text-primary' }}
              activeOptions={{ exact: item.exact }}
            >
              <Icon className="h-5 w-5" />
              {item.label}
            </Link>
          );
        })}
      </nav>

      <Toaster />
    </div>
  );
}
