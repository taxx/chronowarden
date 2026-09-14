# ChronoWarden 🛡️⏱️

ChronoWarden is a personal time-banking and overtime protection system built using Flutter (Mobile/Web) and Supabase. The primary objective of the application is to protect the user's personal time and prevent unintended, unpaid overtime by calculating the exact time they can stop working with a clear conscience.

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
- **Data isolation** is enforced at the database level via RLS policies — each user can only see their own `time_logs`, `work_period_settings`, and `travel_presets`

See `AUTH.md` for the full authentication architecture.

## Core Logic & Features
1. **Seasonal Work Periods:** Automatically detects if the current day requires summer hours (e.g., 7h 15m / 435 mins) or winter hours (e.g., 8h / 480 mins) based on user-defined reduced-week ranges (ISO week numbers, weeks start on Monday as in Sweden). The ISO week number is computed with UTC date arithmetic so Daylight Saving Time transitions never skew the week count. The Week/Month overview headers show the current ISO week(s) to make the reduced-period mapping transparent.
2. **Dynamic Travel Presets:** Users configure their commute/work scenarios (e.g., "Train via Mörby", "Car", "WFH") along with their associated `overhead_minutes` (combined buffer for lunch, walking, driving, etc.).
3. **Morning Calculator:** Instantly determines the target departure time as soon as the day starts:  
   `Leave Time = Start Time + Expected Work Minutes + Overhead Minutes + Lunch Minutes`
4. **Time Bank:** The overall flex-time balance is derived dynamically by summing the `overtime_minutes` (+/- net) across all recorded entries.

## Getting Started & Secrets Management
ChronoWarden uses `--dart-define-from-file` to inject API credentials at compile time.
Secrets are kept out of version control via `.gitignore` (both `secrets.json`, `.env`, and `.env.db`).

### Build-time secrets (`secrets.json`)
Used for Flutter/Docker builds. Never committed.

### Database credentials (`.env.db`)
Used by the AI agent for direct database operations (SQL migrations, backups).
See `.env.db.sample` for the template. Never committed.

### Local Development
1. Create a file named `secrets.json` in the root directory:
```json
{
  "SUPABASE_URL": "https://your-project.supabase.co",
  "SUPABASE_ANON_KEY": "your-anon-key-here"
}
```

2. Run the database schema SQL from `SetupScreen` (tap "Copy" in the app, paste into Supabase SQL Editor).

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
The app will be available at `http://localhost:8080`.

The final image is a slim nginx container (~40 MB) — the bulky Flutter build stage is discarded. Any change to secrets requires a full rebuild since `String.fromEnvironment` bakes values into the compiled JS at build time.

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

### DEK Cache
- The unwrapped DEK is cached in `localStorage` (not `sessionStorage`)
- Survives closing and reopening the browser tab
- Cleared on logout
- If the cached DEK is missing but an envelope exists, the app prompts for passphrase

See `ENCRYPTION_PLAN.md` for the full architecture decision record.

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
Function adds CORS headers and **slimes** the verbose `/v2/trips`
response (~220KB for 3 journeys) to essential fields (~2KB).

### Transit tab visibility
The Transit nav item only appears when enabled in Settings.
Disabled users never see it.

### Edge Function credentials (`.env.edge`)
Credentials live in `.env.edge` (gitignored). Template at `.env.edge.sample`.
Contains the Supabase access token and project reference.

### Edge Function deployment
Located at `supabase/functions/sl-proxy/index.ts`.
Must be deployed separately — NOT included in Docker build:
```bash
cd /path/to/chronowarden
source .env.edge
ssh tobbe@192.168.1.50 "cd /opt/appdata/chronowarden && SUPABASE_ACCESS_TOKEN='$SUPABASE_ACCESS_TOKEN' supabase functions deploy sl-proxy"
```

**First-time CLI install** (already done):
```bash
ssh tobbe@192.168.1.50 "curl -fsSL 'https://github.com/supabase/cli/releases/latest/download/supabase_cli_linux_amd64.tar.gz' -o /tmp/supabase.tar.gz && tar -xzf /tmp/supabase.tar.gz -C /tmp && sudo mv /tmp/supabase /usr/local/bin/supabase && sudo chmod +x /usr/local/bin/supabase && rm -f /tmp/supabase.tar.gz"
source .env.edge
SUPABASE_ACCESS_TOKEN="$SUPABASE_ACCESS_TOKEN" supabase link --project-ref "$SUPABASE_PROJECT_REF"
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
├── models/                  # Domain models
│   ├── time_log.dart        # Workday log entry
│   ├── travel_preset.dart   # Commute scenario preset
│   ├── transit_config.dart  # Transit integration preferences
│   ├── journey_info.dart   # Slimmed journey planner response
│   ├── station_info.dart    # Station model (global IDs + site IDs)
│   ├── user_profile.dart    # Auth user profile (role, status)
│   └── invite.dart          # Invite token
├── services/                # Business logic & API layer
│   ├── auth_service.dart    # Sign in/out, sign up, session management
│   ├── profile_service.dart # Admin user management
│   ├── time_log_service.dart
│   ├── travel_preset_service.dart
│   ├── transit_service.dart # Transit config + journey planner fetcher + caching
│   ├── work_period_service.dart
│   ├── crypto_service.dart  # Encryption / decryption
│   ├── notification_service.dart
│   ├── preferences_service.dart
│   ├── user_settings_service.dart
│   └── supabase_service.dart
├── screens/                 # UI screens
│   ├── login_screen.dart
│   ├── signup_screen.dart
│   ├── pending_screen.dart
│   ├── admin_screen.dart
│   ├── main_shell.dart      # Bottom nav with conditional Transit tab
│   ├── my_day_tab.dart
│   ├── overview_tab.dart
│   ├── history_content.dart
│   ├── projection_screen.dart
│   ├── transit_screen.dart  # Journey options list with smart direction
│   ├── settings_screen.dart # Transit config card (Work/Home pickers)
│   └── about_encryption_screen.dart
├── widgets/                 # Reusable widgets
│   └── station_picker.dart  # SL station autocomplete with debounce
├── utils/                   # Utilities
│   ├── csv_export.dart
│   ├── csv_import.dart
│   ├── overtime_colors.dart
│   └── paste_button.dart
├── app_state.dart           # Central ChangeNotifier
└── main.dart                # Auth gate & app entry point
supabase/
└── functions/
    └── sl-proxy/
        └── index.ts         # Edge Function: CORS proxy + response slimming
```
