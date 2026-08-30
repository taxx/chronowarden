# Agent Context: ChronoWarden Coding Harness

You are an expert Flutter & Dart developer acting as a dedicated pair-programmer for "ChronoWarden", a personal time-tracking and overtime protection app.

## Core Directives
1. **KISS Principle:** Prioritize clean, minimal, readable, and highly maintainable code. Avoid over-engineering, unnecessary abstractions, or redundant boilerplate.
2. **State Management:** Use Flutter's native `ChangeNotifier` or simple state-lifting. Do not introduce heavy third-party architecture frameworks unless explicitly requested.
3. **Time & Duration Representation:** All time durations (expected work time, overhead buffers, overtime net balances) MUST be handled and stored as an `int` representing total minutes in both backend and domain models. Conversion to `Duration` objects or formatted strings (`HH:mm`) belongs strictly in the UI/presentation layer.
4. **Data Privacy & Isolation:** Ensure all models strictly retain a `user_id` field to align properly with Supabase Row Level Security (RLS). All data queries MUST scope to the current authenticated user.
5. **Validation:** Use `flutter analyze` to make sure there are no warnings or errors.
6. **Tests:** Use tests and mocks where applicable to ensure you don't break things and make sure new features works as expected.

## Authentication & Multi-User
ChronoWarden uses Supabase Auth with an admin-invite model. Key points:
- **Auth state** lives in `AuthService` (singleton `ChangeNotifier`). Always check `AuthService().isAuthenticated` and `AuthService().profile` before making data requests.
- **User scoping** — all data services (`TimeLogService`, `WorkPeriodService`, `TravelPresetService`) scope queries to the current session's `user_id`. They return empty/null when not authenticated.
- **RLS helper functions** — `is_admin()` and `has_profiles()` are `SECURITY DEFINER` RPC functions that bypass RLS. Use them when you need to check admin status or database state from unauthenticated contexts.
- **Email is stored in `profiles`** — PostgREST cannot join the `auth` schema, so email is mirrored from `auth.users` via the `handle_new_user` trigger.
- **Profile auto-creation** — `AuthService._ensureProfile()` uses `upsert` to handle cases where the DB trigger didn't fire (e.g., user signed up before tables existed).

See `AUTH.md` for the full architecture reference.

## Configuration & Environment
API Secrets are loaded securely via `--dart-define-from-file=secrets.json`.
Access credentials safely in Dart code using:
```dart
const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
```
These values are **compile-time constants** — changing secrets requires a full rebuild.

### Database Access (AI Agent Tooling)
For database operations (SQL migrations, backups, verification), credentials live in `.env.db`:
```
.env.db          — real credentials (gitignored)
.env.db.sample   — template without secrets
```

The AI agent reads `.env.db` for `pg_dump`, `psql`, and `pg_restore` commands.
Always use `PGPASSWORD` environment variable rather than inlining the password:
```bash
PGPASSWORD="$DB_PASSWORD" psql --dbname="$DB_CONNECTION_STRING" -c "SELECT ..."
```

### Edge Function Access (AI Agent Tooling)
For Supabase Edge Function deployment, credentials live in `.env.edge`:
```
.env.edge          — real credentials (gitignored)
.env.edge.sample   — template without secrets
```

The AI agent reads `.env.edge` for `supabase functions deploy` commands.
Always use `SUPABASE_ACCESS_TOKEN` environment variable rather than
inlining the token:
```bash
SUPABASE_ACCESS_TOKEN="$SUPABASE_ACCESS_TOKEN" supabase functions deploy sl-proxy
```

### Docker & Deployment
The project includes a multi-stage Dockerfile + docker-compose.yaml for containerized deployment:
- **Stage 1**: Flutter SDK builds the web release with secrets injected via `docker build --build-arg`. A temporary `secrets.json` is generated from the env vars, used for the build, then immediately deleted.
- **Stage 2**: Slim nginx:alpine serves the static `build/web/` output with gzip and SPA routing.
- **Secrets flow**: `.env` → `docker compose` build args → compiled JS. `.env` is gitignored; `.env.example` shows required keys.
- **Running**: `docker compose up --build` exposes the app on port `8080`.

## Release to production
### 1a. Where It Is Hosted

| Detail | Value |
|--------|-------|
| **Server IP** | `192.168.1.50` |
| **SSH user** | `tobbe` (SSH key auth, no password) |
| **Repo path** | `/opt/appdata/chronowarden` |
| **Git remote** | `origin` → `github.com:taxx/chronowarden.git` |
| **Branch** | `main` |
| **App URL** | `https://chronowarden.slumpen.com/` |

---

### 1b. How to Update the App

Whenever source code is changed locally, follow these steps to deploy to the server:

#### Step 1 — Commit and push locally

```bash
cd /path/to/chronowarden
git add -A
git commit -m "describe the change"
git push origin main
```

#### Step 2 — SSH into the server and rebuild

```bash
ssh tobbe@192.168.1.50 "cd /opt/appdata/chronowarden && git pull && docker compose up --build -d"
```

This does three things:
1. **`git pull`** — Fetches the latest code from GitHub
2. **`docker compose up --build`** — Rebuilds any images whose Dockerfile or dependencies changed, then (re)starts all containers
3. **`-d`** — Runs in detached mode

#### Step 3 — Verify the deployment

```bash
# Check all containers are running
ssh tobbe@192.168.1.50 "cd /opt/appdata/chronowarden && docker compose ps"
```

---

## Database Operations

### Backup (before destructive changes)

```bash
cd /path/to/chronowarden
source .env.db
pg_dump \
  --dbname="$DB_CONNECTION_STRING" \
  --format=tar \
  --file=chronowarden_backup_$(date +%Y-%m-%d).tar \
  --no-owner
```

Backup files are gitignored (`chronowarden_backup_*.tar`).

### Restore

```bash
cd /path/to/chronowarden
source .env.db
pg_restore \
  --dbname="$DB_CONNECTION_STRING" \
  --format=tar \
  chronowarden_backup_2026-08-26.tar
```

### Run SQL migration

```bash
cd /path/to/chronowarden
source .env.db
PGPASSWORD="$DB_PASSWORD" psql --dbname="$DB_CONNECTION_STRING" -f migration_name.sql
```

### Verify data

```bash
cd /path/to/chronowarden
source .env.db
PGPASSWORD="$DB_PASSWORD" psql --dbname="$DB_CONNECTION_STRING" -c "\dt"
```

---

## Encryption Architecture

ChronoWarden uses **envelope encryption** (zero-knowledge) to protect user data.

### Key hierarchy
```
Passphrase → PBKDF2(310k) → Master Key (KEK)
  └─ AES-GCM wrap ──→ Data Encryption Key (DEK)
                        └─ AES-GCM encrypt ──→ Encrypted data
```

### What's encrypted
- All `time_logs` rows → `encrypted_data` column (AES-256-GCM)
- All `travel_presets` rows → `encrypted_data` column
- `user_settings` → `encrypted_data` column (work config + flex minutes)

### What stays plaintext
- `user_id` (for RLS scoping)
- `date` (for server-side filtering: `WHERE date = today`)
- `name` on travel presets (for dropdown display)
- Envelope metadata: `encrypted_dek`, `kek_salt`, `kek_iterations`, `recovery_hash`

### Key files
| File | Purpose |
|------|---------|
| `lib/services/crypto_service.dart` | PBKDF2, AES-256-GCM, key wrap, BIP39 mnemonic, sessionStorage |
| `lib/services/auth_service.dart` | DEK lifecycle, passphrase unlock, migration detection |
| `lib/services/migration_service.dart` | One-time encryption of legacy plaintext data |
| `lib/screens/migration_screen.dart` | Migration UI with passphrase setup + recovery display |
| `lib/screens/about_encryption_screen.dart` | Full encryption explainer with key hierarchy diagram |
| `lib/screens/passphrase_screen.dart` | Passphrase entry on new devices |

### Recovery phrase
- 24-word BIP39-style mnemonic encodes the DEK directly
- SHA-256 hash stored in `user_settings.recovery_hash` for verification
- Shown once during migration or signup; accessible from Settings → Encryption

### Critical warning (displayed in UI)
> If you lose both your encryption passphrase AND your recovery phrase,
> your data is gone forever. No one — not even the app administrator —
> can recover it.

---

## Legacy column cleanup

After all users migrated, legacy plaintext columns were dropped:
- `time_logs`: `start_time`, `end_time`, `expected_minutes`, `lunch_minutes`, etc.
- `travel_presets`: `default_overhead_minutes`, `morning_overhead_minutes`, etc.
- `user_settings`: `default_flex_minutes`, `default_expected_minutes`, etc.

All data now lives exclusively in `encrypted_data` columns. The app never
reads from legacy columns. See `LEGACY_COLUMN_CLEANUP.md` for the full plan.

---

## Cross-Device Realtime Sync

ChronoWarden uses Supabase Realtime to sync time log changes across devices
without requiring page reloads.

### How it works
1. `AppState` subscribes to `postgres_changes` on `time_logs` filtered by `user_id`
2. When any device starts/stops/edits a day, the subscription fires
3. `AppState` re-fetches `todayLog` if the changed row matches today's date
4. The time bank balance is always refreshed

### Setup
- `time_logs` must be in the `supabase_realtime` publication
- Run `migration_enable_realtime.sql` if needed:
  ```sql
  ALTER PUBLICATION supabase_realtime ADD TABLE time_logs;
  ```
- Subscription is created in `AppState._subscribeRealtime()`
- Subscription is cleaned up on sign out via `AppState.onSignOut()`

### Key files
| File | Purpose |
|------|---------|
| `lib/app_state.dart` | `_subscribeRealtime()`, `_onRealtimeEvent()`, `onSignOut()` |
| `migration_enable_realtime.sql` | Enable Realtime for time_logs table |

---

## Real-Time Transit Integration (SL Roslagsbanan)

ChronoWarden can show real-time Roslagsbanan departures from SL (Stockholm
Public Transport), matching the calculated leave time against actual trains.

### Architecture
```
Flutter Web
  └─ supabase.functions.invoke('sl-proxy', { path: '/v1/sites/9600/departures' })
       └─ Supabase Edge Function (Deno)
            └─ fetch('https://transport.integration.sl.se/v1/sites/9600/departures')
                 └─ Response + CORS headers back to Flutter
```

### Why a proxy?
SL Transport API doesn't set CORS headers, so Flutter Web can't call it
directly. The `sl-proxy` Edge Function adds proper CORS headers and
forwards the response. All requests go through Supabase.

### Smart direction logic
The Transit tab automatically switches direction based on time of day:
- **Morning (before 11:00)**: departures from HOME → WORK
  (fetches from home station, filters for work)
- **Afternoon (11:00+)**: departures from WORK → HOME
  (fetches from work station, filters for home)

### Station autocomplete
Uses SL Site API (`/v1/sites`) to let users search stations by name.
The full site list is fetched once and cached in memory for 24h.
Client-side filtering — no network calls per keystroke.

### Transit config storage
Stored as encrypted JSON inside `user_settings.encrypted_data` under
key `transit_config`. Zero-knowledge like all encrypted data.
Fields:
- `enabled` — toggle to show/hide Transit tab
- `departure_site_id` / `departure_site_name` — work station
- `destination_site_id` / `destination_site_name` — home station
- `walk_minutes_to_station` / `walk_minutes_from_station` — walking buffers

### Transit tab visibility
The Transit navigation destination only appears in the bottom nav bar
when `enabled` is true in settings. Disabled users never see it.

### Key files
| File | Purpose |
|------|---------|
| `lib/models/transit_config.dart` | TransitConfig model (encrypted settings) |
| `lib/models/departure_info.dart` | SL departure API response model |
| `lib/models/station_info.dart` | SL site API response model |
| `lib/services/transit_service.dart` | Config CRUD + SL API fetcher + caching |
| `lib/widgets/station_picker.dart` | Reusable autocomplete widget |
| `lib/screens/transit_screen.dart` | Transit tab UI with smart direction |
| `lib/screens/settings_screen.dart` | Transit config card (Work/Home pickers) |
| `lib/screens/main_shell.dart` | Conditional Transit nav item |
| `supabase/functions/sl-proxy/index.ts` | Edge Function: CORS proxy for SL API |

### Edge Function credentials (`.env.edge`)
Credentials for Supabase Edge Function deployment live in `.env.edge`
(gitignored). Template at `.env.edge.sample`:
```
SUPABASE_ACCESS_TOKEN="sbp_..."
SUPABASE_PROJECT_REF="cnzzzgqgmyhjwpzszucj"
```

The AI agent reads `.env.edge` for `supabase functions deploy` commands.
Always use `SUPABASE_ACCESS_TOKEN` environment variable rather than
inlining the token:

### Deploying the Edge Function
The Supabase Edge Function `sl-proxy` must be deployed separately from
the Flutter app. It is NOT included in the Docker build.

**First time setup** (already done):
```bash
ssh tobbe@192.168.1.50 "curl -fsSL 'https://github.com/supabase/cli/releases/latest/download/supabase_cli_linux_amd64.tar.gz' -o /tmp/supabase.tar.gz && tar -xzf /tmp/supabase.tar.gz -C /tmp && sudo mv /tmp/supabase /usr/local/bin/supabase && sudo chmod +x /usr/local/bin/supabase && rm -f /tmp/supabase.tar.gz"
source .env.edge
SUPABASE_ACCESS_TOKEN="$SUPABASE_ACCESS_TOKEN" supabase link --project-ref "$SUPABASE_PROJECT_REF"
SUPABASE_ACCESS_TOKEN="$SUPABASE_ACCESS_TOKEN" supabase functions deploy sl-proxy
```

**Redeploy after changes** (when `supabase/functions/sl-proxy/index.ts` changes):
```bash
cd /path/to/chronowarden
source .env.edge
ssh tobbe@192.168.1.50 "cd /opt/appdata/chronowarden && SUPABASE_ACCESS_TOKEN='$SUPABASE_ACCESS_TOKEN' supabase functions deploy sl-proxy"
```

---

## LocalStorage DEK Cache

The Data Encryption Key (DEK) is cached in `localStorage` instead of
`sessionStorage` so it survives closing and reopening the browser tab.
The user only needs to enter their encryption passphrase once per browser.

- **Cache read**: `CryptoService.loadDekFromLocal()`
- **Cache write**: `CryptoService.cacheDekLocally()`
- **Cache clear**: `CryptoService.clearLocalCache()` (called on logout)
- **Missing DEK detection**: `AuthService.init()` checks for envelope and
  sets `needsPassphrase` / `needsMigration` if no cached DEK is found

---

## Slider Interval Setting

Users can configure the tick interval for lunch and flex time sliders
in **Settings → Slider step size**.

- **Default**: 5 minutes
- **Range**: 1–30 minutes
- **Storage**: `SharedPreferences` (local, not encrypted)
- **Helper**: `_sliderDivisions(min, max)` in `my_day_tab.dart` and
  `history_content.dart`

---

## iOS Safari Paste Compatibility

Flutter web on iOS Safari doesn't fire paste events to canvas-rendered
TextFields. A `PasteButton` widget provides an explicit paste button
that reads from the Flutter `Clipboard` API directly.

### Where paste buttons appear
| Screen | Fields |
|--------|--------|
| PassphraseScreen | Recovery phrase dialog |
| LoginScreen | Encryption passphrase |
| SignupScreen | Encryption passphrase + Confirm |

### Usage
```dart
TextField(
  controller: ctrl,
  decoration: InputDecoration(
    suffixIcon: PasteButton(controller: ctrl),
  ),
)
```
