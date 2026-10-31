# Milestones

Notable checkpoints in ChronoWarden's history. Each one is tagged in git.

## M2 — React UI rewrite · `v0.2.0-react-ui`

The client was rewritten from the Flutter web app (canvas-rendered) to a
React 19 + TypeScript app, feature parity was reached, and the interface was
modernised. The API, database and backups were unchanged; the crypto is a
byte-for-byte port verified against the original's golden fixtures, so existing
envelopes, ciphertext and passphrases keep working.

Highlights:

- **Feature parity** with the Flutter client: My Day, History, Overview
  (week/month/year), Projection analytics, Transit, Settings, Admin.
- **Day editing everywhere** — edit, delete and adjust a day from My Day,
  History and the Overview calendar.
- **Design system** — shadcn-compatible tokens, light/dark/system theming,
  Radix-based dialogs/tabs/switch, toasts, a desktop sidebar + mobile bottom nav.
- **Time-warding colours** — green when you *kept* your time (worked less than
  expected), red when you worked over.
- **Recovery** — official BIP39 phrase with a one-time hash migration.
- **Admin-assisted password reset**, encryption explainer, notifications test,
  CSV format guide, diagnostics and update check.
- **Testing** — Vitest suite + Playwright E2E driving the real DOM.

Tags: `v0.2.0-react-ui`.

## M1 — Self-hosting migration · `v0.1.0-selfhost`

Moved off Supabase to a fully self-hosted stack: Bun + Hono API, PostgreSQL 18,
nginx proxy, daily `pg_dump` backups, invite-only auth with httpOnly cookie
sessions, SSE realtime, and an in-repo SL Journey Planner proxy.
