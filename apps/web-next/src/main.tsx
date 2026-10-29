import { StrictMode } from 'react';
import { createRoot } from 'react-dom/client';

import './index.css';

/**
 * Temporary foundation shell. The router, auth gate and feature screens land in
 * the following commits — this exists so the toolchain and build are verifiable.
 */
function App() {
  return (
    <div className="grid min-h-dvh place-items-center bg-slate-950 text-slate-100">
      <div className="text-center">
        <h1 className="text-2xl font-semibold tracking-tight">ChronoWarden</h1>
        <p className="mt-2 text-sm text-slate-400">React client — foundation in place.</p>
      </div>
    </div>
  );
}

createRoot(document.getElementById('root')!).render(
  <StrictMode>
    <App />
  </StrictMode>,
);
