# Security Model

This document describes the security posture of ChronoWarden and the
defences in place across the client, API and deployment. It also records the
hardening applied after the project-wide review.

## Threat model

ChronoWarden is a self-hosted, invite-only, zero-knowledge time tracker. The
primary threats are:

1. **Cross-user data access** — one account reading or modifying another's data.
2. **Unauthorised access** — bypassing authentication/authorisation state.
3. **Credential attacks** — brute force / credential stuffing / user enumeration.
4. **Denial of service** — using expensive endpoints, unbounded caches, streams
   or request bodies to exhaust CPU/memory/DB.
5. **Client-side compromise** — XSS reading the cached DEK from `localStorage`.
6. **Transport/session weaknesses** — cookie theft, stale sessions, CSRF.

The server never sees plaintext: only AES-256-GCM ciphertext and the envelope
metadata it cannot unwrap. See [`ENCRYPTION.md`](ENCRYPTION.md).

## Identity & authorisation

- **Passwords** are hashed with argon2id (19 MiB, 2 iterations) via
  `Bun.password`; minimum length 10.
- **Sessions** are 256-bit opaque tokens; only their SHA-256 hash is stored.
  The cookie is `httpOnly`, `SameSite=Lax`, `Secure` in production, `path=/`.
- **Sliding + absolute expiry** — the sliding TTL (`SESSION_TTL_DAYS`, default
  30) is refreshed at most hourly; a hard cap
  (`SESSION_ABSOLUTE_TTL_DAYS`, default 90) bounds a session's total age.
- **Status gate** — `authenticateToken` treats any non-`approved` account as
  unauthenticated, so a disabled/pending user cannot keep using a live session.
  Disabling an account also deletes its sessions immediately.
- **Password change** revokes every other session. **Admin reset** revokes all.
- **Invites** are single-use, email-bound and expire (default 14, max 90 days).
- **Last admin** cannot be demoted or disabled, preventing administrative
  lockout.
- **Origin guard** rejects cookie-authenticated mutations whose `Origin` does
  not match the host (defence-in-depth on top of `SameSite=Lax`).
- **Data scoping** — every user-data query filters on the authenticated
  `user_id` in the route layer. There is no RLS because the API is the only DB
  client; cross-user access is covered by integration tests.

## Rate limiting & DoS resistance

- **API-level fixed-window limiter** (`src/rate-limit.ts`):
  - login: 50/min per client, plus 10 failed attempts / 15 min per account.
  - registration: 30/min per client.
  - invite validation: 60/min per client.
  - initial setup: 10/min per client.
  - SL proxy: 60/min per client.
- **nginx front door** has coarse `limit_req` zones as a backstop for auth and
  general API traffic.
- **Request bodies** are capped at `MAX_BODY_BYTES` (default 8 MiB) both in
  Hono (`bodyLimit`) and `Bun.serve`; nginx also caps at 10 MB.
- **Field lengths** are capped (`encrypted_data`, names, dates, tokens, KDF
  parameters). Dates must be real `YYYY-MM-DD`.
- **Backup import** is capped at 5 000 rows per table and inserts in chunks.
- **SL proxy** bounds its cache (500 entries, 30 s TTL), caps path length,
  rejects control characters and times out upstream calls after 10 s.
- **SSE streams** are capped at 10 per user and 500 total; a slot is freed as
  soon as the client disconnects (page reload / closed tab).
- **Expired sessions and stale invites** are pruned at startup and hourly.

## Client-side

- The DEK is cached in `localStorage` (`cw_dek`) so a reload does not require
  the passphrase. This is a deliberate trade-off: **any XSS is equivalent to
  full data compromise**, so the CSP is strict and there is no
  `dangerouslySetInnerHTML`/`eval` anywhere.
- **CSP** (set by the proxy and exercised by E2E):
  `default-src 'self'; script-src 'self'; style-src 'self' 'unsafe-inline';
  img-src 'self' data: blob:; font-src 'self' data:; connect-src 'self';
  object-src 'none'; base-uri 'self'; frame-ancestors 'none'; form-action 'self';
  worker-src 'self' blob:; manifest-src 'self'`.
- Other headers: HSTS, `X-Content-Type-Options: nosniff`,
  `Referrer-Policy: strict-origin-when-cross-origin`, `X-Frame-Options: DENY`,
  `Permissions-Policy`.
- The API also sends Hono `secureHeaders` on every response.

## Transport & deployment

- TLS terminates at the host reverse proxy; the compose stack publishes only
  the nginx front door port. Postgres/API/web are not exposed on the host.
- `CORS_ORIGIN` may only be a concrete origin; wildcards are rejected.
- Containers should be kept updated and ideally run non-root with a read-only
  root filesystem and `no-new-privileges` (see follow-ups).

## Follow-ups / known gaps

- **Dependency advisories**: production dependencies are clean (`npm audit
  --omit=dev` reports none) and the API (`bun audit`) reports none. The web
  toolchain is current on Vite 8 / Vitest 5 / plugin-react 6 / jsdom 30. The
  remaining advisories are confined to the build-time
  `vite-plugin-pwa` → `workbox-build` transitive chain (deepmerge, ejs, glob,
  minimatch, etc.), which is not shipped in the bundle; clearing them would
  require downgrading `vite-plugin-pwa`, so they are accepted for now.
- **Backups at rest** are unencrypted (`pg_dump` + gzip). They contain emails,
  Argon2 hashes and ciphertext. Restrict host permissions and consider
  encrypting archives.
- **Container hardening**: pin base images by digest and run non-root.
- **Audit logging** of failed logins and admin mutations is not yet implemented.
- The SSE `?token=` fallback can appear in proxy access logs; prefer the cookie
  (the web client always does).

## Verification

Security-relevant behaviour is covered by:

- API integration tests (`apps/api/test/integration/api.test.ts`,
  "security hardening" suite): disabled-account access, session revocation,
  absolute expiry, Origin rejection, security headers, field limits, import
  caps, last-admin guard and rate limiting.
- API unit tests for the rate limiter and SSE subscriber bounds.
- Web unit tests for the crypto port and the i18n guard.
- Playwright E2E, including a test that loads the app under the production CSP
  and asserts there are no CSP violations.
