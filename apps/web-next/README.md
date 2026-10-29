# ChronoWarden web client (React)

The rewrite of the Flutter web client. See
[`docs/UI_REWRITE_PLAN.md`](../../docs/UI_REWRITE_PLAN.md) for the plan and the
agreed stack.

The Flutter client still lives at `apps/web` and keeps working; this one is
built alongside it and becomes `apps/web` at cutover.

## Requirements

- **Node 26 LTS** (see `.nvmrc`) — older Node lines have known security issues.

## Scripts

```bash
npm install
npm run dev        # Vite dev server on :5173 (proxies /api to :8080)
npm run build      # typecheck + production build to dist/
npm test           # Vitest
npm run typecheck  # tsc --noEmit
```

## Progress

- **Foundation** — Vite + React 19 + TypeScript + Tailwind; Node 26 pinned.
- **Crypto** — `src/lib/crypto.ts` is a byte-for-byte port of the Dart
  `CryptoService` (PBKDF2 310k, AES-256-GCM, envelope wrap, BIP39 recovery
  phrase). Verified against golden fixtures the Dart client generated
  (`src/lib/__fixtures__/crypto-golden.json`), so it can read existing data.
  Recovery phrases now use the **official BIP39 wordlist** (`@scure/bip39`);
  the DEK/envelope/passphrase are unchanged.
- Next: API client + httpOnly cookie auth, auth screens, domain-logic port.
