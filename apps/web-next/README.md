# ChronoWarden web client (React)

The rewrite of the Flutter web client. See
[`docs/UI_REWRITE_PLAN.md`](../../docs/UI_REWRITE_PLAN.md) for the plan and the
agreed stack.

The Flutter client still lives at `apps/web` and keeps working; this one is
built alongside it and becomes `apps/web` at cutover.

## Requirements

- **Node 26 LTS** (see `.nvmrc`) — older Node lines have known security issues.

## Scripts

```bash
npm install
npm run dev        # Vite dev server on :5173 (proxies /api to :8080)
npm run build      # typecheck + production build to dist/ (writes version.json)
npm test           # Vitest (domain, crypto, services, components, i18n guard)
npm run typecheck  # tsc --noEmit
```

## What's implemented

- **Foundation** — Vite + React 19 + TypeScript + Tailwind; Node 26 pinned;
  PWA (manifest, service worker, installable) with code-split chunks.
- **Crypto** — `src/lib/crypto.ts` is a byte-for-byte port of the Dart
  `CryptoService` (PBKDF2 310k, AES-256-GCM, envelope wrap). Verified against
  golden fixtures the Dart client generated. Recovery phrases use the official
  **BIP39** wordlist (`@scure/bip39`); the DEK/envelope/passphrase are unchanged
  and each unlock migrates the stored `recovery_hash`.
- **Domain** (pure + tested) — work config (ISO/reduced weeks), time log (leave
  time, overtime, flex, non-work), formatting, CSV import/export, leave-alert
  evaluation, transit retry guard, transit config, travel presets.
- **Data layer** — typed API client over httpOnly cookie sessions; encrypted
  time-log/settings/preset services; TanStack Query; SSE realtime bridge.
- **Screens** — first-run setup, invite registration, sign-in, unlock, recovery
  onboarding, forgot-passphrase recovery, My Day (start/stop, lunch, non-work,
  flex, live leave time, time bank, preset picker), History (add/edit/delete +
  CSV), Overview (week/month/year views with ISO week gutter), Projection
  (balance chart), Transit (stations, journeys, pinned journey, retry/back-off),
  Settings (work hours, travel presets, notifications, preferences, recovery
  phrase, backup/restore, language, What's New, logout) and Admin (users +
  invites).
- **Notifications** — leave-time alerts with in-app banner, OS notification,
  sound and vibration, snooze/dismiss.
- **Update prompt** — polls `version.json` and offers a reload.
- **i18n** — English keys + Swedish catalog with a missing/stale guard test.
- **E2E** — Playwright suite in `../../e2e-next`.

Feature parity with the Flutter client is complete for v1.
