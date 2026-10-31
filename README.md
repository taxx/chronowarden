# ChronoWarden 🛡️⏱️

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![GitHub issues](https://img.shields.io/github/issues/taxx/chronowarden)](https://github.com/taxx/chronowarden)
[![GitHub stars](https://img.shields.io/github/stars/taxx/chronowarden)](https://github.com/taxx/chronowarden)

ChronoWarden is a personal time-banking and overtime protection system built with
a **React + TypeScript** web client on top of a **Bun + Hono** API and
**PostgreSQL**. Its goal is to protect your personal time and prevent unintended,
unpaid overtime by calculating the exact moment you can stop working with a clear
conscience.

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
| 👥 Auth architecture | [`docs/AUTH.md`](docs/AUTH.md) |
| ⚖️ License | [MIT](LICENSE) |

---

## Architecture & Tech Stack

| Layer | Technology |
|-------|-----------|
| **Client** | React 19 + TypeScript + Vite, Tailwind CSS, TanStack Router/Query, installable PWA |
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
                  │ React     │  │ REST + SSE +SL │
                  └───────────┘  └───────┬────────┘
                                         │
                                   ┌─────▼──────┐   ┌────────┐
                                   │ postgres:18 │   │ backup │
                                   └────────────┘   └────────┘
```

Because the app and API share an origin, there is no CORS and no API URL baked
into the JS bundle. Cross-device sync uses **Server-Sent Events** published by
the API (all writes go through it), so no separate realtime service is needed.
The client is an installable PWA.

## Two ways to run ChronoWarden

### 1. Self-host it (recommended)

Run the whole stack yourself — your own Postgres, web and API containers, your
own data and backups. Nobody else can shut it down. See
[Running it](#running-it).

### 2. Use the hosted instance (best effort)

The maintainer also runs a public instance at
<https://chronowarden.slumpen.com/>. It is a convenience, not an SLA:

- **No guarantees.** Availability, uptime, and retention are best-effort.
- **Your data is encrypted end-to-end** with your own passphrase, so the host
  cannot read it. If you lose your passphrase *and* recovery phrase, nobody can
  restore your data.
- **You can move your data at any time** with Settings → **Backup & Restore**.

---

## Multi-User & Auth

| Role | Capabilities |
|------|-------------|
| **Admin** | Manage users (approve/reject/delete), create invites, use own tracking |
| **User** | Full time-tracking access (own data only) |

- **First admin** is created when the app detects an empty database.
- **New users** register with an invite token issued by an admin (bound to an
  email, single-use, expiring).
- **Data isolation** is enforced by the API, which scopes every query to the
  authenticated user (no RLS — the database is only reachable by the API).
- **Passwords** use argon2id; sessions are revocable opaque tokens delivered as
  an httpOnly cookie.
- There is **no email delivery**: invites are shared out-of-band, and password
  resets are admin-assisted.

See [`docs/AUTH.md`](docs/AUTH.md) for the full reference.

## Core Logic & Features

1. **Seasonal Work Periods:** summer/winter hours from reduced-week ranges (ISO
   week numbers, Monday start), computed DST-safely.
2. **Travel Presets:** commute scenarios with per-direction overhead and
   productive-commute minutes.
3. **Morning Calculator:**
   `Leave Time = Start + Expected Work + Overhead + Lunch + Non-work − Flex`
4. **Time Bank:** flex balance derived by summing `overtime_minutes`.
5. **Bilingual UI (English / Swedish)**, stored in encrypted settings.
6. **In-app changelog ("What's New")** generated from the git history.
7. **Update prompt** when a newer deployment is detected.
8. **Leave-time notifications** (banner, OS notification, sound, vibration,
   snooze/dismiss).
9. **Non-work time (errands)** and **flex withdrawal** planning.
10. **Backup & Restore** — download a complete encrypted backup and restore it
    on any ChronoWarden instance.
11. **Transit** — SL Journey Planner journeys, station autocomplete, pinned
    journeys and failure back-off.
12. **Installable PWA.**

---

## Running it

### Docker Compose (production / self-hosting)

| Service | Role |
|---------|------|
| `proxy` | nginx front door on `${WEB_PORT:-8981}` — serves the app and proxies `/api` |
| `web` | React build served by nginx |
| `api` | Bun + Hono API; applies SQL migrations on startup |
| `db` | PostgreSQL 18 (not exposed on the host) |
| `backup` | daily `pg_dump` + retention |

```bash
# 1. Configure secrets
cp .env.example .env          # set a strong POSTGRES_PASSWORD

# 2. Build and start
docker compose up --build -d

# 3. Check
docker compose ps
```

The app is then available at `http://localhost:8981`. Point your host reverse
proxy (or HAProxy) at that port for TLS and a public hostname.

### Local development

```bash
# API — needs a reachable Postgres (any instance; migrations run on startup)
cd apps/api
bun install
DATABASE_URL=postgres://user:pass@localhost:5432/chronowarden bun run src/index.ts

# Client — proxies /api to the API (requires Node 26 LTS, see apps/web/.nvmrc)
cd apps/web
npm install
npm run dev            # http://localhost:5173
```

### Tests

```bash
./tool/check.sh          # API typecheck/unit/integration + web typecheck/tests/build
./tool/check.sh api      # API only
./tool/check.sh web      # web only
./tool/check.sh e2e      # browser end-to-end (Playwright; builds the client)
```

- **API integration tests** start a throwaway Postgres and cover auth, invites,
  admin ops, cross-user isolation, CRUD, export/import, SSE, cookies and a
  `pg_dump` round-trip.
- **Browser E2E** (`e2e/`) drives the real client against a real API — see
  [`e2e/README.md`](e2e/README.md).
- CI (`.github/workflows/ci.yml`) runs all of the above on push and PRs.

### Generated metadata

| File | Generated by | Purpose |
|------|--------------|---------|
| `apps/web/public/CHANGELOG.md` | `apps/web/tool/generate_metadata.sh` | in-app "What's New" |
| `apps/web/public/version.json` | `apps/web/tool/generate_metadata.sh` | update prompt (`/version.json`) |

Run the generator before committing.

---

## Encryption & Zero-Knowledge

ChronoWarden uses **envelope encryption** so the server (and its administrator)
cannot read user data.

```
Passphrase → PBKDF2(310k) → Master Key (KEK)
  └─ AES-GCM wrap ──→ Data Encryption Key (DEK)
                        └─ AES-GCM encrypt ──→ Encrypted data
```

- Encrypted: all time logs, travel presets and settings payloads
  (including the work config, language and transit settings).
- Plaintext: `user_id` (ownership), `date` (filtering), row ids/timestamps and
  the preset `name`.
- **Recovery:** a 24-word BIP39 recovery phrase encodes the DEK. If you lose
  both the passphrase and the recovery phrase, your data is gone forever — not
  even the administrator can recover it. See
  [`docs/ENCRYPTION.md`](docs/ENCRYPTION.md).

## Backup & Restore

**Settings → Backup & Restore**:

1. **Download backup** produces a JSON bundle with the encryption envelope
   (`encrypted_dek`, `kek_salt`, `kek_iterations`, `recovery_hash`) and all
   ciphertext rows.
2. **Restore backup** on the target instance replaces that account's data, then
   asks for the **backup's** passphrase to unlock it.

A CSV export/import for time logs is also available in History.

## Database Backups

A `backup` container runs `pg_dump` daily at 02:00 (`CRON_SCHEDULE`) and prunes
archives older than `RETENTION_DAYS` (default 62). Credentials come from the same
`.env` (`POSTGRES_*`).

```bash
docker compose logs backup
source .env
gunzip -c backup/chronowarden_backup_YYYYMMDD_HHMMSS.tar.gz \
  | docker compose exec -T db pg_restore -U "$POSTGRES_USER" -d "$POSTGRES_DB" --format=tar
```

---

## Project Structure

```
apps/
├── web/                     React client
│   ├── src/
│   │   ├── api/             typed API client + endpoint modules
│   │   ├── lib/             crypto, format, date, download, notify + domain/
│   │   ├── queries/         TanStack Query hooks
│   │   ├── services/        encrypted data services
│   │   ├── screens/         route screens
│   │   ├── components/      UI kit + feature components
│   │   ├── state/           Zustand stores
│   │   ├── i18n/            t() + Swedish catalog + guard test
│   │   ├── router.tsx       TanStack Router with auth guards
│   │   └── main.tsx         entry point
│   ├── public/              icons, generated version.json + CHANGELOG.md
│   ├── tool/                generate_metadata.sh
│   └── Dockerfile
└── api/                     Bun + Hono API
    ├── src/                 app, config, db, migrate, auth, password, tokens, events, sl, routes/
    ├── migrations/          numbered SQL (001_init.sql …)
    ├── test/                unit + integration (throwaway Postgres)
    └── Dockerfile
e2e/                         Playwright browser tests
tool/check.sh                one-command feedback loop (api | web | e2e)
docker/
├── proxy/nginx.conf         front door
└── backup/                  pg_dump cron container
docker-compose.yaml
.github/workflows/ci.yml     CI: api, web, e2e
```

---

## Contributing

Contributions are welcome — bug reports, feature ideas, docs, and pull requests.

- **Bugs / ideas:** open an issue at
  <https://github.com/taxx/chronowarden/issues> with steps to reproduce,
  expected vs. actual behaviour, and browser/OS.
- **Before a PR:** run `./tool/check.sh` (API + web) and `./tool/check.sh e2e`
  (browser). Keep changes small and consistent with the KISS approach.
- **UI text is localized:** wrap new strings in `t('…')` and add the Swedish
  entry to `apps/web/src/i18n/index.ts` in the same commit —
  `src/i18n/i18n.test.ts` fails otherwise.
- **Regenerate metadata before committing:**
  ```bash
  apps/web/tool/generate_metadata.sh
  ```

## License

ChronoWarden is released under the [MIT License](LICENSE).

Copyright © 2026 [taxx](https://github.com/taxx) and contributors.

You are free to use, copy, modify, merge, publish, distribute, sublicense, and/or
sell copies of the software, subject only to including the copyright notice and
license. The software is provided "as is", without warranty of any kind.
