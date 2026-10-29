import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { RouterProvider } from '@tanstack/react-router';
import { StrictMode } from 'react';
import { createRoot } from 'react-dom/client';

import './index.css';
import { router } from './router';
import { useAuthStore } from './state/auth';
import { useNotificationsStore } from './state/notifications';

const queryClient = new QueryClient({
  defaultOptions: {
    queries: { staleTime: 30_000, refetchOnWindowFocus: true },
  },
});

/**
 * Restore the session (cookie + cached DEK) before the first render, so the
 * router guards have a settled auth status to work with.
 */
async function start() {
  useNotificationsStore.getState().init();
  await useAuthStore.getState().bootstrap();

  createRoot(document.getElementById('root')!).render(
    <StrictMode>
      <QueryClientProvider client={queryClient}>
        <RouterProvider router={router} />
      </QueryClientProvider>
    </StrictMode>,
  );
}

void start();
