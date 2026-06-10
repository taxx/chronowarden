# Authentication & User Management Plan

## Overview

ChronoWarden uses Supabase Auth for user authentication with an admin-invite model.
Admins manage users but cannot see other users' data — each user operates on their
own isolated "island."

## Roles

| Role | Description |
|------|-------------|
| `admin` | Can manage users (approve, delete, create invites). Sees only own data. |
| `user` | Regular time-tracking user. Sees only own data. |

## User Statuses

| Status | Meaning |
|--------|---------|
| `approved` | Fully active, can log in and use the app |
| `pending` | Signed up without an invite token, awaiting admin approval |
| `rejected` | Admin declined this user |

## Auth Flow

### First Admin (empty DB)
1. App detects no existing `profiles` rows
2. Shows "Create Admin Account" screen (pre-filled with `role='admin'`, `status='approved'`)
3. After signup, this user becomes the sole admin

### Regular Users (invite-only)
1. Admin generates a short invite token (e.g., `7f3k2a`) and shares it
2. User enters email + password + invite token at signup → auto-approved
3. Without a token, user signs up as `pending` until admin approves

## Routing (post-login)

```
main()
  └─ Supabase.initialize()
      └─ AuthService checks session
          ├─ No session + DB empty → SignupScreen (admin mode)
          ├─ No session + DB has users → LoginScreen
          └─ Has session → load profile
              ├─ role = 'admin' → AdminShell
              ├─ role = 'user', status = 'approved' → HomeScreen
              └─ status = 'pending' → "Account pending approval"
```

## Database Schema

### `profiles` (extends auth.users)

| Column | Type | Notes |
|--------|------|-------|
| `id` | `uuid PK → auth.users.id` | |
| `role` | `enum('admin','user')` | first signup = admin |
| `status` | `enum('pending','approved','rejected')` | |
| `full_name` | `text` | |
| `created_at` | `timestamptz` | |

### `invites`

| Column | Type | Notes |
|--------|------|-------|
| `id` | `uuid PK` | |
| `created_by` | `uuid → profiles.id` | |
| `email` | `text` | optional hint |
| `token` | `text unique` | short shareable code |
| `used` | `boolean default false` | |
| `expires_at` | `timestamptz` | |
| `created_at` | `timestamptz` | |

### Existing tables (recreated, no anon access)

All three (`time_logs`, `work_period_settings`, `travel_presets`):
- `user_id uuid NOT NULL` (no more `IS NULL` fallback)
- RLS: `auth.uid() = user_id` only
- Foreign keys use `ON DELETE CASCADE`

## RLS Policies

| Table | Policy |
|-------|--------|
| `profiles` | Users: read own row only. Admins: full CRUD on all |
| `invites` | Admins only: full CRUD |
| `time_logs` | Owner only (`auth.uid() = user_id`) |
| `work_period_settings` | Owner only |
| `travel_presets` | Owner only |

## Dart Layer

### New Files
- `lib/models/user_profile.dart` — Profile model
- `lib/models/invite.dart` — Invite model
- `lib/services/auth_service.dart` — Sign in/out, sign up, session management
- `lib/services/profile_service.dart` — CRUD for profiles + invites (admin ops)
- `lib/screens/login_screen.dart` — Email/password login
- `lib/screens/signup_screen.dart` — Sign up with optional invite token
- `lib/screens/admin_screen.dart` — User management + invite tokens

### Modified Files
- `lib/main.dart` — Auth gate routing
- `lib/app_state.dart` — AuthService dependency, userId injection, profile state
- `lib/services/time_log_service.dart` — Queries scoped to current user
- `lib/services/work_period_service.dart` — Queries scoped to current user
- `lib/services/travel_preset_service.dart` — Queries scoped to current user
- `lib/screens/setup_screen.dart` — Updated for post-auth DB verification
- `lib/screens/home_screen.dart` — Logout button in app bar
