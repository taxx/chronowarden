# End-to-end tests (Playwright)

Browser tests for the ChronoWarden web client against a throwaway stack.

## How it works

`global-setup.ts` builds the client (`npm run build` in `apps/web`) and starts
`server.ts`, which:

1. starts a temporary Postgres (`apps/api/test/helpers/postgres.ts`),
2. runs the API migrations and mounts the Hono app under `/api`,
3. serves `apps/web/dist` on the same origin (like the production proxy).

Because the client renders to the real DOM, the tests use ordinary Playwright
selectors (`getByRole`, `getByLabel`).

## Running

```bash
cd e2e
npm install
npx playwright install chromium   # once
npx playwright test               # or: ../tool/check.sh e2e
```

Set `E2E_FORCE_BUILD=1` to rebuild the client, or `E2E_PORT` to change the port.

## Tests

- First-run admin setup through the UI, including the recovery phrase (24 words).
- Sign-in with the encryption passphrase, start/stop a day.
- Add a day in History.
- Download and validate a full backup from Settings.
- Admin creates an invite and sees the one-time token.
- Recover access with the recovery phrase and a new passphrase.
