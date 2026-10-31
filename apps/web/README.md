# ChronoWarden web client

The React + TypeScript client for ChronoWarden.

## Requirements

- **Node 26 LTS** (see `.nvmrc`) — older Node lines have known security issues.

## Scripts

```bash
npm install
npm run dev        # Vite dev server on :5173 (proxies /api to :8080)
npm run build      # typecheck + production build to dist/
npm test           # Vitest (domain, crypto, services, components, i18n guard)
npm run typecheck  # tsc --noEmit
```

The API must be running for the app to do anything (auth, data). Start it with
`cd ../../apps/api && bun run src/index.ts` or `docker compose up`.

## Structure

```
src/
  api/          typed fetch client + endpoint modules
  lib/          crypto, format, date, download, notify + domain/ (pure logic)
  queries/      TanStack Query hooks
  services/     encrypted data services (time logs, settings, transit, presets)
  screens/      route screens
  components/   UI kit + feature components (banners, cards, dialogs)
  state/        Zustand stores (auth, notifications)
  i18n/         t() + English keys + Swedish catalog + guard test
  router.tsx    TanStack Router with auth guards
  main.tsx      entry point
public/         icons, generated version.json + CHANGELOG.md
tool/           generate_metadata.sh (version + changelog from git)
```

## Key behaviours

- **Crypto:** `src/lib/crypto.ts` is a byte-for-byte port of the original
  client's crypto, verified against golden fixtures, so existing
  envelopes, ciphertext and passphrases keep working. Recovery phrases use
  official BIP39; each unlock migrates the stored `recovery_hash`.
- **Auth:** httpOnly cookie session; route guards redirect to setup / login /
  unlock / recovery as appropriate.
- **Realtime:** `components/RealtimeBridge.tsx` subscribes to the API's SSE
  stream and invalidates queries.
- **Localization:** every user-facing string goes through `t(...)`; the guard
  test fails on missing or unused Swedish entries.

## Tests

- Unit/component: `npm test`.
- Browser E2E: `../../tool/check.sh e2e` (Playwright in `../../e2e`).
