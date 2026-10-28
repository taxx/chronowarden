# End-to-end tests (Playwright)

Browser tests that drive the **real** Flutter web app against the **real** API
backed by a throwaway Postgres.

## How it works

`global-setup.ts` builds the Flutter web bundle with

```
--dart-define=API_URL=              # same-origin /api/v1
--dart-define=ENABLE_SEMANTICS=true # expose the accessibility tree to the DOM
```

then starts `server.ts`, which:

1. starts a temporary Postgres (`apps/api/test/helpers/postgres.ts`),
2. runs the API migrations and mounts the Hono app under `/api`,
3. serves `apps/web/build/web` on the same origin (like the production proxy).

Flutter renders to a canvas, so the tests interact through the **semantics
tree** (buttons, text fields and labels are real DOM elements when semantics
are enabled). See `tests/app.spec.ts` for the helper that types into Flutter
text fields reliably.

## Running

```bash
cd e2e
npm install
npx playwright install chromium   # once
npx playwright test               # or: ../tool/check.sh e2e
```

Set `E2E_FORCE_BUILD=1` to rebuild the web bundle, or `E2E_PORT` to change the
port. Traces for failures land in `e2e/test-results/`.

## Tests

- First run: creates the admin through the UI and reaches the app shell.
- Sign-in: a fresh browser session signs in with email, password and the
  encryption passphrase.
- Backup: opens Settings and downloads a full backup, asserting the bundle
  envelope and structure.

## Regression coverage

The first-run test asserts that a new user **must** land on the recovery-phrase
onboarding and can dismiss it. Two bugs used to hide or trap that screen:

1. The signup screen was unmounted mid-flow — a rebuild recreated the
   `checkDatabaseState()` future, resetting the `FutureBuilder` — so the
   onboarding route was never pushed and the app fell through to the main shell.
2. The onboarding was pushed with `pushReplacement`, making it the *first*
   route, so "Continue to App" (`popUntil(isFirst)`) could never dismiss it.

The future is now cached in `main.dart` (reset only on a real sign-out) and the
route is pushed on top of the shell. This test guards both.
