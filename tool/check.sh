#!/usr/bin/env bash
#
# One-command feedback loop: typecheck + tests + build.
#
#   tool/check.sh            # fast loop: API + web
#   tool/check.sh api        # API only (typecheck + unit + integration)
#   tool/check.sh web        # Web client (typecheck + tests + build)
#   tool/check.sh e2e        # browser end-to-end (Playwright; builds the client)
#
# The API integration tests start their own throwaway Postgres (using local
# binaries), or use $TEST_DATABASE_URL when set (e.g. CI).
set -euo pipefail

cd "$(dirname "$0")/.."
ROOT="$PWD"

# Make sure the toolchains are on PATH.
if ! command -v bun >/dev/null 2>&1 && [ -x "$HOME/.bun/bin/bun" ]; then
  export PATH="$HOME/.bun/bin:$PATH"
fi
if [ -x "$HOME/.nodejs/v26.13.0/bin/node" ]; then
  export PATH="$HOME/.nodejs/v26.13.0/bin:$PATH"
fi
if ! command -v bun >/dev/null 2>&1; then
  echo "error: bun is not installed (https://bun.sh)" >&2
  exit 1
fi
if ! command -v node >/dev/null 2>&1; then
  echo "error: Node is not installed (need 26 LTS — see apps/web/.nvmrc)" >&2
  exit 1
fi

TARGET="${1:-all}"
FAILED=0

step() { printf '\n\033[1m==> %s\033[0m\n' "$1"; }
run() { if ! "$@"; then FAILED=1; fi; }

if [ "$TARGET" = "all" ] || [ "$TARGET" = "api" ]; then
  step "API · typecheck"
  run bash -c "cd '$ROOT/apps/api' && bunx tsc --noEmit"

  step "API · unit tests"
  run bash -c "cd '$ROOT/apps/api' && bun test test/unit"

  step "API · integration tests (throwaway Postgres)"
  run bash -c "cd '$ROOT/apps/api' && bun test test/integration"
fi

if [ "$TARGET" = "all" ] || [ "$TARGET" = "web" ]; then
  step "Web · typecheck"
  run bash -c "cd '$ROOT/apps/web' && npm run typecheck"

  step "Web · tests"
  run bash -c "cd '$ROOT/apps/web' && npm test"

  step "Web · build"
  run bash -c "cd '$ROOT/apps/web' && npm run build"
fi

if [ "$TARGET" = "e2e" ]; then
  step "E2E · Playwright (builds the client, starts a throwaway API + Postgres)"
  run bash -c "cd '$ROOT/e2e' && npm install --silent && npx playwright test"
fi

if [ "$FAILED" -ne 0 ]; then
  printf '\n\033[31m✗ checks failed\033[0m\n'
  exit 1
fi
printf '\n\033[32m✓ all checks passed\033[0m\n'
