# Authentication & User Management

ChronoWarden uses **invite-only registration with local accounts** served by the
self-hosted API. Admins manage users but cannot read their data — each user
operates on an isolated "island", and all data is encrypted client-side.

There is **no email delivery**. Invites are shared out-of-band, and password
resets are admin-assisted.

## Roles & Statuses

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
   "First-time setup" screen.
2. `POST /api/v1/auth/setup` creates the account as `admin` / `approved`, returns
   a session token **and** sets the `cw_session` cookie. It only succeeds while
   no users exist.

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
(wrapped DEK) and shows the **recovery phrase** once on the recovery screen
(`apps/web/src/screens/RecoveryScreen.tsx`). That screen must always appear: it
is the user's only way to recover the DEK if they forget the passphrase.

The first-run E2E test (`e2e/tests/app.spec.ts`) asserts the phrase is shown (24
words) and can be dismissed.

### Login / logout

- `POST /api/v1/auth/login` (`{ email, password }`) verifies the password and
  returns `{ token, user }`, and sets the httpOnly `cw_session` cookie.
- `POST /api/v1/auth/logout` revokes the presented session and clears the cookie.

### Password change / reset

- `PATCH /api/v1/me/password` (`{ currentPassword, newPassword }`) changes the
  password after verifying the current one.
- There is no self-service reset (no email). An admin issues a new temporary
  password out-of-band. The **encryption passphrase is separate and is never
  changed** by a password reset.

### Forgot passphrase

- `apps/web/src/screens/RecoverScreen.tsx` takes the recovery phrase and a new
  encryption passphrase, verifies the phrase by decrypting the settings payload,
  re-wraps the DEK and rewrites `recovery_hash`.

## Sessions & Tokens

- Sessions are opaque 256-bit random tokens. Only the SHA-256 hash is stored, in
  `sessions(token_hash PK, user_id, created_at, expires_at, last_seen_at)`.
- The TTL is sliding: every authenticated request refreshes `expires_at` to
  `now + SESSION_TTL_DAYS` (default 30 days).
- Sessions cascade-delete with the user.
- **Transport:** the React client uses an httpOnly `cw_session` cookie
  (SameSite=Lax, Secure in production). `requireAuth` also accepts
  `Authorization: Bearer <token>` for tooling, and `GET /events` accepts the
  cookie or `?token=`.

### Passwords

- Hashed with **argon2id** via `Bun.password` (19 MiB memory, 2 iterations).
- Minimum length 10 characters (`validatePasswordStrength`).

## Request Scoping (security model)

There is no Row Level Security. The database is not published on the host and is
reachable only by the API container. Every data route resolves the user from the
session (cookie or bearer) and scopes its query to that `user_id`; a `user_id`
supplied by the client is never trusted. Admin routes additionally require
`role = 'admin' AND status = 'approved'` (`requireAdmin` middleware).

## API Reference

| Method & path | Auth | Purpose |
|---|---|---|
| `GET /api/v1/state` | public | whether any user exists |
| `POST /api/v1/auth/setup` | public* | create the first admin (*only if empty) |
| `POST /api/v1/auth/register` | public | register with an invite token |
| `POST /api/v1/auth/login` | public | log in (sets the cookie) |
| `POST /api/v1/auth/logout` | session | revoke the session |
| `GET /api/v1/me` | session | current profile |
| `PATCH /api/v1/me` | session | update `full_name` |
| `PATCH /api/v1/me/password` | session | change password |
| `POST /api/v1/invites/validate` | public | validate an invite token |
| `GET /api/v1/admin/users` | admin | list users |
| `PATCH /api/v1/admin/users/:id` | admin | set `status` / `role` / `full_name` |
| `DELETE /api/v1/admin/users/:id` | admin | delete user (cascades) |
| `GET /api/v1/admin/invites` | admin | list invites |
| `POST /api/v1/admin/invites` | admin | create an invite (returns the token once) |
| `DELETE /api/v1/admin/invites/:id` | admin | delete an invite |

## Client Layer

| File | Purpose |
|------|---------|
| `apps/web/src/api/client.ts` | HTTP transport, cookie credentials, error mapping |
| `apps/web/src/api/auth.ts` | auth + invite endpoints |
| `apps/web/src/state/auth.ts` | bootstrap, login/setup/register, unlock, recovery, DEK lifecycle |
| `apps/web/src/router.tsx` | route guards by auth status |
| `apps/web/src/screens/SetupScreen.tsx` | first-run admin setup |
| `apps/web/src/screens/RegisterScreen.tsx` | invite-based signup |
| `apps/web/src/screens/LoginScreen.tsx` | sign in with optional passphrase |
| `apps/web/src/screens/UnlockScreen.tsx` | unlock on a new device |
| `apps/web/src/screens/RecoveryScreen.tsx` | recovery phrase onboarding |
| `apps/web/src/screens/RecoverScreen.tsx` | forgot-passphrase recovery |
| `apps/web/src/screens/AdminPage.tsx` | user + invite management |

## Key Implementation Notes

1. **No `_ensureProfile` / signup trigger.** The API creates the account and
   profile atomically.
2. **Invite tokens are hashed.** Only the raw token returned at creation can be
   shared; the admin list shows the email, not the token.
3. **Account deletion is real.** `DELETE /admin/users/:id` removes the user and
   cascades to sessions, data and presets.
4. **The envelope is separate from the account.** A password reset never touches
   it. Restoring a backup replaces the envelope and requires the backup's
   passphrase.
