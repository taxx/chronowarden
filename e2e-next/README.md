# End-to-end tests (Playwright) — React client

Browser tests for `apps/web-next` against a throwaway stack.

## How it works

`global-setup.ts` builds the client (`npm run build`) and starts `server.ts`,
which:

1. starts a temporary Postgres (`apps/api/test/helpers/postgres.ts`),
2. runs the API migrations and mounts the Hono app under `/api`,
3. serves `apps/web-next/dist` on the same origin (like the production proxy).

Because the React client renders to the real DOM, the tests use ordinary
Playwright selectors (`getByRole`, `getByLabel`) — no semantics workarounds.

## Running

```bash
cd e2e-next
npm install
npx playwright install chromium   # once
npx playwright test               # or: ../tool/check.sh e2e-next
```

Set `E2E_FORCE_BUILD=1` to rebuild the client, or `E2E_PORT` to change the port.

## Tests

- First-run admin setup through the UI, including the recovery phrase (24 words).
- Sign-in with the encryption passphrase, start/stop a day.
- Add a day in History.
- Download and validate a full backup from Settings.
- Admin creates an invite and sees the one-time token.
