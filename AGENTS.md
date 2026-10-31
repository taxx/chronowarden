# Agent Context: ChronoWarden Coding Harness

You are an expert TypeScript developer acting as a dedicated pair-programmer for
**ChronoWarden**, a personal time-tracking and overtime-protection app. The
stack is 100 % self-hosted: a **React 19 web client** talks to a **Bun + Hono
API** backed by **PostgreSQL 18**, all run with Docker Compose.

## Core Directives

1. **KISS Principle:** Prioritize clean, minimal, readable, and highly
   maintainable code. Avoid over-engineering, unnecessary abstractions, or
   redundant boilerplate.
2. **State Management (client):** TanStack Query for server state, Zustand for
   small client state. Do not introduce heavy architecture frameworks.
3. **Time & Duration Representation:** All time durations (expected work time,
   overhead buffers, overtime net balances) MUST be handled and stored as an
   `int` representing total minutes in both backend and domain models.
   Conversion to display strings (`HH:mm`, `8h 30m`) belongs strictly in the
   presentation layer (`src/lib/format.ts`).
4. **Data Privacy & Isolation:** Every user-data query is scoped to the
   authenticated user. There is no RLS: the API is the only client of the
   database and enforces ownership in the route layer. Never accept a
   `user_id` from the client for scoping.
5. **Validation:** `cd apps/web && npm run typecheck` and
   `cd apps/api && bunx tsc --noEmit` must be clean. `./tool/check.sh` runs
   everything (typecheck, tests, build).
6. **Tests:** Use tests and mocks where applicable to ensure you don't break
   things and make sure new features work. `npm test` (web), `bun test` (API)
   and the Playwright suite (`e2e/`) must pass.
7. **Deploy as part of the routine:** Every completed code change (fix or
   feature) MUST be deployed as part of the same working session, unless the
   user explicitly says not to. After committing and pushing, run the SSH
   rebuild + verification steps in "Release to production" below.
8. **Localization:** All user-facing text goes through `t('English text')`
   (`src/i18n`). Add the Swedish entry to `apps/web/src/i18n/index.ts` **in the
   same commit**, or `src/i18n/i18n.test.ts` fails. The guard also fails on
   *unused* entries and on dynamic keys (the literal must be at the `t(...)`
   call site).
9. **Generated metadata:** `apps/web/public/version.json` and
   `apps/web/public/CHANGELOG.md` are produced by
   `apps/web/tool/generate_metadata.sh`. They are **gitignored** and generated
   at deploy/build time so they always reflect the deployed revision. Never
   hand-edit them.

---

## Architecture Overview

```
                        https://chronowarden.slumpen.com  (host reverse proxy, TLS)
                                        │
                              ┌─────────▼──────────┐
                              │  proxy (nginx)     │   8981:80
                              │  /api/* → api      │
                              │  /*     → web      │
                              └───┬────────────┬───┘
                                  │            │
                    ┌─────────────▼──┐   ┌─────▼──────────────┐
                    │  web (nginx)   │   │  api (Bun + Hono)  │
                    │  React build   │   │  REST + SSE + SL   │
                    └────────────────┘   └─────┬──────────────┘
                                               │
                                        ┌──────▼───────┐
                                        │ postgres:18  │  (volume data/postgres)
                                        └──────┬───────┘
                                               │
                                        ┌──────▼───────┐
                                        │  backup      │  pg_dump + retention
                                        └──────────────┘
```

- **Same origin** for app and API (`/api/*`) → no CORS and no API URL baked
  into the JS bundle.
- All writes go through the API, so cross-device sync uses **SSE** (the API
  publishes an event per write) instead of Postgres logical replication.
- The SL Journey Planner proxy + response slimming live in the API
  (`POST /api/v1/sl/proxy`), not a separate service.
- The database is not published on the host; only the API reaches it.
- Zero-knowledge: the server only ever stores AES-256-GCM ciphertext plus the
  envelope metadata it cannot unwrap.

---

## Repository Layout

```
apps/
  web/                 React 19 + TypeScript + Vite client
    src/
      api/             typed fetch client + endpoint modules
      lib/             crypto.ts, format.ts, date.ts, download.ts, notify.ts
        domain/        pure domain logic (work config, time log, CSV, transit…)
      queries/         TanStack Query hooks
      services/        encrypted data services (time logs, settings, transit…)
      screens/         route screens
      components/      UI kit + feature components
      state/           Zustand stores (auth, notifications)
      i18n/            t() + English keys + Swedish catalog + guard test
      router.tsx       TanStack Router with auth guards
      main.tsx         entry point
    public/            icons, generated version.json + CHANGELOG.md
    tool/              generate_metadata.sh
    Dockerfile         builds the static bundle (Node 26 → nginx)
  api/                 Bun + Hono API
    src/
      index.ts         entry point: migrate, then Bun.serve
      app.ts           Hono app, /api/v1 routes, error mapping, CORS
      config.ts        env config (DATABASE_URL, PORT, SESSION_TTL_DAYS, …)
      db.ts            shared postgres.js pool
      migrate.ts       numbered SQL migration runner
      auth.ts          session middleware (cookie or bearer)
      password.ts      argon2id hashing via Bun.password
      tokens.ts        token generation + SHA-256 hashing
      events.ts        in-process SSE pub/sub hub
      sl.ts            SL Journey Planner fetch + response slimming
      routes/          auth, admin, data, backup, sl, events
    migrations/        001_init.sql … (applied on startup)
    test/
      unit/            fast unit tests (`bun test test/unit`)
      integration/     full-stack API tests against a throwaway Postgres
      helpers/         ephemeral Postgres helper (postgres.ts)
    Dockerfile
e2e/                   Playwright browser tests (real DOM)
  tests/app.spec.ts    setup + recovery, sign-in, My Day, History, backup, invites
  server.ts            API + apps/web/dist on one origin (throwaway stack)
  global-setup.ts      builds the client, boots the stack
  README.md            how the harness works / selectors
  playwright.config.ts
tool/check.sh          one-command feedback loop (api | web | e2e)
docker/
  proxy/nginx.conf     front door (web + /api)
  backup/              pg_dump cron container
docker-compose.yaml
.env.example           compose configuration template
.github/workflows/     CI: api, web, e2e jobs
```

---

## API Surface (`/api/v1`, JSON, cookie session or `Authorization: Bearer`)

User-data routes are implicitly scoped to the authenticated user.

| Method & path | Purpose |
|---|---|
| `GET /state` | `{ has_users }` — public; drives first-run admin setup |
| `POST /auth/setup` | create the first admin (only while no users exist) |
| `POST /auth/register` | register with an email-bound invite token |
| `POST /auth/login` | email + password → `{ token, user }` + session cookie |
| `POST /auth/logout` | revoke the session and clear the cookie |
| `GET /me` · `PATCH /me` | profile read / update |
| `PATCH /me/password` | change own password (current required) |
| `POST /invites/validate` | validate an invite token (public) |
| `GET/PATCH/DELETE /admin/users/:id`, `GET /admin/users` | admin user management |
| `GET/POST/DELETE /admin/invites[/:id]` | admin invite management |
| `GET/POST/PATCH/DELETE /time-logs[/:id]` (`?date=`) | encrypted time-log CRUD |
| `GET/POST/PATCH/DELETE /travel-presets[/:id]` | encrypted preset CRUD |
| `GET/PATCH /settings` | the single settings row (envelope + encrypted payload) |
| `GET /export` · `POST /import` | full portable backup bundle |
| `POST /sl/proxy` | SL Journey Planner proxy (`{ path }`), slimmed |
| `GET /events` | SSE stream of `{ table, type, row }` (cookie; `?token=` for bearer) |
| `GET /api/health` | container health check |

Errors are `{ "error": { "code", "message" } }` with an HTTP status. A
Postgres unique violation maps to 409.

---

## Authentication & Multi-User

ChronoWarden uses invite-only registration with local accounts. Admins manage
users but cannot read their data — each user operates on an isolated "island".
See [`docs/AUTH.md`](docs/AUTH.md) for the full reference.

### Roles & statuses (`users` table)

| Role | Status | Meaning |
|------|--------|---------|
| `admin` | `approved` | Manage users/invites. Sees only own data. |
| `user` | `approved` | Regular user (invite registration is auto-approved). |
| `user` | `pending` | Exists but not approved (reserved). |
| `user` | `rejected` | Disabled; login is refused. |

### First admin (empty database)

1. The client calls `GET /state`; `has_users == false` shows "First-time setup".
2. `POST /auth/setup` creates the account as `admin` / `approved`, returns a
   session token **and** sets the `cw_session` cookie.

### Regular users (invite-only)

1. An admin creates an invite (`POST /admin/invites`) for a specific email.
   Only the SHA-256 hash is stored; the raw token is returned **once**.
2. The user enters the token at signup; `POST /invites/validate` confirms it and
   returns the bound email (the client prefills it).
3. `POST /auth/register` creates the account with the invite's role and marks the
   invite used. Invites are single-use and expire (default 14 days, max 90).

### Credentials & sessions

- Passwords are hashed with **argon2id** (`Bun.password`, 19 MiB / 2
  iterations). Minimum length 10 characters.
- Sessions are opaque 256-bit tokens. Only their SHA-256 hash is stored, in
  `sessions`. The TTL is sliding (`SESSION_TTL_DAYS`, default 30).
- **Transport:** the React client uses an httpOnly `cw_session` cookie
  (SameSite=Lax, Secure in production). The legacy bearer token is still
  returned in the login response and accepted by `requireAuth`, so CLI/API
  tooling works. `GET /events` accepts the cookie or `?token=`.

### Password resets (no email)

Password resets are admin-assisted: an admin issues a new temporary password
out-of-band. The **encryption passphrase is separate and never changes**; data
recovery uses the recovery phrase.

---

## Encryption Architecture

ChronoWarden uses **envelope encryption** (zero-knowledge) to protect user
data. The server is blind to everything except ciphertext and envelope metadata.

### Key hierarchy

```
Passphrase → PBKDF2(310k) → Master Key (KEK)
  └─ AES-GCM wrap ──→ Data Encryption Key (DEK)
                        └─ AES-GCM encrypt ──→ Encrypted data
```

### What's encrypted

- All `time_logs` rows → `encrypted_data` (AES-256-GCM)
- All `travel_presets` rows → `encrypted_data` (name stays plaintext)
- `user_settings` → `encrypted_data` (work config, flex, language, transit, prefs)
- `user_settings` envelope columns: `encrypted_dek`, `kek_salt`,
  `kek_iterations`, `recovery_hash`

### What stays plaintext

- `user_id` (ownership scoping), `date` (server-side filtering), row
  `id`/`created_at`, the preset `name` (dropdowns)

### Key files

| File | Purpose |
|------|---------|
| `apps/web/src/lib/crypto.ts` | PBKDF2, AES-256-GCM, key wrap, BIP39 mnemonic, base64 |
| `apps/web/src/state/auth.ts` | session + DEK lifecycle, passphrase unlock, envelope detection |
| `apps/web/src/lib/domain/` | pure domain logic (work config, time log, CSV, transit, alerts) |
| `apps/web/src/services/settings.ts` | encrypted settings read/write |
| `apps/web/src/services/time-logs.ts` | encrypted time-log CRUD |
| `apps/web/src/components/BackupCard.tsx` | export / restore bundle |

### Crypto interoperability

The client is a **byte-for-byte port** of the original client's crypto
implementation and is verified against golden fixtures generated by it:

- **KEK:** PBKDF2-HMAC-SHA256, 310 000 iterations, 32-byte key (WebCrypto).
- **Wrap/encrypt:** AES-256-GCM, 12-byte nonce, 16-byte tag, stored as
  `base64(nonce ‖ ciphertext ‖ tag)`.
- **Recovery hash:** `base64(SHA-256(utf8(phrase)))`.
- **Recovery phrase:** official **BIP39** (`@scure/bip39`). The DEK is unchanged;
  each unlock/show re-derives the phrase and rewrites `recovery_hash` (the
  one-time migration from the old custom wordlist).
- Fixtures: `apps/web/src/lib/__fixtures__/crypto-golden.json`
  (generator lives in the git history; the fixtures are committed).

### Critical warning (displayed in UI)

> If you lose both your encryption passphrase AND your recovery phrase,
> your data is gone forever. No one — not even the app administrator —
> can recover it.

---

## Configuration & Environment

Secrets are loaded by Docker Compose from a single, gitignored `.env`.
Template: `.env.example`.

`.env` keys:

| Key | Purpose |
|-----|---------|
| `POSTGRES_USER` / `POSTGRES_PASSWORD` / `POSTGRES_DB` | database credentials |
| `DATA_DIR` | host dir for the Postgres volume (default `./data`) |
| `SESSION_TTL_DAYS` | session lifetime in days (default 30) |
| `SL_API_KEY` | optional Journey Planner API key |
| `WEB_PORT` | host port for the front door (default 8981) |
| `CRON_SCHEDULE` / `RETENTION_DAYS` / `BACKUP_VOLUME` | backup tuning |
| `CORS_ORIGIN` | optional; only needed for local `npm run dev` on a different origin |

The client needs no secrets: it calls `/api/v1` on the same origin. The Vite dev
server proxies `/api` to the API.

### Database access (AI agent tooling)

Credentials live in `.env` (`POSTGRES_USER` / `POSTGRES_PASSWORD` /
`POSTGRES_DB`). Run SQL through the container:

```bash
docker compose exec db psql -U "$POSTGRES_USER" -d "$POSTGRES_DB"
```

The database port is not published on the host. Always pass the password via
`PGPASSWORD` (or the compose environment) rather than inlining it.

---

## Docker & Deployment

`docker-compose.yaml` (symlinked from
`/opt/appdata/chronowarden/docker-compose.yaml` → `src/docker-compose.yaml`)
runs:

- `db` — `postgres:18-alpine`, `PGDATA=/var/lib/postgresql/data/pgdata`,
  volume `${DATA_DIR:-./data}/postgres`, healthcheck via `pg_isready`.
- `api` — builds `./src/apps/api`; `DATABASE_URL` points at `db`; runs
  migrations on startup; port 8080 (internal).
- `web` — builds `./src/apps/web` (Node 26 → nginx static build).
- `proxy` — `nginx:alpine` front door on `${WEB_PORT:-8981}:80`; routes
  `/api/` → `api:8080` (SSE-safe: buffering off) and `/` → `web:80`.
- `backup` — builds `./src/docker/backup`; daily `pg_dump`.

Run:

```bash
cp .env.example .env        # fill in a strong POSTGRES_PASSWORD
docker compose up --build -d
```

### Local development

```bash
# API (needs a local Postgres)
cd apps/api && bun install
DATABASE_URL=postgres://postgres@localhost:5432/chronowarden bun run src/index.ts

# Client (proxies /api to the API; requires Node 26 LTS)
cd apps/web
npm install
npm run dev            # http://localhost:5173
```

Set `CORS_ORIGIN` on the API only if you bypass the Vite proxy.

---

## Release to production

### Where it is hosted

| Detail | Value |
|--------|-------|
| **Server IP** | `192.168.1.50` |
| **SSH user** | `tobbe` (key auth) |
| **Repo path** | `/opt/appdata/chronowarden/src` |
| **Git remote** | `origin` → `github.com:taxx/chronowarden.git` |
| **Branch** | `main` |
| **Front door** | the `proxy` container on `${WEB_PORT}` (host HAProxy does TLS) |

### Environments (during the self-hosting migration)

| Environment | URL | Port | Host path | Branch |
|---|---|---|---|---|
| Production | https://chronowarden.slumpen.com | 8981 | `/opt/appdata/chronowarden` | `main` |
| Beta (React client) | https://chronowarden-beta.slumpen.com | 8982 | `/opt/appdata/chronowarden-beta` | `feat/ui-rewrite` |
| Old (frozen Flutter instance) | https://chronowarden-old.slumpen.com | 8983 | `/opt/appdata/chronowarden-old` | `feat/selfhost` |

All three sit behind HAProxy and each has its own Compose project (derived from
the directory name, so containers/networks never collide). `chronowarden-old` is
a frozen copy of the self-hosted instance **with the real data** (a rollback
reference); `chronowarden-beta` runs the React client against an identical copy
of that data. Beta becomes production at cutover.

### Step 1 — commit and push

```bash
cd /path/to/chronowarden
git add -A
git commit -m "describe the change"
git push origin main
```

### Step 2 — SSH rebuild

The metadata is generated on the host **after** pulling, so the deployed
`version.json`/`CHANGELOG.md` match the exact revision.

```bash
ssh tobbe@192.168.1.50 "cd /opt/appdata/chronowarden/src && git pull && apps/web/tool/generate_metadata.sh && cd /opt/appdata/chronowarden && docker compose up --build -d"
```

### Step 3 — verify

```bash
ssh tobbe@192.168.1.50 "cd /opt/appdata/chronowarden && docker compose ps"
```

### Server directory layout

```
/opt/appdata/chronowarden/
├── .env                     # compose secrets (gitignored)
├── docker-compose.yaml      # symlink -> src/docker-compose.yaml
├── data/postgres/           # Postgres data volume
├── backup/                  # daily pg_dump archives
└── src/                     # the git repo
```

Relative paths in `docker-compose.yaml` resolve to `/opt/appdata/chronowarden`.

---

## Backup Job

A `backup` container runs `pg_dump` on a cron schedule, gzips each dump, and
prunes old ones.

| Detail | Value |
|--------|-------|
| **Image** | `postgres:18-alpine` (pg_dump version matches the server) |
| **Cron** | daily `0 2 * * *` (`CRON_SCHEDULE`) |
| **Retention** | `RETENTION_DAYS` (default 62) |
| **Host dir** | `/opt/appdata/chronowarden/backup` (`BACKUP_VOLUME`) |
| **Credentials** | the same `POSTGRES_*` from `.env`, exposed as `PG*` |
| **Format** | `pg_dump --format=tar --no-owner` → `gzip -9` |

Files: `docker/backup/{Dockerfile,backup.sh,entrypoint.sh}`. Logs:
`docker compose logs backup`.

---

## Backup & Restore (data portability)

Users can move all their data between instances:
**Settings → Backup & Restore**.

- `GET /export` returns a JSON bundle:
  `{ format, version, exported_at, user, envelope, settings, time_logs,
  travel_presets }` where the envelope carries `encrypted_dek`, `kek_salt`,
  `kek_iterations`, `recovery_hash`, and every row is ciphertext.
- `POST /import` replaces the account's envelope + rows atomically.
- The **envelope must travel with the data**: the DEK is random, so a fresh
  signup on the target instance would otherwise derive a different key. After
  restore the client drops the in-memory DEK and prompts for the *backup's*
  passphrase (`AuthStore.onBackupRestored()` → unlock screen).
- CSV export/import (time logs only) remains for spreadsheet workflows.

---

## Cross-Device Realtime Sync

The API publishes changes over Server-Sent Events; there is no third-party
realtime service.

### How it works

1. `RealtimeBridge` (`apps/web/src/components/RealtimeBridge.tsx`) opens
   `GET /api/v1/events` via `EventSource`; the httpOnly cookie authenticates it.
2. On any `time_logs` write the API publishes `{ table, type, row }` to that
   user's open streams (`apps/api/src/events.ts`).
3. The bridge invalidates the time-log queries, so My Day, Overview and History
   refresh without a page reload.
4. The stream is closed on sign out (the shell unmounts).

The hub is in-process, so it assumes a single API container. `EventSource`
reconnects automatically.

---

## Reduced-week (Seasonal) Work Config

ChronoWarden picks between default and reduced expected minutes per day using
ISO week numbers (`reduced_start_week` / `reduced_end_week` →
`reduced_expected_minutes`).

- **ISO weeks** start Monday (Sweden).
- **DST-safe** — `isoWeekNumber()` in `apps/web/src/lib/domain/work-config.ts`
  works on UTC; wall-clock arithmetic truncated by one day around DST and skewed
  the week number.
- **Week transparency** — the Overview week/month headers show the ISO week and
  the month grid has a week-number gutter.

---

## Real-Time Transit Integration (SL Journey Planner)

```
React client
  └─ POST /sl/proxy { path }
       └─ API route (Bun) — slims the ~220 KB /v2/trips response to ~2 KB
            └─ fetch('https://journeyplanner.integration.sl.se/v2/...')
                 └─ Slimmed JSON (departure/arrival, legs with line, platform,
                     occupancy, delay) back to the client
```

### Why slimming (and why the proxy stays)

The proxy is the API itself: being same-origin removes the CORS reason, but the
server also holds an optional `SL_API_KEY`, caches identical queries for 30 s,
and only allows `/v2/` paths.

### Smart direction & walk offset

- Morning (before 11:00): home → work; otherwise work → home.
- The query time is offset by the walking time so returned journeys depart after
  the user has walked to the station.

### Station autocomplete

`/v2/stop-finder`, 300 ms debounce (`StationPicker`), returning Journey Planner
global IDs (e.g. `9091001001009638`).

### Failure back-off & rate limiting

The app must never hammer SL:

- **`TransitFetchGuard`** (`apps/web/src/lib/domain/transit-guard.ts`) — pure,
  clock-injected retry policy: exponential back-off with equal jitter (base 15 s
  → cap 15 min), honouring `Retry-After`. A non-retryable status (400/401/403)
  or `maxFailures` consecutive failures gives up until an explicit retry.
- **`apps/web/src/services/transit.ts`** checks the guard before the network,
  coalesces in-flight requests, caches for 60 s, and returns stale data while
  backing off (never rejects).
- **UI:** the Transit page shows a retry countdown or the give-up message plus
  **Try again**.
- **Server hardening:** the API caches paths for 30 s; the client back-off is the
  real protection.

### Pinned (committed) journey

The SL API returns at most 3 trips; a committed train can slide out of the
window. Pinning keeps it visible.

- **Matching** by scheduled departure time-of-day + line (delays don't unpin it).
- **Storage** in `localStorage` (per-device, not encrypted).
- **Auto-expire** the next day; cleared when the route (stations) changes.
- **Behaviour:** pinned card at the top with a Pinned badge; live data when
  present, otherwise a synthetic card.

Files: `apps/web/src/lib/domain/pinned-journey.ts`,
`apps/web/src/services/pinned-journey-store.ts`, `apps/web/src/screens/TransitPage.tsx`.

---

## LocalStorage DEK Cache

The DEK is cached so it survives closing/reopening the tab.

- Write/read/clear: `apps/web/src/state/auth.ts` (`cw_dek`).
- Cleared on logout and when a backup is restored.

---

## Leave-time notifications

While a day is active the client watches the projected leave time and alerts
when close to leaving, then again if overrunning.

### Two phases

- **Wrap-up** — once `remaining <= threshold` (default 30 min).
- **Overtime** — up to 60 min past leave.

### Snooze & dismiss

- Snooze (default 10 min, 1–60) re-arms the alert.
- Dismiss suppresses alerts for the rest of the day.
- State and settings persist to `localStorage`.

### Delivery

1. In-app banner (`AlertBanner`, rendered by the app shell).
2. OS notification (Notification API, when granted).
3. Beep (Web Audio) + vibration.

### Robustness

- Timing decisions live in the pure `evaluateLeaveAlert()`
  (`apps/web/src/lib/domain/leave-alert.ts`, unit-tested).
- The projected leave time accounts for a break that is still running.

Key files: `apps/web/src/state/notifications.ts`,
`apps/web/src/components/AlertBanner.tsx`,
`apps/web/src/components/NotificationSettingsCard.tsx`,
`apps/web/src/lib/notify.ts`, `apps/web/src/screens/MyDayPage.tsx`.

---

## Changelog / What's New

```
apps/web/tool/generate_metadata.sh → apps/web/public/CHANGELOG.md (generated)
   → fetchChangelog() → parseChangelog() → ChangelogScreen
```

- Runs `git log --no-merges` (newest first, grouped by date), default last 300
  commits, and also writes `public/version.json`.

---

## Version Check / Update Prompt

```
apps/web/tool/generate_metadata.sh → apps/web/public/version.json
   → served at /version.json; the bundle's commit comes from __BUILD_COMMIT__
        ↓
UpdateBanner polls /version.json → offers "Reload" when the commits differ
```

- Polls every 5 minutes and when the tab becomes visible.
- Prompts only when both commits are known (not `dev`) and differ.
- **Dismiss** records the server commit; reappears for the next deploy.

Key files: `apps/web/src/components/UpdateBanner.tsx`,
`apps/web/src/lib/download.ts`, `apps/web/tool/generate_metadata.sh`.

---

## Localization (i18n)

English (source) and Swedish. Chosen in **Settings → Language**, persisted
locally and mirrored to encrypted settings.

```tsx
const t = useT();
t('Leave time')
t('Snooze {minutes}m', { minutes: 10 })
```

- `apps/web/src/i18n/index.ts` — `translate()`, the `svCatalog`, and the `useT()`
  hook. Falls back to English for unknown keys.
- `apps/web/src/services/locale_service` equivalents live in the locale store /
  settings.

### Guard test

`apps/web/src/i18n/i18n.test.ts` scans `src/` for `t('…')` literals and fails on
missing **or unused** entries. Pass literals directly to `t(...)` — a dynamic
key (`t(variable)`) is invisible to the guard and will fail as unused.

---

## Testing & CI

- **`tool/check.sh`** is the feedback loop: API typecheck + unit + integration,
  then web typecheck + tests + build. Sub-targets: `tool/check.sh api|web|e2e`.
- **API unit tests** live in `apps/api/test/unit`; **integration tests** in
  `apps/api/test/integration`. The latter start a throwaway Postgres (via
  `test/helpers/postgres.ts`) or use `TEST_DATABASE_URL`, run the real
  migrations, and drive the real Hono app in-process: bootstrap/auth, invites,
  admin ops, cross-user isolation, CRUD, export/import, SSE, cookie sessions and
  a pg_dump round-trip.
- **Web tests** live in `apps/web/src` (Vitest): domain logic, crypto (golden
  fixtures), API client, encrypted services, components and the i18n guard.
- **Browser E2E** (`e2e/`, Playwright) builds the client, starts a real API +
  throwaway Postgres, and drives it through the DOM: setup + recovery phrase,
  sign-in, My Day, History, backup download, invites and recovery. Run with
  `tool/check.sh e2e`.
- **CI** (`.github/workflows/ci.yml`) runs all three on push/PR.
