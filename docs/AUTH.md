# Authentication & User Management

ChronoWarden uses **invite-only registration with local accounts** served by the
self-hosted API. Admins manage users but cannot read their data — each user
operates on an isolated "island", and all data is encrypted client-side.

There is **no email delivery**. Invites are shared out-of-band, and password
resets are admin-assisted.

## Roles & Statuses

The `users` table holds both the account and the profile (there is no separate
`auth.users`).

| Role    | Status     | Meaning                                                          |
|---------|------------|------------------------------------------------------------------|
| `admin` | `approved` | Manages users and invites. Sees only own data.                   |
| `user`  | `approved` | Regular user. Invite registration is approved immediately.       |
| `user`  | `pending`  | Reserved — the current invite flow grants access immediately.    |
| `user`  | `rejected` | Disabled. Login is refused.                                      |

| Column | Type | Notes |
|--------|------|-------|
| `id` | `uuid PK` | |
| `email` | `text unique` | normalized to lowercase |
| `password_hash` | `text` | argon2id |
| `full_name` | `text` | |
| `role` | `text check ('admin','user')` | |
| `status` | `text check ('pending','approved','rejected')` | |
| `created_at` / `updated_at` | `timestamptz` | |

## Auth Flows

### First admin (empty database)

1. The client calls `GET /api/v1/state` → `{ has_users: false }` and shows the
   "Create Admin" screen.
2. `POST /api/v1/auth/setup` creates the account as `admin` / `approved` and
   returns a session token. It only succeeds while no users exist.

### Regular users (invite-only)

1. An admin issues an invite with `POST /api/v1/admin/invites`
   (`{ email, role?, ttlDays? }`). The server stores only the SHA-256 hash of the
   token and returns the raw token **once** for the admin to share.
2. The user opens the signup screen and enters the token.
   `POST /api/v1/invites/validate` confirms it and returns the bound email, which
   the client prefills.
3. `POST /api/v1/auth/register`
   (`{ email, password, fullName, inviteToken }`) creates the account with the
   invite's role, marks the invite used, and returns a session token.

Invites are single-use and expire (default 14 days, maximum 90). Creating a new
invite for an email replaces any unused invite for that address.

### Encryption setup at signup

Immediately after `setup`/`register`, the client creates the encryption envelope
(wrapped DEK) and shows the **recovery phrase** once on
`RecoveryOnboardingScreen` (`apps/web/lib/screens/recovery_onboarding_screen.dart`).
That screen must always appear: it is the user's only way to recover the DEK if
they forget the passphrase.

Two regressions used to hide it, both now fixed and guarded by the first-run E2E
test (`e2e/tests/app.spec.ts`):

1. `main.dart` rebuilt the unauthenticated screen's `checkDatabaseState()`
   future, so the signup screen was unmounted mid-flow and never pushed the
   onboarding route. The future is now cached (reset only on sign-out).
2. The onboarding was pushed with `pushReplacement`, making it the first route,
   so "Continue to App" could never dismiss it. It is now pushed on top of the
   shell.

### Login / logout

- `POST /api/v1/auth/login` (`{ email, password }`) verifies the password and
  returns `{ token, user }`. The same message is returned for an unknown user and
  a wrong password.
- `POST /api/v1/auth/logout` revokes the presented session.

### Password change / reset

- `PATCH /api/v1/me/password` (`{ currentPassword, newPassword }`) changes the
  password after verifying the current one.
- There is no self-service reset (no email). An admin issues a new temporary
  password out-of-band. The **encryption passphrase is separate and is never
  changed** by a password reset.

## Sessions & Tokens

- Sessions are opaque 256-bit random tokens. Only the SHA-256 hash is stored, in
  `sessions(token_hash PK, user_id, created_at, expires_at, last_seen_at)`.
- The TTL is sliding: every authenticated request refreshes `expires_at` to
  `now + SESSION_TTL_DAYS` (default 30 days) and updates `last_seen_at`.
- Sessions cascade-delete with the user.
- The client caches the raw token in `localStorage` (`cw_api_token`) and sends it
  as `Authorization: Bearer <token>`; `ApiClient` clears it on a 401.

### Passwords

- Hashed with **argon2id** via `Bun.password` (19 MiB memory, 2 iterations).
- Minimum length 10 characters (`validatePasswordStrength`).

## Request Scoping (security model)

There is no Row Level Security. The database is not published on the host and is
reachable only by the API container. Every data route resolves the user from the
bearer token and scopes its query to that `user_id`; a `user_id` supplied by the
client is never trusted. Admin routes additionally require
`role = 'admin' AND status = 'approved'` (`requireAdmin` middleware).

## API Reference

| Method & path | Auth | Purpose |
|---|---|---|
| `GET /api/v1/state` | public | whether any user exists |
| `POST /api/v1/auth/setup` | public* | create the first admin (*only if empty) |
| `POST /api/v1/auth/register` | public | register with an invite token |
| `POST /api/v1/auth/login` | public | log in |
| `POST /api/v1/auth/logout` | bearer | revoke the session |
| `GET /api/v1/me` | bearer | current profile |
| `PATCH /api/v1/me` | bearer | update `full_name` |
| `PATCH /api/v1/me/password` | bearer | change password |
| `POST /api/v1/invites/validate` | public | validate an invite token |
| `GET /api/v1/admin/users` | admin | list users |
| `PATCH /api/v1/admin/users/:id` | admin | set `status` / `role` / `full_name` |
| `DELETE /api/v1/admin/users/:id` | admin | delete user (cascades) |
| `GET /api/v1/admin/invites` | admin | list invites |
| `POST /api/v1/admin/invites` | admin | create an invite (returns the token once) |
| `DELETE /api/v1/admin/invites/:id` | admin | delete an invite |

## Dart Layer

| File | Purpose |
|------|---------|
| `apps/web/lib/services/api_client.dart` | HTTP transport, bearer token, error mapping |
| `apps/web/lib/services/auth_service.dart` | sign in/up/out, session init, DEK lifecycle, invite validation |
| `apps/web/lib/services/profile_service.dart` | admin user + invite management |
| `apps/web/lib/models/user_profile.dart` | profile model (`role`, `status`) |
| `apps/web/lib/models/invite.dart` | invite model (token only present on creation) |
| `apps/web/lib/screens/login_screen.dart` | login with encryption passphrase |
| `apps/web/lib/screens/signup_screen.dart` | invite-based signup + encryption setup |
| `apps/web/lib/screens/pending_screen.dart` | "account pending approval" |
| `apps/web/lib/screens/admin_screen.dart` | user + invite management UI |

## Key Implementation Notes

1. **No `_ensureProfile` / signup trigger.** The API creates the account and
   profile atomically; there is no mirroring workaround.
2. **Invite tokens are hashed.** Only the raw token returned at creation can be
   shared; the admin list shows the email, not the token.
3. **Account deletion is real.** `DELETE /admin/users/:id` removes the user and
   cascades to sessions, data and presets — no orphaned auth rows.
4. **The envelope is separate from the account.** Signing up creates an
   encryption envelope (wrapped DEK) in `user_settings`; a password reset never
   touches it. Restoring a backup replaces the envelope and requires the
   backup's passphrase.
