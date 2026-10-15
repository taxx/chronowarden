# ChronoWarden 🛡️⏱️

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![GitHub issues](https://img.shields.io/github/issues/taxx/chronowarden)](https://github.com/taxx/chronowarden/issues)
[![GitHub stars](https://img.shields.io/github/stars/taxx/chronowarden)](https://github.com/taxx/chronowarden)

ChronoWarden is a personal time-banking and overtime protection system built with
Flutter (Web/Mobile) and Supabase. Its goal is to protect your personal time and
prevent unintended, unpaid overtime by calculating the exact moment you can stop
working with a clear conscience.

It is **free and open-source software** (MIT), built to be **self-hosted**.
You can also use the maintainer's hosted instance as a convenience — but that
instance is provided on a **best-effort basis**, with **no guarantees** of
availability, uptime, or data retention.

| Resource | Link |
|----------|------|
| 📦 Source code | <https://github.com/taxx/chronowarden> |
| 🐛 Report an issue / request a feature | <https://github.com/taxx/chronowarden/issues> |
| 📖 Self-hosting guide | this file (see [Running it](#two-ways-to-run-chronowarden)) |
| ⚖️ License | [MIT](LICENSE) |
| 🔐 Encryption architecture | [`ENCRYPTION_PLAN.md`](ENCRYPTION_PLAN.md) |
| 👥 Auth architecture | [`AUTH.md`](AUTH.md) |

---

## Two ways to run ChronoWarden

### 1. Self-host it (recommended)

You run the whole stack yourself: your own Supabase project, your own web
container, your own data. This is the most private and most durable option —
nobody else can shut it down, and you own your backups. Everything you need is
in this repository; see [Getting Started](#getting-started--secrets-management)
and [Docker Deployment](#docker-deployment).

### 2. Use the hosted instance (best effort)

The maintainer also runs a public instance at
<https://chronowarden.slumpen.com/>. It is meant as a convenience, not a
service-level commitment:

- **No guarantees.** Availability, uptime, and data retention are best-effort.
  The instance may be down, reset, or retired at any time.
- **Your data is still encrypted end-to-end** with your own passphrase, so the
  host cannot read it. But if you lose your passphrase *and* your recovery
  phrase, no one — including the administrator — can restore your data.
- **Back up anything you care about.** Prefer self-hosting or the CSV export if
  you need long-term guarantees.

---

## Architecture & Tech Stack

- **Frontend:** Flutter (KISS design principles, responsive for both mobile and web).
- **Backend & Database:** Supabase (PostgreSQL with automatic REST API generation and built-in Authentication).
- **Security:** Row Level Security (RLS) in Supabase for seamless multi-user isolation. API secrets managed securely via Dart-defines.
- **Auth:** Supabase Auth with admin-invite model. Each user operates on their own isolated "island" — admins can manage users but cannot see their data.

## Multi-User & Auth

ChronoWarden supports multiple users with role-based access:

| Role | Capabilities |
|------|-------------|
| **Admin** | Manage users (approve/reject/delete), create invite tokens, use own time-tracking |
| **User** | Full time-tracking access (own data only) |

- **First admin** is created automatically when the app detects an empty database
- **New users** join via invite tokens shared by an admin, or sign up as pending until approved
- **Data isolation** is enforced at the database level via RLS policies — each user can only see their own `time_logs`, `travel_presets`, and `user_settings`

See [`AUTH.md`](AUTH.md) for the full authentication architecture.

## Core Logic & Features

1. **Seasonal Work Periods:** Automatically detects if the current day requires summer hours (e.g., 7h 15m / 435 mins) or winter hours (e.g., 8h / 480 mins) based on user-defined reduced-week ranges (ISO week numbers, weeks start on Monday as in Sweden). The ISO week number is computed with UTC date arithmetic so Daylight Saving Time transitions never skew the week count. The Week/Month overview headers show the current ISO week(s) to make the reduced-period mapping transparent. The month calendar is aligned to the real weekday columns — the 1st of the month sits under its actual weekday, with the previous/next month's boundary days shown dimmed and unclickable.
2. **Dynamic Travel Presets:** Users configure their commute/work scenarios (e.g., "Train via Mörby", "Car", "WFH") along with their associated `overhead_minutes` (combined buffer for lunch, walking, driving, etc.).
3. **Morning Calculator:** Instantly determines the target departure time as soon as the day starts:  
   `Leave Time = Start Time + Expected Work Minutes + Overhead Minutes + Lunch Minutes`
4. **Time Bank:** The overall flex-time balance is derived dynamically by summing the `overtime_minutes` (+/- net) across all recorded entries.
5. **Bilingual UI (English / Swedish):** English is the source of truth; every string is translated through a lightweight catalog and falls back to English if a translation is missing. Pick the language in **Settings → Language** — the choice is stored in your encrypted settings, so it follows you across devices.
6. **In-app changelog ("What's New"):** The app ships a changelog generated straight from the git commit history, reachable from Settings and the About screen.
7. **Update prompt:** The app compares its own build commit against the server's `/version.json` and offers a one-tap **Reload** when a newer deployment is detected — handy for long-lived browser tabs.
8. **Leave-time notifications:** Alerts fire shortly before your projected leave time — and again if you overrun it — via an in-app banner, an **OS notification** (when permission is granted, so it surfaces even in a background tab) and an optional sound/vibration. Supports **Snooze** and **Dismiss for today**, accounts for a lunch/non-work break that is still running, and includes a small **diagnostics** panel (permission, audio state, vibration support).
9. **Non-work time (errands):** A second, optional break type alongside lunch. Start/stop it from My Day (or set it in the add/edit-day dialogs) and it counts as not-working time, exactly like lunch — leaving the time bank and flex withdrawal untouched. Toggle it in **Settings** (enabled by default).

---

## Getting Started & Secrets Management

ChronoWarden uses `--dart-define-from-file` to inject API credentials at compile time.
Secrets are kept out of version control via `.gitignore` (both `secrets.json`, `.env`, and `.env.db`).

### Build-time secrets (`secrets.json`)
Used for Flutter/Docker builds. Never committed.

### Database credentials (`.env.db`)
Used by the AI agent for direct database operations (SQL migrations, backups).
See `.env.db.sample` for the template. Never committed.

### Edge Function credentials (`.env.edge`)
Used to deploy the `sl-proxy` Supabase Edge Function.
See `.env.edge.sample` for the template. Never committed.

### Local Development
1. Create a file named `secrets.json` in the root directory:
```json
{
  "SUPABASE_URL": "https://your-project.supabase.co",
  "SUPABASE_ANON_KEY": "your-anon-key-here"
}
```

2. Run the database schema SQL from `SetupScreen` (tap "Copy" in the app, paste into Supabase SQL Editor). The SQL is loaded from the canonical [`supabase_schema.sql`](supabase_schema.sql) asset — that file is the single source of truth for the schema.

3. Launch the app:
```bash
flutter run --dart-define-from-file=secrets.json
```

### Docker Deployment
ChronoWarden can be containerized with a multi-stage Docker build (Flutter compile → nginx serve).

1. Create a `.env` file from the template:
```bash
cp .env.example .env
```
2. Edit `.env` with your real Supabase credentials.
3. Build and run:
```bash
docker compose up --build
```
The app will be available at `http://localhost:8981`.

The final image is a slim nginx container (~40 MB) — the bulky Flutter build stage is discarded. Any change to secrets requires a full rebuild since `String.fromEnvironment` bakes values into the compiled JS at build time.

nginx serves the app with `Cache-Control: no-cache, no-store, must-revalidate` for text assets (`.js`, `.dart`, `.html`, `.json`, `.md`, `.sql`, …) so a redeploy is never served stale. The Docker build also regenerates `CHANGELOG.md`, `build_info.json`, and `web/version.json` from the checked-out git history (see [Generated metadata](#generated-metadata)).

### Generated metadata

Three files are generated rather than hand-written:

| File | Generated by | Purpose |
|------|--------------|---------|
| `CHANGELOG.md` | `tool/generate_changelog.sh` | In-app "What's New" content |
| `build_info.json` | `tool/generate_build_info.sh` | The running build's version/commit (baked in as an asset) |
| `web/version.json` | `tool/generate_build_info.sh` | The server's current commit, served at `/version.json` |

Run both scripts before committing (they are part of the release routine), and the Docker build re-runs them so the hosted instance always reflects the commit it was built from.

---

## Encryption & Zero-Knowledge

ChronoWarden uses **envelope encryption** to ensure even the database administrator
cannot read user data. Each user has their own encryption passphrase that unlocks
a Data Encryption Key (DEK) stored encrypted on the server.

### Key hierarchy
```
Passphrase → PBKDF2(310k) → Master Key → wrap DEK → AES-256-GCM encrypt data
```

### What's encrypted
- All time logs, travel presets, and settings
- Encrypted with AES-256-GCM, keyed with a per-user 256-bit DEK
- DEK is wrapped with a Master Key derived from the user's passphrase

### What stays plaintext
- `user_id` (for RLS), `date` (for server-side filtering)
- Travel preset `name` (for dropdown display)

### Recovery
- 24-word BIP39 mnemonic encodes the DEK directly
- If passphrase + recovery phrase are both lost, data is gone forever

### Transparency for new users
Login and Signup screens show a "How we store & protect your data" link that
opens a modal explainer (zero-knowledge architecture, key hierarchy, recovery
phrase guidance, and the critical warning) so prospective users understand
the encryption setup — and the importance of keeping their keys and recovery
phrase safe — before they sign in.

### DEK Cache
- The unwrapped DEK is cached in browser `localStorage` (not `sessionStorage`)
- Survives refreshing and reopening the browser tab
- Cleared on logout
- If the cached DEK is missing but an envelope exists, the app prompts for passphrase

See [`ENCRYPTION_PLAN.md`](ENCRYPTION_PLAN.md) for the full architecture decision record.

---

## Database Backups

Before destructive schema changes, create a backup:
```bash
source .env.db
pg_dump --dbname="$DB_CONNECTION_STRING" --format=tar \
  --file=chronowarden_backup_$(date +%Y-%m-%d).tar --no-owner
```

To restore:
```bash
source .env.db
pg_restore --dbname="$DB_CONNECTION_STRING" --format=tar chronowarden_backup_*.tar
```

Backup files are gitignored (`chronowarden_backup_*.tar`).

A `backup` container can also run `pg_dump` on a cron schedule (daily at
02:00, 62-day retention by default) — see `backup/` and `docker-compose.yaml`.

---

## Real-Time Transit Integration (SL Journey Planner)

ChronoWarden uses SL's Journey Planner API to show journey options
between home and work stations. The feature is opt-in via Settings.

### Smart direction
- **Morning (before 11:00)**: home → work
- **Afternoon (11:00+)**: work → home

### Walk-offset query time
When fetching journeys, the query time is offset by walking minutes so
the API returns journeys that depart after the user has walked to the
station, maximizing useful results from the 3-journey limit.

### Station autocomplete
Uses SL Journey Planner `/v2/stop-finder` with 300ms debounce.
Returns journey planner global IDs (strings like "9091001001009638").

### CORS proxy + response slimming
SL Journey Planner API doesn't set CORS headers. The `sl-proxy` Edge
Function adds CORS headers and **slims** the verbose `/v2/trips`
response (~220KB for 3 journeys) to essential fields (~2KB).

### Transit tab visibility
The Transit nav item only appears when enabled in Settings.
Disabled users never see it.

### Edge Function deployment
Located at `supabase/functions/sl-proxy/index.ts`.
Must be deployed separately — NOT included in Docker build:
```bash
cd /path/to/chronowarden
source .env.edge
supabase functions deploy sl-proxy
```

---

## Cross-Device Realtime Sync

ChronoWarden uses Supabase Realtime to sync time log changes across devices
without page reloads. When you start/stop a day on one device, all other
devices update automatically within seconds.

### Setup
- `time_logs` must be in the `supabase_realtime` publication
- Run `migration_enable_realtime.sql` if needed

### How it works
1. `AppState` subscribes to Postgres changes on `time_logs` filtered by `user_id`
2. The subscription fires on INSERT, UPDATE, DELETE
3. If the changed row matches today's date, `todayLog` is re-fetched
4. The time bank balance is always refreshed

---

## Slider Interval Setting

Users can configure the tick interval for lunch and flex time sliders
in **Settings → Slider step size** (1–30 minutes, default 5).
Stored locally in `SharedPreferences`.

---

## iOS Safari Paste Compatibility

Flutter web on iOS Safari doesn't fire paste events to canvas-rendered
TextFields. A `PasteButton` widget provides an explicit paste button
that reads from the Flutter `Clipboard` API directly.

Paste buttons appear on:
- Recovery phrase dialog (PassphraseScreen)
- Encryption passphrase fields (LoginScreen, SignupScreen)

---

## Project Structure

```
lib/
├── app_info.dart            # Project metadata + public links (repo, issues, license)
├── l10n/                    # Localization (English source + catalog delegate)
│   ├── app_strings.dart     # AppStrings, delegate, context.t(...) extension
│   └── app_strings_sv.dart  # Swedish catalog (keyed by English text)
├── models/                  # Domain models
│   ├── time_log.dart        # Workday log entry
│   ├── travel_preset.dart   # Commute scenario preset
│   ├── transit_config.dart  # Transit integration preferences
│   ├── journey_info.dart   # Slimmed journey planner response
│   ├── station_info.dart    # Station model (global IDs + site IDs)
│   ├── pinned_journey.dart  # Locally-pinned (committed) journey
│   ├── changelog.dart       # Changelog entries + parser
│   ├── build_info.dart      # Build version/commit + update-check logic
│   ├── user_profile.dart    # Auth user profile (role, status)
│   ├── period.dart          # Overview aggregation period enum
│   └── invite.dart          # Invite token
├── services/                # Business logic & API layer
│   ├── auth_service.dart    # Sign in/out, sign up, session management
│   ├── profile_service.dart # Admin user management
│   ├── time_log_service.dart
│   ├── travel_preset_service.dart
│   ├── transit_service.dart # Transit config + journey planner fetcher + caching
│   ├── work_config_service.dart # Work config (default/reduced expected minutes)
│   ├── crypto_service.dart  # Encryption / decryption
│   ├── migration_service.dart # One-time plaintext → encrypted migration
│   ├── notification_service.dart # Leave-time alerts (snooze/dismiss)
│   ├── locale_service.dart  # Language selection (local + cross-device)
│   ├── changelog_service.dart # Loads the bundled CHANGELOG.md asset
│   ├── update_service.dart  # Polls /version.json for new deployments
│   ├── preferences_service.dart
│   ├── user_settings_service.dart
│   └── supabase_service.dart
├── screens/                 # UI screens (thin — layout + wiring only)
│   ├── login_screen.dart
│   ├── signup_screen.dart
│   ├── recovery_onboarding_screen.dart
│   ├── pending_screen.dart
│   ├── admin_screen.dart
│   ├── main_shell.dart      # Bottom nav with conditional Transit tab
│   ├── my_day_tab.dart
│   ├── overview_tab.dart
│   ├── history_content.dart
│   ├── projection_screen.dart
│   ├── transit_screen.dart  # Journey options list with smart direction
│   ├── settings_screen.dart # Settings sections wiring
│   ├── migration_screen.dart # First-run encryption setup
│   ├── passphrase_screen.dart # Unlock on a new device
│   ├── setup_screen.dart    # First-time Supabase schema setup
│   ├── changelog_screen.dart # "What's New"
│   ├── about_encryption_screen.dart
│   └── about_screen.dart    # About, open source, issue tracker, self-hosting
├── widgets/                 # Reusable widgets (extracted from screens)
│   ├── add_day_dialog.dart  # Shared add-past-day dialog (Overview + History)
│   ├── edit_day_dialog.dart
│   ├── start_stop_day_dialogs.dart
│   ├── commute_summary.dart
│   ├── stat_row.dart
│   ├── section_card.dart
│   ├── summary_card.dart
│   ├── period_tab.dart      # Week/month/year overview tab
│   ├── calendar_views.dart  # Week/month/year calendar grids
│   ├── time_bank_chart.dart
│   ├── projection_chart.dart
│   ├── journey_card.dart    # Transit journey card / badges
│   ├── journey_tile.dart    # Shared journey status + pin controls
│   ├── break_timer_section.dart # Shared lunch/non-work Start-Stop-Edit row
│   ├── alert_banner.dart
│   ├── update_banner.dart   # "New version available" reload banner
│   ├── language_setting.dart # Settings language dropdown (EN/SV)
│   ├── small_button.dart
│   ├── log_card.dart
│   ├── import_dialog.dart
│   ├── transit_config_section.dart
│   ├── encryption_settings_section.dart
│   ├── about_app_section.dart # Open-source links card (Settings)
│   ├── external_link.dart   # Reusable link text/button (url_launcher)
│   ├── export_settings_section.dart
│   ├── notification_settings.dart
│   ├── personal_settings.dart
│   ├── work_config_section.dart
│   ├── toggle_row.dart
│   ├── recovery_phrase_card.dart
│   └── station_picker.dart  # SL station autocomplete with debounce
├── utils/                   # Utilities
│   ├── csv_export.dart
│   ├── csv_import.dart
│   ├── format.dart          # Shared minute/duration formatting
│   ├── paste_button.dart
│   ├── external_link.dart   # Open URLs in the browser
│   ├── web_browser.dart     # Conditional web bridge (beep/vibrate)
│   ├── web_download.dart    # Conditional file download
│   └── web_local_storage.dart # Conditional localStorage facade
├── app_state.dart           # Central ChangeNotifier
└── main.dart                # Auth gate & app entry point
supabase/
└── functions/
    └── sl-proxy/
        └── index.ts         # Edge Function: CORS proxy + response slimming
tool/
├── generate_changelog.sh    # CHANGELOG.md from git log
└── generate_build_info.sh   # build_info.json + web/version.json
```

---

## Contributing

Contributions are welcome — bug reports, feature ideas, documentation fixes, and
pull requests.

- **Found a bug or have an idea?** Open an issue at
  <https://github.com/taxx/chronowarden/issues>. Please include steps to
  reproduce, expected vs. actual behaviour, and your platform (web, Android, iOS).
- **Questions about security or encryption?** See [`ENCRYPTION_PLAN.md`](ENCRYPTION_PLAN.md)
  first; it documents the threat model and design decisions.
- **Before opening a PR:** run `flutter analyze` and `flutter test`. Keep changes
  small and consistent with the KISS approach (no heavy state-management or
  architecture frameworks).
- **UI text is localized.** Wrap new user-facing strings in `context.t('…')` and
  add the Swedish entry to `lib/l10n/app_strings_sv.dart` —
  `test/app_strings_test.dart` fails otherwise.
- **Regenerate metadata before committing** (they are generated, not hand-written):
  ```bash
  tool/generate_changelog.sh
  tool/generate_build_info.sh
  ```

## License

ChronoWarden is released under the [MIT License](LICENSE).

Copyright © 2026 [taxx](https://github.com/taxx) and contributors.

You are free to use, copy, modify, merge, publish, distribute, sublicense, and/or
sell copies of the software, subject only to including the copyright notice and
license. The software is provided "as is", without warranty of any kind.
