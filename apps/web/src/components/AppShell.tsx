import { Link, Outlet, useNavigate, useRouterState } from '@tanstack/react-router';
import { useState } from 'react';
import {
  CalendarDays,
  Check,
  ChevronUp,
  ChevronsLeft,
  ChevronsRight,
  History,
  Home,
  Lock,
  LogOut,
  Monitor,
  Moon,
  Settings as SettingsIcon,
  ShieldCheck,
  Sparkles,
  Sun,
  TrainFront,
  TrendingUp,
  UserRound,
} from 'lucide-react';

import { useT } from '../i18n';
import { useAuthStore } from '../state/auth';
import { useThemeStore, type ThemePreference } from '../state/theme';
import { AlertBanner } from './AlertBanner';
import { RealtimeBridge } from './RealtimeBridge';
import { UpdateBanner } from './UpdateBanner';
import {
  Button,
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuLabel,
  DropdownMenuSeparator,
  DropdownMenuTrigger,
  Sheet,
  Toaster,
  Tooltip,
  TooltipContent,
  TooltipProvider,
  TooltipTrigger,
  cn,
} from './ui';

const SIDEBAR_KEY = 'cw_sidebar_collapsed';

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

/** One compact button that cycles light → dark → system (used on mobile). */
function ThemeToggle() {
  const t = useT();
  const preference = useThemeStore((state) => state.preference);
  const setPreference = useThemeStore((state) => state.setPreference);

  const label =
    preference === 'light' ? t('Light') : preference === 'dark' ? t('Dark') : t('System');
  const Icon = preference === 'light' ? Sun : preference === 'dark' ? Moon : Monitor;
  const next = THEME_ORDER[(THEME_ORDER.indexOf(preference) + 1) % THEME_ORDER.length]!;

  return (
    <Tooltip>
      <TooltipTrigger asChild>
        <Button
          variant="ghost"
          size="icon"
          aria-label={`${t('Appearance')}: ${label}`}
          onClick={() => setPreference(next)}
          className="h-8 w-8"
        >
          <Icon className="h-4 w-4" />
        </Button>
      </TooltipTrigger>
      <TooltipContent>
        {t('Appearance')}: {label}
      </TooltipContent>
    </Tooltip>
  );
}

function AccountMenuItems() {
  const t = useT();
  const navigate = useNavigate();
  const logout = useAuthStore((state) => state.logout);
  const preference = useThemeStore((state) => state.preference);
  const setPreference = useThemeStore((state) => state.setPreference);

  const themes: Array<{ value: ThemePreference; label: string; icon: typeof Sun }> = [
    { value: 'light', label: t('Light'), icon: Sun },
    { value: 'dark', label: t('Dark'), icon: Moon },
    { value: 'system', label: t('System'), icon: Monitor },
  ];

  async function onLogout() {
    await logout();
    await navigate({ to: '/login' });
  }

  return (
    <>
      <DropdownMenuLabel>{t('Appearance')}</DropdownMenuLabel>
      {themes.map((theme) => {
        const Icon = theme.icon;
        return (
          <DropdownMenuItem key={theme.value} onClick={() => setPreference(theme.value)}>
            <Icon />
            {theme.label}
            {preference === theme.value ? <Check className="ml-auto h-3.5 w-3.5" /> : null}
          </DropdownMenuItem>
        );
      })}
      <DropdownMenuSeparator />
      <DropdownMenuItem asChild>
        <Link to="/changelog" className="flex items-center gap-2">
          <Sparkles />
          {t("What's New")}
        </Link>
      </DropdownMenuItem>
      <DropdownMenuItem onClick={() => void onLogout()}>
        <LogOut />
        {t('Log out')}
      </DropdownMenuItem>
    </>
  );
}

function AccountMenu({ collapsed }: { collapsed: boolean }) {
  const t = useT();
  const user = useAuthStore((state) => state.user);

  return (
    <DropdownMenu>
      <DropdownMenuTrigger asChild>
        {collapsed ? (
          <Button variant="ghost" size="icon" className="w-full" aria-label={t('Account')}>
            <UserRound className="h-4 w-4" />
          </Button>
        ) : (
          <Button variant="ghost" className="w-full justify-between px-2">
            <span className="min-w-0 truncate text-xs text-muted-foreground">{user?.email}</span>
            <ChevronUp className="h-3.5 w-3.5 shrink-0 text-muted-foreground" />
          </Button>
        )}
      </DropdownMenuTrigger>
      <DropdownMenuContent side="top" align={collapsed ? 'center' : 'start'} className="w-56">
        <DropdownMenuLabel className="truncate">{user?.email}</DropdownMenuLabel>
        <DropdownMenuSeparator />
        <AccountMenuItems />
      </DropdownMenuContent>
    </DropdownMenu>
  );
}

function SidebarNav({ collapsed }: { collapsed: boolean }) {
  const nav = useNav();
  return (
    <>
      {nav.map((item) => {
        const Icon = item.icon;
        const link = (
          <Link
            to={item.to}
            className={cn(
              'flex items-center rounded-lg py-2 text-sm font-medium text-muted-foreground transition hover:bg-accent hover:text-foreground',
              collapsed ? 'justify-center px-0' : 'gap-3 px-3',
            )}
            activeProps={{ className: 'bg-accent text-foreground' }}
            activeOptions={{ exact: item.exact }}
          >
            <Icon className="h-4 w-4 shrink-0" />
            {collapsed ? null : item.label}
          </Link>
        );
        return collapsed ? (
          <Tooltip key={item.to}>
            <TooltipTrigger asChild>{link}</TooltipTrigger>
            <TooltipContent side="right">{item.label}</TooltipContent>
          </Tooltip>
        ) : (
          <div key={item.to}>{link}</div>
        );
      })}
    </>
  );
}

function SidebarToggle({ collapsed, onToggle }: { collapsed: boolean; onToggle: () => void }) {
  const t = useT();
  return (
    <Tooltip>
      <TooltipTrigger asChild>
        <Button
          variant="ghost"
          size={collapsed ? 'icon' : 'default'}
          onClick={onToggle}
          aria-label={collapsed ? t('Expand') : t('Collapse')}
          className={cn('mt-1 w-full', !collapsed && 'justify-start')}
        >
          {collapsed ? <ChevronsRight className="h-4 w-4" /> : <ChevronsLeft className="h-4 w-4" />}
          {collapsed ? null : t('Collapse')}
        </Button>
      </TooltipTrigger>
      <TooltipContent side="right">{collapsed ? t('Expand') : t('Collapse')}</TooltipContent>
    </Tooltip>
  );
}

function MobileNav() {
  const nav = useNav();
  return (
    <>
      {nav.map((item) => {
        const Icon = item.icon;
        return (
          <Link
            key={item.to}
            to={item.to}
            className="flex flex-1 flex-col items-center gap-1 py-2 text-[11px] font-medium text-muted-foreground"
            activeProps={{ className: 'text-primary' }}
            activeOptions={{ exact: item.exact }}
          >
            <Icon className="h-5 w-5" />
            {item.label}
          </Link>
        );
      })}
    </>
  );
}

export function AppShell() {
  const t = useT();
  const pathname = useRouterState({ select: (state) => state.location.pathname });
  const [collapsed, setCollapsed] = useState(
    () => localStorage.getItem(SIDEBAR_KEY) === 'true',
  );

  function toggleSidebar() {
    const next = !collapsed;
    localStorage.setItem(SIDEBAR_KEY, String(next));
    setCollapsed(next);
  }

  return (
    <TooltipProvider delayDuration={300}>
      <div className="min-h-dvh bg-background text-foreground">
        {/* Desktop sidebar */}
        <aside
          className={cn(
            'fixed inset-y-0 left-0 z-40 hidden flex-col border-r border-border bg-card/60 backdrop-blur transition-[width] duration-200 lg:flex',
            collapsed ? 'w-16' : 'w-60',
          )}
        >
          <div className={cn('flex h-16 items-center', collapsed ? 'justify-center' : 'gap-2 px-5')}>
            <img src="/logo.png" alt="" width={32} height={32} className="h-8 w-8 shrink-0" />
            {collapsed ? null : (
              <span className="font-semibold tracking-tight">{t('ChronoWarden')}</span>
            )}
          </div>
          <nav className={cn('flex-1 space-y-1', collapsed ? 'px-2' : 'px-3')}>
            <SidebarNav collapsed={collapsed} />
          </nav>
          <div className={cn('border-t border-border', collapsed ? 'p-2' : 'p-3')}>
            <AccountMenu collapsed={collapsed} />
            <SidebarToggle collapsed={collapsed} onToggle={toggleSidebar} />
          </div>
        </aside>

        {/* Mobile top bar */}
        <header className="sticky top-0 z-40 flex h-14 items-center justify-between border-b border-border bg-card/80 px-4 backdrop-blur lg:hidden">
          <div className="flex items-center gap-2">
            <img src="/logo.png" alt="" width={28} height={28} className="h-7 w-7" />
            <span className="font-semibold tracking-tight">{t('ChronoWarden')}</span>
          </div>
          <div className="flex items-center gap-1">
            <ThemeToggle />
            <MobileAccountSheet />
          </div>
        </header>

        <main className={cn(collapsed ? 'lg:pl-16' : 'lg:pl-60')}>
          <div className="mx-auto max-w-4xl px-4 py-6 pb-24 lg:pb-10">
            <RealtimeBridge />
            <UpdateBanner />
            <AlertBanner />
            <div key={pathname} className="animate-fade-in">
              <Outlet />
            </div>
          </div>
        </main>

        {/* Mobile bottom nav */}
        <nav className="fixed inset-x-0 bottom-0 z-40 flex border-t border-border bg-card/90 backdrop-blur lg:hidden">
          <MobileNav />
        </nav>

        <Toaster />
      </div>
    </TooltipProvider>
  );
}

/** Mobile-only account drawer (kept separate from the desktop sidebar). */
function MobileAccountSheet() {
  const t = useT();
  const navigate = useNavigate();
  const user = useAuthStore((state) => state.user);
  const logout = useAuthStore((state) => state.logout);
  const preference = useThemeStore((state) => state.preference);
  const setPreference = useThemeStore((state) => state.setPreference);
  const [open, setOpen] = useState(false);

  const themes: Array<{ value: ThemePreference; label: string; icon: typeof Sun }> = [
    { value: 'light', label: t('Light'), icon: Sun },
    { value: 'dark', label: t('Dark'), icon: Moon },
    { value: 'system', label: t('System'), icon: Monitor },
  ];

  async function onLogout() {
    setOpen(false);
    await logout();
    await navigate({ to: '/login' });
  }

  return (
    <>
      <Button
        variant="ghost"
        size="icon"
        aria-label={t('Account')}
        className="h-8 w-8"
        onClick={() => setOpen(true)}
      >
        <UserRound className="h-4 w-4" />
      </Button>
      <Sheet open={open} onOpenChange={setOpen} title={t('Account')} side="right">
        <p className="text-sm text-muted-foreground">{user?.email}</p>

        <p className="mt-5 text-xs uppercase tracking-wide text-muted-foreground">
          {t('Appearance')}
        </p>
        <div className="mt-2 space-y-1">
          {themes.map((theme) => {
            const Icon = theme.icon;
            return (
              <button
                key={theme.value}
                type="button"
                onClick={() => setPreference(theme.value)}
                className="flex w-full items-center gap-3 rounded-lg px-3 py-2 text-sm transition hover:bg-accent"
              >
                <Icon className="h-4 w-4" />
                {theme.label}
                {preference === theme.value ? (
                  <Check className="ml-auto h-4 w-4 text-primary" />
                ) : null}
              </button>
            );
          })}
        </div>

        <div className="mt-5 space-y-1 border-t border-border pt-3">
          <Link
            to="/encryption"
            onClick={() => setOpen(false)}
            className="flex items-center gap-3 rounded-lg px-3 py-2 text-sm transition hover:bg-accent"
          >
            <Lock className="h-4 w-4" />
            {t('Encryption')}
          </Link>
          <Link
            to="/changelog"
            onClick={() => setOpen(false)}
            className="flex items-center gap-3 rounded-lg px-3 py-2 text-sm transition hover:bg-accent"
          >
            <Sparkles className="h-4 w-4" />
            {t("What's New")}
          </Link>
          <button
            type="button"
            onClick={() => void onLogout()}
            className="flex w-full items-center gap-3 rounded-lg px-3 py-2 text-sm text-destructive transition hover:bg-accent"
          >
            <LogOut className="h-4 w-4" />
            {t('Log out')}
          </button>
        </div>
      </Sheet>
    </>
  );
}
