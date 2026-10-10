# Agent Context: ChronoWarden Coding Harness

You are an expert Flutter & Dart developer acting as a dedicated pair-programmer for "ChronoWarden", a personal time-tracking and overtime protection app.

## Core Directives
1. **KISS Principle:** Prioritize clean, minimal, readable, and highly maintainable code. Avoid over-engineering, unnecessary abstractions, or redundant boilerplate.
2. **State Management:** Use Flutter's native `ChangeNotifier` or simple state-lifting. Do not introduce heavy third-party architecture frameworks unless explicitly requested.
3. **Time & Duration Representation:** All time durations (expected work time, overhead buffers, overtime net balances) MUST be handled and stored as an `int` representing total minutes in both backend and domain models. Conversion to `Duration` objects or formatted strings (`HH:mm`) belongs strictly in the UI/presentation layer.
4. **Data Privacy & Isolation:** Ensure all models strictly retain a `user_id` field to align properly with Supabase Row Level Security (RLS). All data queries MUST scope to the current authenticated user.
5. **Validation:** Use `flutter analyze` to make sure there are no warnings or errors.
6. **Tests:** Use tests and mocks where applicable to ensure you don't break things and make sure new features works as expected.
7. **Deploy as part of the routine:** Every code change that is completed (fix or feature) MUST be deployed to production as part of the same working session, unless the user explicitly says not to. After committing and pushing, run the SSH rebuild + verification steps in the "Release to production" section below (git pull, docker compose up --build -d, docker compose ps). Do not stop after local changes — deploy and verify. Remember: the `sl-proxy` Edge Function is deployed separately from the Flutter app and is NOT part of the Docker build (see the Edge Function section).

## Authentication & Multi-User
ChronoWarden uses Supabase Auth with an admin-invite model. Key points:
- **Auth state** lives in `AuthService` (singleton `ChangeNotifier`). Always check `AuthService().isAuthenticated` and `AuthService().profile` before making data requests.
- **User scoping** — all data services (`TimeLogService`, `WorkConfigService`, `TravelPresetService`, `UserSettingsService`, `TransitService`) scope queries to the current session's `user_id`. They return empty/null when not authenticated.
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
| **Repo path** | `/opt/appdata/chronowarden/src` |
| **Git remote** | `origin` → `github.com:taxx/chronowarden.git` |
| **Branch** | `main` |
| **App URL** | `https://chronowarden.slumpen.com/` |

---

### 1b. How to Update the App

Whenever source code is changed locally, follow these steps to deploy to the server:

#### Step 1 — Regenerate metadata, then commit and push locally

The in-app changelog and version check are generated from the git history, so
refresh both before committing (see the "Changelog / What's New" and
"Version Check / Update Prompt" sections):

```bash
cd /path/to/chronowarden
tool/generate_changelog.sh
tool/generate_build_info.sh
git add -A
git commit -m "describe the change"
git push origin main
```

#### Step 2 — SSH into the server and rebuild

```bash
ssh tobbe@192.168.1.50 "cd /opt/appdata/chronowarden/src && git pull && cd /opt/appdata/chronowarden && docker compose up --build -d"
```

This does four things:
1. **`git pull`** — Fetches the latest code from GitHub into `src/`
2. **`cd /opt/appdata/chronowarden`** — Runs compose from the parent dir, where `.env` auto-loads and the `docker-compose.yaml` symlink lives
3. **`docker compose up --build`** — Rebuilds any images whose Dockerfile or dependencies changed, then (re)starts all containers
4. **`-d`** — Runs in detached mode

#### Step 3 — Verify the deployment

```bash
# Check all containers are running
ssh tobbe@192.168.1.50 "cd /opt/appdata/chronowarden && docker compose ps"
```

---

## Server directory layout

```
/opt/appdata/chronowarden/
├── .env                     # secrets (gitignored) — auto-loaded by compose
├── .env.db                  # DB credentials for the backup container (gitignored)
├── docker-compose.yaml      # symlink -> src/docker-compose.yaml
├── backup/                  # host dir where daily backups land (bind-mounted)
└── src/                     # the git repo (git pull happens here)
```

Relative paths in `docker-compose.yaml` resolve to the **parent** dir (the symlink's directory), so `build.context: ./src` points at the repo and `./backup` is the host backup dir.

---

## Backup Job

A dedicated `backup` container runs `pg_dump` on a cron schedule, gzips each dump, and prunes old ones.

| Detail | Value |
|--------|-------|
| **Image** | `alpine:3.20` + `postgresql-client` + busybox cron |
| **Cron schedule** | daily `0 2 * * *` (02:00), override via `CRON_SCHEDULE` |
| **Retention** | keep dumps newer than `RETENTION_DAYS` (default `62` ≈ 2 months) |
| **Host dir** | `/opt/appdata/chronowarden/backup` (override via `BACKUP_VOLUME`) |
| **Credentials** | `env_file: .env.db` at the parent dir (gitignored, never committed) |
| **Format** | `pg_dump --format=tar --no-owner`, then `gzip -9` → `chronowarden_backup_*.tar.gz` |

### Files
| File | Purpose |
|------|---------|
| `backup/Dockerfile` | Alpine image with pg client + cron |
| `backup/backup.sh` | pg_dump → gzip → retention cleanup |
| `backup/entrypoint.sh` | writes crontab from `CRON_SCHEDULE`, starts `crond` |
| `docker-compose.yaml` | `backup` service (env_file `.env.db`, `./backup` volume) |

### Troubleshooting
- Backup logs go to `docker compose logs backup`.
- If the container isn't running, check `.env.db` exists at `/opt/appdata/chronowarden/.env.db` (compose errors if the `env_file` is missing).

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
| `lib/screens/about_encryption_screen.dart` | Full encryption explainer with key hierarchy diagram (reusable `EncryptionInfoContent`) |
| `lib/screens/passphrase_screen.dart` | Passphrase entry on new devices |

### Recovery phrase
- 24-word BIP39-style mnemonic encodes the DEK directly
- SHA-256 hash stored in `user_settings.recovery_hash` for verification
- Shown once during migration or signup; accessible from Settings → Encryption

### Critical warning (displayed in UI)
> If you lose both your encryption passphrase AND your recovery phrase,
> your data is gone forever. No one — not even the app administrator —
> can recover it.

### Login/Signup encryption explainer
Login and Signup screens show a "How we store & protect your data" link below
the encrypted-data note. It opens a modal dialog reusing the same
`EncryptionInfoContent` widget as the full Settings page, so prospective or
new-device users can read the zero-knowledge architecture, key hierarchy,
recovery-phrase guidance, and the critical warning before signing in.

---

## Legacy column cleanup

After all users migrated, legacy plaintext columns were dropped:
- `time_logs`: `start_time`, `end_time`, `expected_minutes`, `lunch_minutes`, etc.
- `travel_presets`: `default_overhead_minutes`, `morning_overhead_minutes`, etc.
- `user_settings`: `default_flex_minutes`, `default_expected_minutes`, etc.

All data now lives exclusively in `encrypted_data` columns. The app never
reads from legacy columns. See `LEGACY_COLUMN_CLEANUP.md` for the full plan.

---

## Reduced-week (Seasonal) Work Config

ChronoWarden picks between default and reduced expected work minutes per day
using ISO week numbers. Users configure `reduced_start_week` / `reduced_end_week`
(e.g. weeks 20–37 for summer hours) and the app applies `reduced_expected_minutes`
when today's ISO week falls inside that range.

- **ISO week numbering** — weeks start on Monday (as in Sweden).
- **DST-safe calculation** — `isoWeekNumber()` in `lib/models/work_config.dart`
  performs all arithmetic on `DateTime.utc` dates. The original implementation
  used wall-clock `DateTime` + `Duration`, and Europe/Sweden's Daylight Saving
  Time transitions made `difference().inDays` truncate by one day for part of
  the year, skewing the week number by −1 (e.g. real ISO week 38 was reported
  as 37).
- **Week transparency** — the Week overview header shows the ISO week number
  (e.g. `Wk 38 · 14/9 — 20/9`) and the Month overview header shows the week
  range it covers (e.g. `Sep 2026 · Wk 36–40`). The month calendar also adds a
  per-row week-number gutter so each grid row maps directly to its ISO week.
- **Month calendar alignment** — the month grid is built over the full Mon–Sun
  week structure. The 1st of the month is placed under its real weekday (the
  leading days of the first row are the previous month's Monday, shown dimmed
  and unclickable), and the trailing days of the last row are the next month's
  days, also dimmed. Cells are built from date components (not `Duration`) so
  DST cannot shift a date, and weekend columns are skipped when weekends are
  hidden. Previously the grid filled days linearly without the weekday offset,
  so the 1st landed in the Monday column and every day was misaligned.

### Key files
| File | Purpose |
|------|---------|
| `lib/models/work_config.dart` | `WorkConfig` model + DST-safe `isoWeekNumber()` |
| `lib/screens/overview_tab.dart` | Week/Month overview headers + month week-number gutter + aligned month grid |
| `test/work_config_test.dart` | ISO week + reduced-period regression tests |

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

## Real-Time Transit Integration (SL Journey Planner)

ChronoWarden uses SL's Journey Planner API to show journey options between
the user's home and work stations, accounting for walking time and platform
wait buffers.

### Architecture
```
Flutter Web
  └─ supabase.functions.invoke('sl-proxy', { path: '/v2/trips?...' })
       └─ Supabase Edge Function (Deno) — slims response from ~220KB to essentials
            └─ fetch('https://journeyplanner.integration.sl.se/v2/trips?...')
                 └─ Slimmed JSON (departure_time, arrival_time, legs with
                     line, platform, occupancy, delay) back to Flutter
```

### Why a proxy + slimming?
SL Journey Planner API doesn't set CORS headers, so Flutter Web can't call
it directly. The `sl-proxy` Edge Function adds CORS headers, forwards the
request, and **slimes** the verbose `/v2/trips` response (~220KB for 3
journeys) down to essential fields (~2KB).

### Smart direction logic
The Transit tab automatically switches direction based on time of day:
- **Morning (before 11:00)**: home → work
- **Afternoon (11:00+)**: work → home

### Walk-offset query time
When fetching journeys, the query time is offset by the walking time so
the API returns journeys that depart after the user has walked to the
station, maximizing useful results from the 3-journey limit.

### Station autocomplete
Uses SL Journey Planner `/v2/stop-finder` to search stations by name.
Each query fetches fresh results (no caching) with 300ms debounce.
Returns journey planner global IDs (strings like "9091001001009638").

### Transit config storage
Stored as encrypted JSON inside `user_settings.encrypted_data` under
key `transit_config`. Zero-knowledge like all encrypted data.
Fields:
- `enabled` — toggle to show/hide Transit tab
- `work_stop_id` / `work_stop_name` — journey planner global IDs
- `home_stop_id` / `home_stop_name` — journey planner global IDs
- `walk_home_minutes` / `walk_work_minutes` — walking buffers

### Transit tab visibility
The Transit navigation destination only appears in the bottom nav bar
when `enabled` is true in settings. Disabled users never see it.

### My Day transit card visibility
The My Day transit card is **context-sensitive** — it appears only when the
applicable travel preset uses transit:

- **Active/completed day** — the log is matched to a preset by its four
  per-direction commute values (`TravelPreset.matchesLog` /
  `findPresetForLog`). Day logs don't store a preset id, so matching the
  profile is what makes the decision follow the *synced* log across devices.
- **No day yet** — the last-used preset is used (the Start Day dialog default,
  `PreferencesService.lastTravelPresetId`).
- **Unknown selection** — the card is shown, so transit users are never cut off.

This is why a "No commute (work from home)" preset hides the card even when
the transit integration is enabled and stops are configured. (An earlier fix,
commit `3edc3f0`, dropped this check for the globally enabled flag; it was
restored with profile matching instead of a per-device preset id.)

### Key files
| File | Purpose |
|------|---------|
| `lib/models/transit_config.dart` | TransitConfig model (encrypted settings) |
| `lib/models/journey_info.dart` | Slimmed journey + leg data models |
| `lib/models/station_info.dart` | Station model (global IDs + site IDs) |
| `lib/services/transit_service.dart` | Config CRUD + journey planner fetcher + caching |
| `lib/widgets/station_picker.dart` | Reusable autocomplete with debounce |
| `lib/screens/transit_screen.dart` | Transit tab UI with journey cards |
| `lib/screens/settings_screen.dart` | Transit config card (Work/Home pickers) |
| `lib/screens/main_shell.dart` | Conditional Transit nav item |
| `supabase/functions/sl-proxy/index.ts` | Edge Function: CORS proxy + response slimming |

### Pinned (committed) journey

The SL API returns at most 3 trips per request, and the walk-offset query time
slides that window forward. A train the user commits to can therefore get
pushed out of the visible list. The pinned-journey feature lets the user lock
a trip so it stays visible even when the API no longer returns it.

- **Matching:** by scheduled (planned) departure time-of-day + line + route, so
delays don't make the pin slide between trains.
- **Storage:** `localStorage` (per-device, ephemeral, not encrypted).
- **Auto-expire:** when the departure time has passed (or the day ends,
whichever comes first); unpinning reverts to the normal rolling window.
- **Behavior:** the pinned card renders at top with a Locked badge; if it is
still in the returned list it uses live data, otherwise a synthetic card is
built from the stored pin. Cleared when stations (route) change.

| File | Purpose |
|------|---------|
| `lib/models/pinned_journey.dart` | PinnedJourney model + matching/expiry/synthetic journey |
| `lib/services/pinned_journey_store.dart` | localStorage-backed pin store (ChangeNotifier) |

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
ssh tobbe@192.168.1.50 "cd /opt/appdata/chronowarden/src && SUPABASE_ACCESS_TOKEN='$SUPABASE_ACCESS_TOKEN' supabase functions deploy sl-proxy"
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

## Flex (banked-time) withdrawal visualization

The amount of banked overtime the user plans to withdraw as personal time is
chosen at Start Day and stored in `time_logs.flex_minutes`. It is a **live
projection** for the current day only — it is intentionally NOT used in
edit-day / add-day calculations.

- Shown on the active-day card as "Banked time to withdraw" with an **Adjust**
  button so the user can change it mid-day.
- `AppState.updateFlexMinutes()` writes the new value; the `leaveTime` getter
  subtracts flex, so the projected leave time moves earlier immediately.
- Final overtime (`calculateOvertimeMinutes()`) excludes flex by design.

---

## Leave-time notifications

While a day is active the app watches the projected leave time and shows an
in-app alert (plus optional beep + vibration) when the user is close to
leaving, then again if they overrun.

### Two phases
- **Wrap-up** — fires once `remaining <= notification_threshold_minutes`
  (default 30). Message: `⏰ <time> left — wrap up and head out!`
- **Overtime** — fires once leave time has passed (up to 60 min past).
  Message: `🚨 <n> min past your time — finish up and stop the day!`

### Snooze & dismiss
- **Snooze** (default 10 min, configurable 1–30 in Settings) re-arms the
  alert for later; the same alert fires again when the window expires.
- **Dismiss** (the ✕ button) suppresses alerts for the rest of the day.
- Both alert state and settings are persisted to `SharedPreferences`, so a
  page reload neither re-fires nor forgets a dismissal. An alert that was
  delivered but neither snoozed nor dismissed is restored silently (no
  second beep) after a reload.

### Robustness notes
- All timing decisions live in the pure `evaluateLeaveAlert()` function in
  `lib/services/notification_service.dart`, so they are unit-tested
  (`test/notification_service_test.dart`).
- The projected leave time is computed from the **live lunch timer**: if a
  lunch break is running longer than the planned lunch, the alert (and the
  active-day card) shift later via `AppState.effectiveLeaveTime()` /
  `TimeLog.leaveTimeWithLunch()`. This prevents the wrap-up alert from firing
  too early during an overrunning lunch.
- The banner is rendered by `MainShell`, so it is visible on every tab. The
  per-second check runs in `MyDayTab`, which `MainShell` keeps alive in its
  `IndexedStack`.

### Key files
| File | Purpose |
|------|---------|
| `lib/services/notification_service.dart` | Settings, per-day state, `evaluateLeaveAlert()` |
| `lib/widgets/alert_banner.dart` | Banner UI with snooze + dismiss actions |
| `lib/widgets/notification_settings.dart` | Threshold + snooze sliders, sound/vibration |
| `lib/screens/my_day_tab.dart` | Per-second `_checkNotification()` tick |
| `lib/screens/main_shell.dart` | Global banner host |
| `test/notification_service_test.dart` | Alert-timing regression tests |

---

## Changelog / What's New

The app shows an in-app changelog, generated **from the git commit history**.
There is no hand-maintained list — the commit subjects are the source of truth.

### How it works
```
tool/generate_changelog.sh   → CHANGELOG.md (committed)
        → Flutter asset (pubspec.yaml)
        → ChangelogService.load() → parseChangelog()
        → ChangelogScreen ("What's New")
```

- `tool/generate_changelog.sh` runs `git log --no-merges` (newest first,
grouped by commit date) and writes `CHANGELOG.md`. Default: last 300 commits.
- `CHANGELOG.md` **is committed** so local builds and self-hosted instances
that lack `.git` still ship a changelog.
- The Docker build also re-runs the script (best effort) so the hosted
instance always reflects the history it was built from.

### When to run it
Run `tool/generate_changelog.sh` as part of the release routine — before
`git commit` (see "Release to production → Step 1").

### UI entry points
- Settings → **About & Open Source → What's New**
- About screen → **What's New → View changelog**

The Markdown format is intentionally tiny (headings `## YYYY-MM-DD` and
bullets `- text (\`hash\`)`) so no Markdown package is needed; see
`parseChangelog()`.

### Static asset caching (nginx)
`CHANGELOG.md` is a normal Flutter asset, so the browser can serve it from
cache after an update. The nginx config in `Dockerfile` must therefore send
`Cache-Control: no-cache, no-store, must-revalidate` for **every text asset
that changes between builds** — not just the obvious ones:

```
location ~ \.(js|dart|html|json|md|sql|txt|xml)$ { add_header Cache-Control ... }
```

Missing `md` here was a real bug: after pressing **Reload** the app fetched
the new bundle but reused a cached `assets/CHANGELOG.md`, so "What's New"
lagged behind by one deploy. Add new extensions to this list when you ship
new build-generated text assets.

### Key files
| File | Purpose |
|------|---------|
| `tool/generate_changelog.sh` | Generates `CHANGELOG.md` from `git log` |
| `CHANGELOG.md` | Generated changelog (committed asset) |
| `lib/models/changelog.dart` | `ChangelogEntry`/`ChangelogGroup` + `parseChangelog()` |
| `lib/services/changelog_service.dart` | Loads + caches the asset |
| `lib/screens/changelog_screen.dart` | "What's New" screen |
| `lib/screens/about_screen.dart` | "What's New" section / entry point |
| `lib/widgets/about_app_section.dart` | Settings card entry point |
| `test/changelog_test.dart` | Parser tests |
| `test/changelog_screen_test.dart` | Asset-loading widget test |

---

## Version Check / Update Prompt

Long-lived browser tabs keep running the JavaScript they loaded, so a deploy
would otherwise go unnoticed until a manual refresh. The app detects newer
deployments and prompts the user to reload.

### How it works
```
tool/generate_build_info.sh
   ├─ build_info.json    → Flutter asset (the running app's own commit)
   └─ web/version.json   → served by nginx at /version.json (server commit)
                ↓
UpdateService polls /version.json?t=<ts>  →  isUpdateAvailable()
                ↓
UpdateBanner (MainShell) → "Reload" button → web_browser.reloadPage()
```

- Both JSON files contain `{version, commit, built_at}` and are generated from
the same git commit, so the **commit id is the comparison key**.
- `UpdateService` polls every **5 minutes**, and immediately whenever the tab
becomes visible again (`onPageVisible`).
- The prompt only appears when both commits are known (not `dev`) and differ.
  Local/dev builds and git-less self-hosted builds therefore stay quiet.
- **Dismiss** records the server commit in `localStorage`; the prompt stays
  hidden for that build but reappears for the next deploy.
- **Reload** calls `window.location.reload()`. nginx already sends
  `no-cache` for `.js`/`.dart`/`.html`/`.json`, so the new bundle is fetched.
- The banner is hosted in `MainShell` (same place as the leave-time alert).

### Key files
| File | Purpose |
|------|---------|
| `tool/generate_build_info.sh` | Writes `build_info.json` + `web/version.json` |
| `lib/models/build_info.dart` | `BuildInfo.parse()` + `isUpdateAvailable()` |
| `lib/services/update_service.dart` | Polls the server, exposes `updateAvailable` |
| `lib/widgets/update_banner.dart` | "Reload" + dismiss banner |
| `lib/screens/main_shell.dart` | Starts polling + hosts the banner |
| `lib/utils/web_browser*.dart` | `fetchText`, `onPageVisible`, `reloadPage` |
| `test/build_info_test.dart` | Version-comparison tests |

---

## Localization (i18n)

The app supports **English (source) and Swedish**. The language is chosen in
**Settings → Language** and is persisted both locally and in the encrypted
`user_settings` row, so it follows the user across devices.

### How it works
English is the single source of truth. Call sites pass the English string and
the active locale looks it up in its catalog, falling back to English:

```dart
Text(context.t('Leave time'))
Text(context.t('Snooze {minutes}m', {'minutes': 10}))
```

- `lib/l10n/app_strings.dart` — `AppStrings` + `AppStringsDelegate` +
  the `context.t(...)` / `context.strings` extension. Falls back to English
  when no delegate is installed, so bare widget tests keep working.
- `lib/l10n/app_strings_sv.dart` — the Swedish catalog, keyed by the English
  text (`{placeholders}` for interpolation).
- `lib/services/locale_service.dart` — `LocaleService` (ChangeNotifier):
  caches the choice in `SharedPreferences`, mirrors it to `user_settings`
  (`UserSettingsService.getLanguage/setLanguage`), and syncs on startup and
  after passphrase unlock.
- `lib/widgets/language_setting.dart` — the Settings dropdown (English/Svenska).
- `lib/main.dart` — sets `MaterialApp.locale`, `supportedLocales`, and the
  `flutter_localizations` delegates.

### Guard test
`test/app_strings_test.dart` scans `lib/` for `context.t('…')` calls and fails
if any has no Swedish entry, or if a catalog entry is unused. It also checks
fallback + placeholder substitution. **Add the Swedish entry in the same
commit as the call site**, or this test fails.

### Adding a language
1. Add a catalog (`app_strings_xx.dart`) and a case in `AppStrings.forLocale`.
2. Add the code to `LocaleService.supportedLanguages` and `MaterialApp`
   `supportedLocales`.
3. Extend the `AppStringsDelegate`. The guard test can be pointed at the new
   catalog if desired.

### Pending (still English)
The infrastructure and the main surfaces are translated. These are **not yet
migrated** — they still render English literals (the fallback keeps them
readable):
`about_screen`, `about_encryption_screen`, `changelog_screen` (English by
design for the changelog content), `admin_screen`, `transit_screen`,
`projection_screen`, `overview_tab`/`calendar_views`, `history_content`,
`period_tab`, `setup_screen`, `pending_screen`, `migration_screen`,
`recovery_onboarding_screen`, `add_day_dialog`, `edit_day_dialog`,
`start_stop_day_dialogs`, `import_dialog`, `time_bank_chart`,
`recovery_phrase_card`, `station_picker`, `log_card`, `external_link`, plus
`alert_banner`/`update_banner` labels and notification alert messages.

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
