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
To keep API credentials out of version control, ChronoWarden uses `--dart-define-from-file`.

1. Create a file named `secrets.json` in the root directory (this file is excluded via `.gitignore`):
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
