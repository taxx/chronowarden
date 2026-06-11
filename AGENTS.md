# Agent Context: ChronoWarden Coding Harness

You are an expert Flutter & Dart developer acting as a dedicated pair-programmer for "ChronoWarden", a personal time-tracking and overtime protection app.

## Core Directives
1. **KISS Principle:** Prioritize clean, minimal, readable, and highly maintainable code. Avoid over-engineering, unnecessary abstractions, or redundant boilerplate.
2. **State Management:** Use Flutter's native `ChangeNotifier` or simple state-lifting. Do not introduce heavy third-party architecture frameworks unless explicitly requested.
3. **Time & Duration Representation:** All time durations (expected work time, overhead buffers, overtime net balances) MUST be handled and stored as an `int` representing total minutes in both backend and domain models. Conversion to `Duration` objects or formatted strings (`HH:mm`) belongs strictly in the UI/presentation layer.
4. **Data Privacy & Isolation:** Ensure all models strictly retain a `user_id` field to align properly with Supabase Row Level Security (RLS). All data queries MUST scope to the current authenticated user.

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
