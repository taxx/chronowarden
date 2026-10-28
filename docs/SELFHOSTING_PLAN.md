# ChronoWarden — Self-Hosting Migration Plan

> Status: **implemented** on the `feat/selfhost` branch. The stack now runs as a
> self-hosted Docker Compose deployment with **no Supabase dependency**. This
> document is kept as the design record; see `AGENTS.md` and `README.md` for the
> current architecture, and `AUTH.md` for the auth model.
>
> Deviations from the original plan:
> - Auth uses **opaque session tokens** (hashed in `sessions`) rather than JWTs —
>   simpler for the client and instantly revocable.
> - Registration is **invite-only**: an admin issues an email-bound token and the
>   user sets their own password (mirroring the openmash flow).
> - Cross-device sync is **SSE** published by the API on every write, not a
>   Postgres logical-replication bridge.
> - The SL proxy + response slimming moved into the API
>   (`POST /api/v1/sl/proxy`).
> - Data portability uses a full encrypted **backup bundle** (Settings → Backup
>   & Restore) in addition to the existing CSV import/export.

---

## 1. What we depend on today (inventory)

ChronoWarden is a Flutter **web** app talking to Supabase. The client uses a
small slice of Supabase — which is why a replacement is cheap:

| Supabase feature | Where it is used | Notes |
|---|---|---|
| **Postgres (tables)** | `time_logs`, `travel_presets`, `user_settings`, `profiles`, `invites` | Plain CRUD. No joins, no views, no stored procedures beyond RLS helpers. |
| **PostgREST** | `.from(table).select()/.eq()/.order()/.limit()/.single()/.insert()/.update()/.upsert()/.delete()` | ~60 call sites, all hidden behind 8 service classes. |
| **Auth (GoTrue)** | `signInWithPassword`, `signUp`, `signOut`, `currentSession`, `auth.admin.deleteUser` | Admin-invite model. **No email is sent and none will be.** |
| **RLS + `SECURITY DEFINER` helpers** | `is_admin()`, `has_profiles()`, 5 policies | Owner-only scoping; first-admin bootstrap. |
| **Realtime** | `channel('public:time_logs')` + `postgres_changes` filtered by `user_id` | Only used to re-fetch today + balance across devices. |
| **Edge Function `sl-proxy`** | `functions.invoke('sl-proxy')` | CORS proxy + response slimming for SL Journey Planner (Deno/TS, ~230 lines). |
| **Storage** | — | Not used. |
| **Email/SMTP** | — | Not used. Invites are out-of-band tokens. |

**Key insight:** every data payload is already encrypted client-side
(AES-256-GCM, envelope encryption, zero-knowledge). The server only ever sees
ciphertext. That makes swapping the backend a **transport change, not a data
model change** — no re-encryption, no key rotation, and the DEK cache in
`localStorage` stays valid.

Hard dependency: **Dart/Flutter client stays** (rewriting the UI would be a
massive waste). The *backend* is where we are free.

---

## 2. Target architecture

```
                    https://chronowarden.slumpen.com  (host reverse proxy, TLS)
                                        │
                              ┌─────────▼──────────┐
                              │  proxy (nginx)     │   8981:80
                              │  /api/* → api      │
                              │  /*     → web      │
                              └───┬────────────┬───┘
                                  │            │
                    ┌─────────────▼──┐   ┌─────▼──────────────┐
                    │  web (nginx)   │   │  api (Bun + Hono)  │
                    │  Flutter build │   │  REST + SSE + SL   │
                    └────────────────┘   └─────┬──────────────┘
                                               │
                                        ┌──────────────┐
                                        │ postgres:18  │  (volume pgdata)
                                        └──────┬───────┘
                                               │
                                        ┌──────▼───────┐
                                        │  backup      │  pg_dump + retention
                                        └──────────────┘
```

- **Same origin** for app and API (`/api/*`) → **no CORS**, no Dart defines,
  no API keys baked into the JS bundle.
- All writes go through the API, so **Realtime becomes trivial**: the API
  publishes an SSE event to the owning user's open streams on every write.
  No Postgres logical replication, no separate realtime service.
- The `sl-proxy` logic is folded into the API as a route (same-origin, so the
  CORS workaround disappears; the response *slimming* is kept verbatim).

---

## 3. Backend stack decision

Requirements weighting: ~3 users, tiny payloads, no email, one server, KISS,
and **the existing SL slimming logic is TypeScript**.

| Option | Verdict |
|---|---|
| **TypeScript · Bun · Hono · Postgres** | ✅ **Recommended.** `Bun.password` = built-in argon2id (no native deps). Hono = tiny, has `streamSSE`, middleware, runs on Bun/Node/Deno/edge. Existing `sl-proxy` TS ports verbatim. `postgres` (porsager) is a single small dependency. One language for API + proxy. |
| TypeScript · Deno · Hono | Equally good if we prefer to keep the exact runtime of today's `sl-proxy`. Slightly more work for password hashing (needs an npm argon2/bcrypt module). |
| TypeScript · Node · Fastify | Fine, but heavier and slower DX than Bun/Hono for this size. |
| Go · chi + pgx | Great single-binary option, stdlib bcrypt, but no TS reuse and more boilerplate per endpoint. |
| Rust · axum + sqlx | Safest/fastest, but clearly overkill for 3 users and the slowest to write. |
| Dart · shelf | Keeps one language, but smaller ecosystem; we'd rewrite the TS proxy and SSE plumbing by hand for no benefit. |
| PocketBase (single Go binary) | Tempting KISS option (auth + REST + realtime + admin UI built in), but it's SQLite-only, opinionated auth rules, and abandons our existing Postgres/backup tooling. Kept as **fallback** if the custom API grows out of hand. |

**Decision:** TypeScript on **Bun**, **Hono**, **Postgres**, single container.
Rationale: least code, reuses the only non-trivial backend logic we already
have (SL slimming), built-in password hashing, and dead-simple SSE.

> The client remains Flutter/Dart. Only `supabase_flutter` is removed and
> replaced by a ~200-line `ApiClient`.

---

## 4. Data model (self-hosted Postgres)

`profiles` merges into `users` because there is no `auth.users` anymore.
Data tables keep their exact shape (ciphertext columns unchanged), so the
**encrypted rows are byte-for-byte portable** — only the FK target changes.

```sql
-- users — replaces auth.users + profiles
create table users (
  id            uuid primary key default gen_random_uuid(),
  email         text not null unique,
  password_hash text not null,                 -- argon2id
  full_name     text,
  role          text not null default 'user'   check (role   in ('admin','user')),
  status        text not null default 'pending' check (status in ('pending','approved','rejected')),
  created_at    timestamptz not null default now()
);

-- sessions — opaque bearer tokens (sha-256 of token stored, never the token)
create table sessions (
  token_hash   text primary key,
  user_id      uuid not null references users(id) on delete cascade,
  created_at   timestamptz not null default now(),
  expires_at   timestamptz not null,
  last_seen_at timestamptz not null default now()
);

-- invites — unchanged, FK now points at users
create table invites (
  id         uuid primary key default gen_random_uuid(),
  created_by uuid references users(id) on delete set null,
  email      text,
  token      text not null unique,
  used       boolean not null default false,
  expires_at timestamptz,
  created_at timestamptz not null default now()
);

-- unchanged ciphertext tables (encrypted_data stays AES-256-GCM)
create table time_logs      (id uuid pk default gen_random_uuid(), user_id uuid not null references users(id) on delete cascade, date date not null default current_date, encrypted_data text not null default '', created_at timestamptz not null default now());
create table travel_presets (id uuid pk default gen_random_uuid(), user_id uuid not null references users(id) on delete cascade, name text not null, encrypted_data text not null default '', created_at timestamptz not null default now());
create table user_settings  (id uuid pk default gen_random_uuid(), user_id uuid not null unique references users(id) on delete cascade, encrypted_dek text not null default '', kek_salt text not null default '', kek_iterations integer not null default 310000, recovery_hash text, encrypted_data text not null default '', created_at timestamptz not null default now(), updated_at timestamptz default now());
```

**Security posture change:** RLS / `is_admin()` / `has_profiles()` / the
`handle_new_user` trigger are **dropped**. The API is the only client of
Postgres and scopes every query by the authenticated `user_id`. Optionally we
can keep RLS as defence-in-depth using a `SET LOCAL app.user_id` GUC — noted
in §9, not required for v1.

Migrations live as numbered SQL files (`api/migrations/001_init.sql`) applied
by a tiny runner on API startup (idempotent). The Flutter `SetupScreen` /
`supabase_schema.sql` asset becomes obsolete and is retired.

---

## 5. API surface (v1, JSON, `Authorization: Bearer <token>`)

All user-data routes are **implicitly scoped to the authenticated user** —
`user_id` is never accepted from the client (this is what replaces RLS).

| Method & path | Purpose | Replaces |
|---|---|---|
| `GET /api/v1/state` | `{ has_users }` (public) | `has_profiles()` RPC + table probe |
| `POST /api/v1/auth/signup` | create user (+ invite/`isFirstAdmin`), returns `{token,user}` | `auth.signUp` |
| `POST /api/v1/auth/login` | email+password → `{token,user}` | `signInWithPassword` |
| `POST /api/v1/auth/logout` | revoke session | `signOut` |
| `GET /api/v1/me` | current profile | `currentSession` + profile fetch |
| `PATCH /api/v1/auth/password` | change own password | (new; admin-assisted reset) |
| `GET/POST/PATCH/DELETE /api/v1/time-logs[/:id]` | time log CRUD (`?date=`) | `time_logs` queries |
| `GET/POST/PATCH/DELETE /api/v1/travel-presets[/:id]` | preset CRUD | `travel_presets` queries |
| `GET/PATCH /api/v1/settings` | read / merge-upsert the single settings row (envelope **and** `encrypted_data`) | all 9 `user_settings` upserts |
| `GET /api/v1/admin/users` · `PATCH …/:id` · `DELETE …/:id` | list / approve / reject / **hard delete** | `ProfileService` |
| `GET/POST/DELETE /api/v1/admin/invites[/:id]` | invite CRUD | `ProfileService` |
| `GET /api/v1/export` | full JSON backup bundle for the user | (new) |
| `POST /api/v1/import` | atomically restore a bundle | (new) |
| `GET /api/v1/sl/stops?q=` · `GET /api/v1/sl/trips?...` | SL proxy + slimmed response | `sl-proxy` Edge Function |
| `GET /api/v1/events?token=…` | **SSE** stream of `{table,type,row}` for the user | Supabase Realtime |
| `GET /api/health` | compose healthcheck | — |

Notes:
- `auth.admin.deleteUser`'s service-role limitation disappears — admin delete
  is now a normal `DELETE` that cascades (session + data), no orphaned rows.
- Realtime SSE carries `token` as a query param (browsers' `EventSource`
  cannot set headers). Same-origin + HTTPS + short-lived token.
- Rate-limit login/signup (simple in-memory or DB-backed counter) to blunt
  brute force; argon2id makes offline attacks expensive.

---

## 6. Client refactor (Flutter side — the bulk of the work)

Public interfaces stay the same, so **no screen changes are expected** beyond
the two features below.

1. **New `lib/services/api_client.dart`**
   - Base URL: `String.fromEnvironment('API_URL', defaultValue: '/api/v1')`
     (relative by default — same origin).
   - Bearer token persisted via the existing `web_local_storage` facade
     (key `cw_api_token`); non-web falls back to the VM stub for now
     (mobile persistence is a follow-up, see §9).
   - `get/post/patch/delete`, JSON, 401 → clear session and notify
     `AuthService`.
2. **New `lib/services/realtime_service.dart`** — SSE via the
   `web_browser` conditional-import bridge (web `EventSource`, VM stub).
3. **Rewrite data services** (`time_log_service`, `travel_preset_service`,
   `user_settings_service`, `work_config_service`, `transit_service`,
   `migration_service`, `profile_service`) — drop the PostgREST query builder
   in favour of direct `ApiClient` calls. `_userId` now comes from
   `AuthService`, not `client.auth.currentSession`.
4. **`auth_service.dart`** — same public API (`isAuthenticated`, `profile`,
   `signIn`, `signUp`, `signOut`, `needsPassphrase`, …); internals swap to
   `/auth/*` + `/settings`. `checkDatabaseState()` → `GET /state`.
   `_ensureProfile()` and the trigger workaround disappear (the API creates
   the profile atomically).
5. **`app_state.dart`** — replace `RealtimeChannel` with `RealtimeService`;
   `refresh()`'s "tables missing" detection becomes "API unreachable".
6. **`main.dart`** — remove `Supabase.initialize`; `_NoConfigScreen`
   becomes a "backend unavailable" screen.
7. **`pubspec.yaml`** — remove `supabase_flutter`. Remove the
   `supabase_schema.sql` asset; remove Supabase Dart defines from the
   Dockerfile.
8. **`transit_service.dart`** — `_slProxy()` → `ApiClient.get('/sl/...')`
   returning already-slimmed JSON.
9. **Tests** — update `test/widget_test.dart` (no Supabase); add
   `ApiClient` tests with an injectable transport, `AuthService` flow tests
   with a fake API, and a backup bundle round-trip test. All model/crypto/
   localization tests stay untouched.

Realtime semantics stay identical: an SSE event triggers the same
"re-fetch today + re-fetch all + balance" behaviour as today.

---

## 7. Rollout — parallel instance, 3 users, self-service export/import

Your proposed rollout works and is the plan below. One critical caveat first:

> **The encryption envelope must travel with the data.**
> The DEK is randomly generated and wrapped by a KEK derived from the user's
> passphrase. A fresh signup on the new instance generates a **new DEK**, so
> old ciphertext would be undecryptable. The backup bundle therefore includes
> `encrypted_dek`, `kek_salt`, `kek_iterations`, `recovery_hash`, *plus* the
> ciphertext rows. Then the **same passphrase** unwraps the **same DEK** on
> the new instance and history decrypts normally.

### Bundle format (`GET /api/v1/export`)

```json
{
  "format": "chronowarden-backup",
  "version": 1,
  "exported_at": "2026-10-15T18:00:00Z",
  "user": { "email": "a@b.se", "full_name": "…" },
  "envelope": { "encrypted_dek": "…", "kek_salt": "…", "kek_iterations": 310000, "recovery_hash": "…" },
  "settings": { "encrypted_data": "…" },
  "time_logs":      [ { "date": "2026-01-15", "encrypted_data": "…" } ],
  "travel_presets": [ { "name": "Office", "encrypted_data": "…" } ]
}
```

Plaintext stays plaintext (`date`, `name`); everything else is ciphertext.
IDs are omitted — the new server assigns them.

### Phases

**Phase A — Export ships to the *old* instance first.** The export feature must
run on the current Supabase build (it reads Supabase rows). Add
"Settings → Data → Export backup" to the current client, deploy it, and let
users download their bundle. (Admin can also run this server-side for all
three users using `.env.db`.)

**Phase B — New stack deployed to a parallel port** (e.g. `8982`) with a fresh
Postgres and no shared data. Smoke test with a throwaway account.

**Phase C — Account creation on the new instance.** No email ⇒ the admin
either creates accounts via `/auth/signup` with invite tokens, or users
self-signup with a token. Passwords are shared out-of-band; users change them
via `/auth/password`. The **encryption passphrase stays whatever it was** —
it is not an account credential.

**Phase D — Restore.** On the new instance:
`Settings → Data → Restore backup` → `POST /import` stores envelope + ciphertext
→ client prompts for the **old passphrase** → unwraps DEK → verifies against
`recovery_hash` → caches DEK → logs/presets/settings decrypt.
Fallback for users without a bundle: enter their **old recovery phrase**
(`recoverAndSetNewPassphrase` already supports re-wrapping the old DEK).

**Phase E — Verify & cut over.** Compare day counts, work config, presets and
transit settings between instances. Point the domain / swap ports `8981 ↔ 8982`.
Leave the old Supabase project **read-only** for 30 days, take a final
`pg_dump` archive, then decommission and cancel.

> **Shortcut (M1)** — for three users the owner can skip user export entirely:
> dump `time_logs`, `travel_presets`, `user_settings` from the Supabase
> Postgres, recreate the three `users` rows with the **same UUIDs**, and copy
> the ciphertext verbatim. Zero user action, same result. The plan supports
> both; M2 (self-service) is the primary because it also gives users a
> portable backup feature going forward.

### Compose sketch

```yaml
services:
  proxy:                     # front door, keeps host TLS proxy untouched
    image: nginx:alpine
    volumes: [ ./src/deploy/proxy.conf:/etc/nginx/conf.d/default.conf:ro ]
    ports: [ "8981:80" ]
    depends_on: [ web, api ]

  web:                       # Flutter build (no Supabase build args anymore)
    build: { context: ./src }
    restart: unless-stopped

  api:
    build: { context: ./src/api }        # oven/bun alpine, Hono server
    env_file: [ .env ]                   # DATABASE_URL, SESSION_TTL_DAYS
    depends_on: [ db ]
    restart: unless-stopped

  db:
    image: postgres:18-alpine            # current major; pin minor via tag if desired
    env_file: [ .env.db ]                # POSTGRES_PASSWORD, POSTGRES_DB
    volumes: [ pgdata:/var/lib/postgresql/data ]
    restart: unless-stopped

  backup:                    # existing backup container, repointed at db
    build: { context: ./src/backup }
    env_file: [ .env.db ]
    restart: unless-stopped

volumes: { pgdata: {} }
```

`.env` loses `SUPABASE_URL` / `SUPABASE_ANON_KEY` and gains
`DATABASE_URL=postgres://chronowarden:…@db:5432/chronowarden`.
`secrets.json` / `--dart-define-from-file` and the Dockerfile build args are
removed — one less secret baked into the web bundle.

---

## 8. Work breakdown & effort (rough)

| Phase | Deliverable | Est. |
|---|---|---|
| 0 | Decisions + spike (Hono health/state/login against local Postgres, proxy wiring) | 0.5–1 d |
| 1 | Postgres schema + migration runner; auth (signup/login/logout/me/password), sessions, invites, admin users; CRUD for logs/presets/settings; `/state` | 2–3 d |
| 2 | SSE pub/sub on writes; SL proxy route (port + keep slimming) | 1 d |
| 3 | Flutter `ApiClient` + rewrite 8 services + `AuthService` + `AppState` realtime; remove `supabase_flutter`; green analyze + tests | 2–3 d |
| 4 | Export (old client) + import (new client) + bundle round-trip tests + Settings UI | 1–1.5 d |
| 5 | Parallel deploy, smoke tests, account setup, data restore, verification | 0.5–1 d |
| 6 | Cutover, 30-day retention, final archive | 0.5 d |
| 7 | Docs (README/AGENTS/AUTH), remove `sl-proxy` edge function & Supabase artifacts | 0.5–1 d |

**Total ≈ 8–12 dev-days.**

---

## 9. Risks & mitigations

| Risk | Mitigation |
|---|---|
| Envelope lost ⇒ old data undecryptable | Bundle always includes envelope fields; verified by unwrapping + `recovery_hash` check *during* restore, before accepting data. Keep old instance read-only for 30 days. |
| Auth security regressions (hashing, token storage) | argon2id (`Bun.password`), store only SHA-256 of session tokens, random 256-bit tokens, expiry + revocation, login rate limiting. Unit tests for auth flows. |
| SSE reconnection / mobile browsers | `EventSource` auto-reconnects; re-fetch on reconnect. `AppLifecycleState.resumed` refresh already exists in `MyDayTab`. Verify on iOS Safari. |
| No email ⇒ password reset | Documented flow: admin sets a temporary password (`PATCH /admin/users/:id` or a reset route) shared out-of-band; users change via `/auth/password`. Encryption/data recovery stays via recovery phrase. |
| Postgres not publicly reachable | `db` service is on the compose network only (no `ports:`), API is the sole client. Optionally add RLS with `SET LOCAL app.user_id` as defence-in-depth. |
| Flutter mobile persistence (`localStorage` is web-only) | `web_local_storage` has a VM stub; token would not persist on Android/iOS. In scope only if mobile builds are real targets — then add a `shared_preferences`-backed storage impl. |
| SL API shape changes / slimming port bugs | Keep `sl-proxy/index.ts` as the reference; port tests: feed the three recorded samples in `api-specifications/sl-journey-planner/` through the Dart/TS slim function and assert the slimmed output. |
| Two clients during rollout (old export / new import) | Bundle versioned (`format`/`version`); shared parser fixtures. Alternatively use the M1 direct DB copy and skip the dual-client window. |
| Data volume / backup | Existing `backup` container just repoints; `pgdata` volume added to server layout and backup docs. |

---

## 10. Rollback

- Keep the old Supabase instance and its project alive until after cutover
  validation. Rollback = point the domain back and/or redeploy the previous
  Flutter build (`git revert` the client commit) — the Supabase backend is
  untouched by the migration.
- Because envelopes and ciphertext are server-agnostic, a user can be moved
  back and forth between instances without data loss, as long as they keep the
  passphrase/recovery phrase.
- Rollback of the backend alone: stop `db`/`api`, restore `8981` to `web`
  directly; no data migration is needed to return.

---

## 11. Open questions

1. **Runtime:** Bun vs Deno for the TS API (both reuse the existing Deno
   `sl-proxy` logic; Bun has built-in argon2id). *Default: Bun.*
2. **Rollout style:** M2 self-service export/import (your preference) or M1
   direct DB copy with preserved UUIDs (zero user effort). *Default: M2 with
   M1 as an admin fallback.*
3. **Front door:** add the small `proxy` container (recommended) or fold the
   `/api` `proxy_pass` into the existing Flutter `web` nginx config (fewer
   containers, more coupling).
4. **Client scope:** web-only (leave the VM `localStorage` stub as-is) or add
   mobile token persistence now?
5. **Defence-in-depth RLS:** keep Postgres RLS behind a `SET LOCAL app.user_id`
   GUC, or rely solely on API-side scoping?
6. **Old instance lifetime:** 30 days read-only before cancelling Supabase —
   confirm that window.
