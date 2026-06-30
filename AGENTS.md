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
