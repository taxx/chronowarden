# Authentication & User Management

ChronoWarden uses Supabase Auth with an admin-invite model. Admins manage users
but cannot see other users' data — each user operates on their own isolated
"island".

## Roles & Statuses

| Role    | Status     | Meaning                                                  |
|---------|------------|----------------------------------------------------------|
| `admin` | `approved` | Can manage users (approve, reject, delete, create invites). Sees only own data. |
| `user`  | `approved` | Regular time-tracking user. Sees only own data.          |
| `user`  | `pending`  | Signed up without an invite token; awaiting admin approval. |
| `user`  | `rejected` | Admin declined this user.                                |

## Auth Flow

### First Admin (empty DB)

1. App detects no existing `profiles` rows (via `has_profiles()` RPC function)
2. Shows "Create Admin Account" screen (pre-filled with `role='admin'`, `status='approved'`)
3. After signup, the `handle_new_user` trigger creates the profile row automatically
4. This user becomes the sole admin

### Regular Users (invite-only)

1. Admin generates a short invite token (e.g., `7f3k2a`) and shares it
2. User enters email + password + invite token at signup → auto-approved
3. Without a token, user signs up as `pending` until admin approves

### Bootstrap safety

If a user signs up **before** the tables/trigger exist, `AuthService._ensureProfile()`
creates the profile row on login via `upsert(..., onConflict: 'id')`. The first user
becomes admin automatically.

## Routing (post-login)

```
main()
  └─ Supabase.initialize()
      └─ AuthService.init() checks session
          ├─ No session + tables missing → SetupScreen (SQL copy)
          ├─ No session + tables empty   → SignupScreen (admin mode)
          ├─ No session + has profiles   → LoginScreen
          └─ Has session → load profile
              ├─ role = 'admin'  → AdminShell (Users tab + My Day tab)
              ├─ role = 'user', status = 'approved' → HomeScreen
              └─ status = 'pending' → "Account pending approval"
```

## Database Schema

### `profiles` (extends auth.users)

| Column | Type | Notes |
|--------|------|-------|
| `id` | `uuid PK → auth.users.id` | |
| `email` | `text` | Copied from `auth.users` by trigger; stored locally because PostgREST cannot join the `auth` schema. |
| `role` | `text check ('admin','user')` | |
| `status` | `text check ('pending','approved','rejected')` | |
| `full_name` | `text` | |
| `created_at` | `timestamptz` | |

### `invites`

| Column | Type | Notes |
|--------|------|-------|
| `id` | `uuid PK` | |
| `created_by` | `uuid → auth.users` | |
| `email` | `text` | Optional reference email |
| `token` | `text unique` | Short shareable code |
| `used` | `boolean default false` | |
| `expires_at` | `timestamptz` | |
| `created_at` | `timestamptz` | |

### Existing tables

All three (`time_logs`, `work_period_settings`, `travel_presets`):
- `user_id uuid NOT NULL` (no more `IS NULL` fallback)
- RLS: `auth.uid() = user_id` only
- Foreign keys use `ON DELETE CASCADE`

## RLS Policies

| Table | Policy |
|-------|--------|
| `profiles` | Users: read own row only. Admins: full CRUD (via `is_admin()` helper function). |
| `invites` | Admins only: full CRUD (via `is_admin()` helper function). |
| `time_logs` | Owner only (`auth.uid() = user_id`) |
| `work_period_settings` | Owner only |
| `travel_presets` | Owner only |

### Helper functions (SECURITY DEFINER)

Because PostgREST cannot query `auth.users` from RLS policies (causes infinite recursion)
and unauthenticated clients are blocked by RLS on `profiles`, two helper functions
bypass RLS using `SECURITY DEFINER`:

```sql
-- Returns true if the current user is an approved admin
create function is_admin() returns boolean
  security definer set search_path = public ...

-- Returns true if any profiles exist (used by unauthenticated clients)
create function has_profiles() returns boolean
  security definer set search_path = public ...
```

### Signup trigger

```sql
create function handle_new_user()
  returns trigger
  security definer set search_path = public ...
```

Creates a `profiles` row automatically when a new `auth.users` row is inserted,
copying `email`, `full_name`, `role`, and `status` from `raw_user_meta_data`.

## Dart Layer

### New Files

| File | Purpose |
|------|---------|
| `lib/models/user_profile.dart` | Profile model (id, email, role, status, fullName) |
| `lib/models/invite.dart` | Invite model (id, token, used, email, expiresAt) |
| `lib/services/auth_service.dart` | Sign in/out, sign up (with invite token), session init, first-admin detection, auto-profile creation |
| `lib/services/profile_service.dart` | Admin CRUD: list/approve/reject/delete users, create/delete invites |
| `lib/screens/login_screen.dart` | Email/password login with link to signup |
| `lib/screens/signup_screen.dart` | Sign up with optional invite token (auto-approve) or pending mode. First-admin mode skips token. |
| `lib/screens/admin_shell.dart` | Admin tab bar: Users \| My Day |
| `lib/screens/admin_screen.dart` | User list (approve/reject/delete) + Invite tab (create/delete tokens) |
| `lib/screens/pending_screen.dart` | "Account pending approval" screen with re-check button |

### Modified Files

| File | Changes |
|------|---------|
| `lib/main.dart` | Auth gate: checks session → routes to login/signup/admin shell/home. Uses `ListenableBuilder` on both `AuthService` and `AppState`. |
| `lib/services/time_log_service.dart` | All queries scoped to `user_id = currentSession.user.id`. Returns empty/null when not authenticated. |
| `lib/services/work_period_service.dart` | Same scoping. |
| `lib/services/travel_preset_service.dart` | Same scoping. |
| `lib/screens/home_screen.dart` | Added `showSettings`/`showLogout` constructor params + logout confirmation dialog. Reused by both `HomeScreen` (standalone) and `AdminShell`. |
| `lib/screens/setup_screen.dart` | Complete new SQL schema with `profiles`, `invites`, helper functions, RLS policies, and signup trigger. Verification probes tables directly (no auth required). Navigates to next screen after success. |

## Key Implementation Notes

1. **Email is stored in `profiles`** — PostgREST cannot join across the `auth` schema, so the `email` column mirrors `auth.users.email` and is populated by the `handle_new_user` trigger.

2. **`_ensureProfile()` uses `upsert`** — If the trigger already created the profile row, the upsert silently no-ops instead of throwing a 409 duplicate key error.

3. **`has_profiles()` RPC bypasses RLS** — Unauthenticated clients need to know whether profiles exist (to decide between first-admin signup vs login), but RLS blocks direct queries. The `SECURITY DEFINER` RPC function solves this.

4. **`is_admin()` RPC avoids infinite recursion** — The `admin_manage_profiles` policy queries `profiles` from within a policy on `profiles`. The `SECURITY DEFINER` function bypasses RLS to break the loop.

5. **Admin delete fallback** — `_client.auth.admin.deleteUser()` requires the service role key. Falls back to rejecting the profile (account disabled) and shows a message to contact Supabase admin for full deletion.
