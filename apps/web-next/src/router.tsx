import {
  Outlet,
  createRootRoute,
  createRoute,
  createRouter,
  redirect,
} from '@tanstack/react-router';

import { AppShell } from './components/AppShell';
import { AdminPage } from './screens/AdminPage';
import { HistoryPage } from './screens/HistoryPage';
import { LoginScreen } from './screens/LoginScreen';
import { MyDayPage } from './screens/MyDayPage';
import { RegisterScreen } from './screens/RegisterScreen';
import { PlaceholderPage } from './screens/PlaceholderPage';
import { RecoveryScreen } from './screens/RecoveryScreen';
import { SettingsPage } from './screens/SettingsPage';
import { SetupScreen } from './screens/SetupScreen';
import { UnlockScreen } from './screens/UnlockScreen';
import { useAuthStore } from './state/auth';

const rootRoute = createRootRoute({
  component: () => <Outlet />,
});

const setupRoute = createRoute({
  getParentRoute: () => rootRoute,
  path: '/setup',
  component: SetupScreen,
  beforeLoad: () => {
    const { status, hasUsers } = useAuthStore.getState();
    if (status === 'ready') throw redirect({ to: '/' });
    if (status === 'needs-passphrase') throw redirect({ to: '/passphrase' });
    if (status === 'unauthenticated' && hasUsers) throw redirect({ to: '/login' });
  },
});

const loginRoute = createRoute({
  getParentRoute: () => rootRoute,
  path: '/login',
  component: LoginScreen,
  beforeLoad: () => {
    const { status, hasUsers } = useAuthStore.getState();
    if (status === 'ready') throw redirect({ to: '/' });
    if (status === 'needs-passphrase') throw redirect({ to: '/passphrase' });
    if (status === 'unauthenticated' && !hasUsers) throw redirect({ to: '/setup' });
  },
});

const registerRoute = createRoute({
  getParentRoute: () => rootRoute,
  path: '/register',
  component: RegisterScreen,
  beforeLoad: () => {
    const { status, hasUsers } = useAuthStore.getState();
    if (status === 'ready') throw redirect({ to: '/' });
    if (status === 'needs-passphrase') throw redirect({ to: '/passphrase' });
    if (status === 'unauthenticated' && !hasUsers) throw redirect({ to: '/setup' });
  },
});

const passphraseRoute = createRoute({
  getParentRoute: () => rootRoute,
  path: '/passphrase',
  component: UnlockScreen,
  beforeLoad: () => {
    const { status, hasUsers } = useAuthStore.getState();
    if (status === 'ready') throw redirect({ to: '/' });
    if (status === 'unauthenticated') throw redirect({ to: hasUsers ? '/login' : '/setup' });
  },
});

const recoveryRoute = createRoute({
  getParentRoute: () => rootRoute,
  path: '/recovery',
  component: RecoveryScreen,
  beforeLoad: () => {
    const { status, pendingRecoveryPhrase } = useAuthStore.getState();
    if (status !== 'ready' || !pendingRecoveryPhrase) throw redirect({ to: '/' });
  },
});

const appRoute = createRoute({
  getParentRoute: () => rootRoute,
  id: 'app',
  component: AppShell,
  beforeLoad: () => {
    const { status, hasUsers } = useAuthStore.getState();
    if (status === 'needs-passphrase') throw redirect({ to: '/passphrase' });
    if (status === 'unauthenticated') throw redirect({ to: hasUsers ? '/login' : '/setup' });
  },
});

const indexRoute = createRoute({
  getParentRoute: () => appRoute,
  path: '/',
  component: MyDayPage,
});

const settingsRoute = createRoute({
  getParentRoute: () => appRoute,
  path: '/settings',
  component: SettingsPage,
});

const placeholder = (titleKey: string) => () => <PlaceholderPage titleKey={titleKey} />;


const overviewRoute = createRoute({
  getParentRoute: () => appRoute,
  path: '/overview',
  component: placeholder('Overview'),
});
const historyRoute = createRoute({
  getParentRoute: () => appRoute,
  path: '/history',
  component: HistoryPage,
});
const projectionRoute = createRoute({
  getParentRoute: () => appRoute,
  path: '/projection',
  component: placeholder('Projection'),
});
const transitRoute = createRoute({
  getParentRoute: () => appRoute,
  path: '/transit',
  component: placeholder('Transit'),
});
const adminRoute = createRoute({
  getParentRoute: () => appRoute,
  path: '/admin',
  component: AdminPage,
  beforeLoad: () => {
    if (useAuthStore.getState().user?.role !== 'admin') throw redirect({ to: '/' });
  },
});

const routeTree = rootRoute.addChildren([
  setupRoute,
  loginRoute,
  registerRoute,
  passphraseRoute,
  recoveryRoute,
  appRoute.addChildren([
    indexRoute,
    overviewRoute,
    historyRoute,
    projectionRoute,
    transitRoute,
    settingsRoute,
    adminRoute,
  ]),
]);

export const router = createRouter({ routeTree });

declare module '@tanstack/react-router' {
  interface Register {
    router: typeof router;
  }
}
