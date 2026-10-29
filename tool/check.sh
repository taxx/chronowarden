#!/usr/bin/env bash
#
# One-command feedback loop: typecheck + tests for the API and the web client.
#
#   tool/check.sh            # fast loop: API + web + web-next
#   tool/check.sh api        # API only (typecheck + unit + integration)
#   tool/check.sh web        # Flutter web only (analyze + tests)
#   tool/check.sh web-next   # React client (typecheck + tests + build)
#   tool/check.sh e2e        # Flutter browser end-to-end (Playwright)
#   tool/check.sh e2e-next   # React browser end-to-end (builds apps/web-next)
#
# `e2e` is intentionally not part of the default run: it builds the Flutter web
# bundle and drives a real browser, so it is slower. Run it before merging/
# deploying.
#
# The API integration tests start their own throwaway Postgres (using local
# binaries), or use $TEST_DATABASE_URL when set (e.g. CI).
set -euo pipefail

cd "$(dirname "$0")/.."
ROOT="$PWD"

# Make sure bun is on PATH (installed via https://bun.sh).
if ! command -v bun >/dev/null 2>&1 && [ -x "$HOME/.bun/bin/bun" ]; then
  export PATH="$HOME/.bun/bin:$PATH"
fi
if ! command -v bun >/dev/null 2>&1; then
  echo "error: bun is not installed (https://bun.sh)" >&2
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
  step "Web · flutter analyze"
  run bash -c "cd '$ROOT/apps/web' && flutter analyze"

  step "Web · flutter test"
  run bash -c "cd '$ROOT/apps/web' && flutter test"
fi

if [ "$TARGET" = "all" ] || [ "$TARGET" = "web-next" ]; then
  # The React client needs Node 26 LTS (see apps/web-next/.nvmrc).
  if [ -x "$HOME/.nodejs/v26.13.0/bin/node" ]; then
    export PATH="$HOME/.nodejs/v26.13.0/bin:$PATH"
  fi

  step "Web-next · typecheck"
  run bash -c "cd '$ROOT/apps/web-next' && npm run typecheck"

  step "Web-next · tests"
  run bash -c "cd '$ROOT/apps/web-next' && npm test"

  step "Web-next · build"
  run bash -c "cd '$ROOT/apps/web-next' && npm run build"
fi

if [ "$TARGET" = "e2e" ]; then
  step "E2E · Playwright (builds the web app, starts a throwaway API + Postgres)"
  run bash -c "cd '$ROOT/e2e' && npm install --silent && npx playwright test"
fi

if [ "$TARGET" = "e2e-next" ]; then
  if [ -x "$HOME/.nodejs/v26.13.0/bin/node" ]; then
    export PATH="$HOME/.nodejs/v26.13.0/bin:$PATH"
  fi
  step "E2E-next · Playwright (builds the React client, throwaway API + Postgres)"
  run bash -c "cd '$ROOT/e2e-next' && npm install --silent && npx playwright test"
fi

if [ "$FAILED" -ne 0 ]; then
  printf '\n\033[31m✗ checks failed\033[0m\n'
  exit 1
fi
printf '\n\033[32m✓ all checks passed\033[0m\n'
