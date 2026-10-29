import { RouterProvider } from '@tanstack/react-router';
import { StrictMode } from 'react';
import { createRoot } from 'react-dom/client';

import './index.css';
import { router } from './router';
import { useAuthStore } from './state/auth';

/**
 * Restore the session (cookie + cached DEK) before the first render, so the
 * router guards have a settled auth status to work with.
 */
async function start() {
  await useAuthStore.getState().bootstrap();

  createRoot(document.getElementById('root')!).render(
    <StrictMode>
      <RouterProvider router={router} />
    </StrictMode>,
  );
}

void start();
