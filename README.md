# ChronoWarden 🛡️⏱️

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![GitHub issues](https://img.shields.io/github/issues/taxx/chronowarden)](https://github.com/taxx/chronowarden)
[![GitHub stars](https://img.shields.io/github/stars/taxx/chronowarden)](https://github.com/taxx/chronowarden)

ChronoWarden is a personal time-banking and overtime protection system built with
**Flutter** (web/mobile) on top of a **Bun + Hono** API and **PostgreSQL**. Its
goal is to protect your personal time and prevent unintended, unpaid overtime by
calculating the exact moment you can stop working with a clear conscience.

It is **free and open-source software** (MIT), designed to be **100 %
self-hosted** — the entire stack lives in this repository and runs on your own
server via Docker Compose, with no third-party services.

| Resource | Link |
|----------|------|
| 📦 Source code | <https://github.com/taxx/chronowarden> |
| 🐛 Report an issue / request a feature | <https://github.com/taxx/chronowarden/issues> |
| 📖 Self-hosting guide | this file (see [Running it](#running-it)) |
| 🏗️ Architecture & deployment notes | [`AGENTS.md`](AGENTS.md) |
| 🔐 Encryption architecture | [`docs/ENCRYPTION.md`](docs/ENCRYPTION.md) |
| 👥 Auth architecture | [`AUTH.md`](AUTH.md) |
| ⚖️ License | [MIT](LICENSE) |

---

## Architecture & Tech Stack

| Layer | Technology |
|-------|-----------|
| **Client** | Flutter (Dart) web app — KISS, responsive |
| **API** | Bun + Hono (TypeScript): auth, encrypted CRUD, SSE, SL proxy |
| **Database** | PostgreSQL 18 |
| **Front door** | nginx `proxy` container: `/api/*` → API, `/*` → web |
| **Backups** | Daily `pg_dump` container with retention |
| **Security** | Client-side envelope encryption (zero-knowledge) + per-user API scoping |

```
                    host reverse proxy (TLS)
                              │
                    ┌─────────▼──────────┐
                    │  proxy (nginx)     │
                    │  /api/* → api      │
                    │  /*     → web      │
                    └───┬────────────┬───┘
                        │            │
                  ┌─────▼─────┐  ┌───▼────────────┐
                  │ web       │  │ api (Bun+Hono) │
                  │ Flutter   │  │ REST + SSE +SL │
                  └───────────┘  └───────┬────────┘
                                         │
                                   ┌─────▼──────┐   ┌────────┐
                                   │ postgres:18 │   │ backup │
                                   └────────────┘   └────────┘
```

Because the app and API share an origin, there is no CORS and no API URL baked
into the JS bundle. Cross-device sync uses **Server-Sent Events** published by
the API (all writes go through it), so no separate realtime service is needed.

## Two ways to run ChronoWarden

### 1. Self-host it (recommended)

Run the whole stack yourself — your own Postgres, your own web and API
containers, your own data and backups. Nobody else can shut it down. See
[Running it](#running-it).

### 2. Use the hosted instance (best effort)

The maintainer also runs a public instance at
<https://chronowarden.slumpen.com/>. It is a convenience, not an SLA:

- **No guarantees.** Availability, uptime, and retention are best-effort.
- **Your data is encrypted end-to-end** with your own passphrase, so the host
  cannot read it. If you lose your passphrase *and* recovery phrase, nobody can
  restore your data.
- **You can move your data at any time** with Settings → **Backup & Restore**
  (see [Backup & Restore](#backup--restore)).

---

## Multi-User & Auth

ChronoWarden supports multiple users with role-based access:

| Role | Capabilities |
|------|-------------|
| **Admin** | Manage users (approve/reject/delete), create invites, use own tracking |
| **User** | Full time-tracking access (own data only) |

- **First admin** is created when the app detects an empty database.
- **New users** register with an invite token issued by an admin. Invites are
  bound to an email address, single-use, and expire.
- **Data isolation** is enforced by the API, which scopes every query to the
  authenticated user. (There is no RLS — the database is only reachable by the
  API container.)
- **Passwords** are hashed with argon2id; sessions are revocable opaque tokens.
- There is **no email delivery**: invites are shared out-of-band, and password
  resets are admin-assisted.

See [`AUTH.md`](AUTH.md) for the full authentication architecture.

## Core Logic & Features

1. **Seasonal Work Periods:** Detects whether the day uses summer or winter
   hours from user-defined reduced-week ranges (ISO week numbers, Monday start).
   ISO weeks are computed with UTC arithmetic so DST never skews them. Week and
   Month headers show the ISO week(s), and the month grid is aligned to real
   weekday columns with a week-number gutter.
2. **Dynamic Travel Presets:** Commute scenarios (train, car, WFH, …) with their
   associated overhead minutes; presets can include productive commute time.
3. **Morning Calculator:**
   `Leave Time = Start Time + Expected Work Minutes + Overhead + Lunch + Non-work`
4. **Time Bank:** Flex balance derived by summing `overtime_minutes` across all
   recorded days.
5. **Bilingual UI (English / Swedish):** English is the source of truth; stored
   in encrypted settings so it follows you across devices.
6. **In-app changelog ("What's New"):** generated from the git commit history.
7. **Update prompt:** compares the running build's commit with the server's
   `/version.json` and offers a one-tap **Reload**.
8. **Leave-time notifications:** Alert shortly before and after your projected
   leave time via in-app banner, OS notification, and optional sound/vibration,
   with Snooze / Dismiss and a diagnostics panel.
9. **Non-work time (errands):** A second optional break type alongside lunch,
   toggleable in Settings (enabled by default).
10. **Flex withdrawal visualization:** Plan how much banked overtime to take as
    personal time today; the projected leave time moves earlier.
11. **Backup & Restore:** Download a complete, encrypted backup of all your data
    and restore it on any ChronoWarden instance.

---

## Running it

### Docker Compose (production / self-hosting)

Everything runs from `docker-compose.yaml`:

| Service | Role |
|---------|------|
| `proxy` | nginx front door on `${WEB_PORT:-8981}` — serves the app and proxies `/api` |
| `web` | Flutter web build served by nginx |
| `api` | Bun + Hono API; applies SQL migrations on startup |
| `db` | PostgreSQL 18 (not exposed on the host) |
| `backup` | daily `pg_dump` + retention |

```bash
# 1. Configure secrets
cp .env.example .env          # set a strong POSTGRES_PASSWORD
cp .env.db.sample .env.db     # same password + the db connection string

# 2. Build and start
docker compose up --build -d

# 3. Check
docker compose ps
```

The app is then available at `http://localhost:8981`. Point your host reverse
proxy (or HAProxy) at that port for TLS and a public hostname.

**Configuration** (`.env`):

| Key | Purpose |
|-----|---------|
| `POSTGRES_USER` / `POSTGRES_PASSWORD` / `POSTGRES_DB` | database credentials |
| `DATA_DIR` | host directory for the Postgres volume (default `./data`) |
| `SESSION_TTL_DAYS` | session lifetime in days (default 30, sliding) |
| `SL_API_KEY` | optional SL Journey Planner API key |
| `WEB_PORT` | host port for the front door (default 8981) |
| `CRON_SCHEDULE` / `RETENTION_DAYS` / `BACKUP_VOLUME` | backup tuning |
| `CORS_ORIGIN` | optional; only needed for local `flutter run` |

### Local development

```bash
# API — needs a reachable Postgres (any instance; migrations run on startup)
cd apps/api
bun install
DATABASE_URL=postgres://user:pass@localhost:5432/chronowarden bun run src/index.ts

# Client — point it at the API and allow that origin
cd apps/web
flutter run -d chrome --dart-define=API_URL=http://localhost:8080/api/v1
```

Run the API with `CORS_ORIGIN=http://localhost:<flutter-port>` so the browser can
call it cross-origin during development.

### Checks

```bash
flutter analyze && flutter test        # in apps/web
bunx tsc --noEmit && bun test          # in apps/api
```

### Generated metadata

| File | Generated by | Purpose |
|------|--------------|---------|
| `apps/web/CHANGELOG.md` | `apps/web/tool/generate_changelog.sh` | in-app "What's New" |
| `apps/web/build_info.json` | `apps/web/tool/generate_build_info.sh` | running build's version/commit |
| `apps/web/web/version.json` | `apps/web/tool/generate_build_info.sh` | server commit at `/version.json` |

Run both scripts before committing (they are part of the release routine).

---

## Encryption & Zero-Knowledge

ChronoWarden uses **envelope encryption** so the server (and its administrator)
cannot read user data. Each user has an encryption passphrase that unwraps a Data
Encryption Key (DEK) stored only in encrypted form.

### Key hierarchy

```
Passphrase → PBKDF2(310k) → Master Key (KEK)
  └─ AES-GCM wrap ──→ Data Encryption Key (DEK)
                        └─ AES-GCM encrypt ──→ Encrypted data
```

### What's encrypted

- `time_logs.encrypted_data` — every workday
- `travel_presets.encrypted_data` — every commute preset
- `user_settings.encrypted_data` — work config, flex, language, transit config

### What stays plaintext

- `user_id` (ownership), `date` (server-side filtering), row ids/timestamps, and
  the travel preset `name` (dropdown display)

### Recovery

A 24-word recovery phrase encodes the DEK directly; its hash is stored for
verification. If you lose **both** the passphrase and the recovery phrase, your
data is gone forever — not even the administrator can recover it. The full
explainer is in [`docs/ENCRYPTION.md`](docs/ENCRYPTION.md) and in-app under
Settings → Encryption.

---

## Backup & Restore

Move all your data between instances (for example, from the hosted instance to
your own self-hosted one) via **Settings → Backup & Restore**:

1. **Download backup** produces a JSON bundle containing the encryption envelope
   (`encrypted_dek`, `kek_salt`, `kek_iterations`, `recovery_hash`) together with
   the ciphertext rows.
2. **Restore backup** on the target instance replaces that account's data. The
   app then asks for the **backup's** encryption passphrase to unlock it.

The server only ever handles ciphertext. A CSV export/import for time logs is
also available for spreadsheet workflows.

## Database Backups

A `backup` container runs `pg_dump` on a cron schedule and prunes old archives:

- Daily at 02:00 (`CRON_SCHEDULE`), retained for `RETENTION_DAYS` (default 62).
- Archives land in the host directory `BACKUP_VOLUME`
  (`/opt/appdata/chronowarden/backup` on the reference server).
- Credentials come from `.env.db`.

```bash
docker compose logs backup                # see backup activity
ls -lh /opt/appdata/chronowarden/backup   # list archives
```

Restore:

```bash
source .env.db
pg_restore --dbname="$DB_CONNECTION_STRING" --format=tar chronowarden_backup_YYYYMMDD_HHMMSS.tar
```

---

## Real-Time Transit Integration (SL Journey Planner)

```
Flutter Web
  └─ ApiClient.post('/sl/proxy', { path })
       └─ API route — slims the ~220 KB /v2/trips response to ~2 KB
            └─ SL Journey Planner API
```

- **Smart direction:** before 11:00 home → work; after, work → home.
- **Walk-offset:** the query time is offset by your walking time so returned
  journeys are ones you can actually catch.
- **Station autocomplete** via `/v2/stop-finder` (300 ms debounce).
- **Failure back-off:** `TransitFetchGuard` uses exponential back-off with equal
  jitter (15 s → 15 min), honors `Retry-After`, and gives up until an explicit
  retry. The UI shows a countdown or the give-up message plus **Try again**.
- **Pinned journey:** lock the trip you committed to so it stays visible even
  when the API's 3-trip window slides past it.

Transit config is stored encrypted in `user_settings` and can be toggled off.

## Cross-Device Realtime Sync

- The API publishes `{ table, type, row }` over Server-Sent Events whenever one of
  your rows changes.
- The client subscribes at `GET /api/v1/events` (via `EventSource`) and re-fetches
  the affected data, so My Day, Overview and History stay in sync without a
  reload.
- The subscription is torn down on sign out.

## Slider Interval Setting

Configure the tick interval for lunch/flex sliders in **Settings → Slider step
size** (default 5 min, range 1–30; stored locally).

## iOS Safari Paste Compatibility

iOS Safari doesn't fire paste events to canvas-rendered TextFields, so a
`PasteButton` reads the Flutter `Clipboard` directly. It appears on the recovery
phrase dialog and the login/signup passphrase fields.

---

## Project Structure

```
apps/
├── web/                     Flutter web client
│   ├── lib/
│   │   ├── l10n/            AppStrings + Swedish catalog + context.t(...)
│   │   ├── models/          Domain models (TimeLog, TravelPreset, TransitConfig, …)
│   │   ├── services/        api_client, auth, realtime, backup, crypto, transit, …
│   │   ├── screens/         UI screens (thin — layout + wiring)
│   │   ├── widgets/         Reusable widgets
│   │   ├── utils/           csv, format, web bridges (browser/download/storage)
│   │   ├── app_state.dart   Central ChangeNotifier
│   │   └── main.dart        Auth gate & entry point
│   ├── test/                Flutter tests (incl. app_strings guard)
│   ├── tool/                generate_changelog.sh, generate_build_info.sh
│   ├── web/                 index.html, version.json, icons
│   └── Dockerfile
└── api/                     Bun + Hono API
    ├── src/
    │   ├── app.ts           Hono app + routes + error mapping
    │   ├── config.ts        env config
    │   ├── db.ts            postgres.js pool
    │   ├── migrate.ts       SQL migration runner
    │   ├── auth.ts          session middleware
    │   ├── password.ts      argon2id
    │   ├── tokens.ts        token generation/hashing
    │   ├── events.ts        SSE hub
    │   ├── sl.ts            SL fetch + slimming
    │   └── routes/          auth, admin, data, backup, sl, events
    ├── migrations/          numbered SQL (001_init.sql …)
    ├── test/                bun:test unit tests
    └── Dockerfile
docker/
├── proxy/nginx.conf         front door
└── backup/                  pg_dump cron container
docker-compose.yaml
```

---

## Contributing

Contributions are welcome — bug reports, feature ideas, docs, and pull requests.

- **Bugs / ideas:** open an issue at
  <https://github.com/taxx/chronowarden/issues> with steps to reproduce, expected
  vs. actual behaviour, and platform.
- **Before a PR:** run `flutter analyze && flutter test` (in `apps/web`) and
  `bunx tsc --noEmit && bun test` (in `apps/api`). Keep changes small and
  consistent with the KISS approach.
- **UI text is localized:** wrap new strings in `context.t('…')` and add the
  Swedish entry to `apps/web/lib/l10n/app_strings_sv.dart` in the same commit —
  `test/app_strings_test.dart` fails otherwise.
- **Regenerate metadata before committing:**
  ```bash
  apps/web/tool/generate_changelog.sh
  apps/web/tool/generate_build_info.sh
  ```

## License

ChronoWarden is released under the [MIT License](LICENSE).

Copyright © 2026 [taxx](https://github.com/taxx) and contributors.

You are free to use, copy, modify, merge, publish, distribute, sublicense, and/or
sell copies of the software, subject only to including the copyright notice and
license. The software is provided "as is", without warranty of any kind.
