import { Link, Outlet, useNavigate } from '@tanstack/react-router';

import { useT } from '../i18n';
import { useAuthStore } from '../state/auth';
import { RealtimeBridge } from './RealtimeBridge';
import { Button } from './ui';

const linkClass = 'rounded-lg px-3 py-1.5 text-slate-300 hover:bg-slate-800 hover:text-white';
const activeProps = { className: 'bg-slate-800 text-white' };

export function AppShell() {
  const t = useT();
  const navigate = useNavigate();
  const user = useAuthStore((state) => state.user);
  const logout = useAuthStore((state) => state.logout);

  async function onLogout() {
    await logout();
    await navigate({ to: '/login' });
  }

  return (
    <div className="min-h-dvh bg-slate-950 text-slate-100">
      <header className="border-b border-slate-800 bg-slate-900/70 backdrop-blur">
        <div className="mx-auto flex max-w-5xl flex-wrap items-center gap-3 px-4 py-3">
          <span className="font-semibold">{t('ChronoWarden')}</span>
          <nav className="flex flex-1 flex-wrap gap-1 text-sm">
            <Link to="/" className={linkClass} activeProps={activeProps}>
              {t('My Day')}
            </Link>
            <Link to="/overview" className={linkClass} activeProps={activeProps}>
              {t('Overview')}
            </Link>
            <Link to="/history" className={linkClass} activeProps={activeProps}>
              {t('History')}
            </Link>
            <Link to="/projection" className={linkClass} activeProps={activeProps}>
              {t('Projection')}
            </Link>
            <Link to="/transit" className={linkClass} activeProps={activeProps}>
              {t('Transit')}
            </Link>
            <Link to="/settings" className={linkClass} activeProps={activeProps}>
              {t('Settings')}
            </Link>
            {user?.role === 'admin' ? (
              <Link to="/admin" className={linkClass} activeProps={activeProps}>
                {t('Admin')}
              </Link>
            ) : null}
          </nav>
          <Button variant="ghost" onClick={onLogout}>
            {t('Log out')}
          </Button>
        </div>
      </header>
      <main className="mx-auto max-w-5xl px-4 py-6">
        <RealtimeBridge />
        <Outlet />
      </main>
    </div>
  );
}
