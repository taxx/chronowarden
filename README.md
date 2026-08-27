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
1. **Seasonal Work Periods:** Automatically detects if the current day requires summer hours (e.g., 7h 15m / 435 mins) or winter hours (e.g., 8h / 480 mins) based on user-defined date ranges.
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
│   ├── work_period_setting.dart  # Seasonal work period
│   ├── user_profile.dart    # Auth user profile (role, status)
│   └── invite.dart          # Invite token
├── services/                # Business logic & API layer
│   ├── auth_service.dart    # Sign in/out, sign up, session management
│   ├── profile_service.dart # Admin user management
│   ├── time_log_service.dart
│   ├── travel_preset_service.dart
│   ├── work_period_service.dart
│   └── supabase_service.dart
├── screens/                 # UI screens
│   ├── login_screen.dart
│   ├── signup_screen.dart
│   ├── pending_screen.dart
│   ├── admin_shell.dart
│   ├── admin_screen.dart
│   ├── home_screen.dart
│   ├── history_screen.dart
│   ├── settings_screen.dart
│   └── setup_screen.dart
├── app_state.dart           # Central ChangeNotifier
└── main.dart                # Auth gate & app entry point
```
