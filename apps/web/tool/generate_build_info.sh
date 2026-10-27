#!/usr/bin/env bash
#
# Generate build metadata so the running app can detect newly deployed builds.
#
# Writes two identical JSON files:
#   build_info.json   — baked into the app as a Flutter asset (the app's own id)
#   web/version.json  — served by nginx at /version.json (the server's id)
#
# The app compares the two commits and prompts the user to reload when they
# differ. Re-run as part of the release routine — see the "Version Check"
# section in AGENTS.md. The Dockerfile also runs it during the image build.
#
# Usage:
#   tool/generate_build_info.sh
set -euo pipefail

cd "$(dirname "$0")/.."

# A short commit id; "dev" when git metadata is unavailable.
if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  COMMIT="$(git rev-parse --short HEAD)"
else
  COMMIT="dev"
fi

# Version from the first `version:` line in pubspec.yaml, minus the build
# number ("0.1.0+1" -> "0.1.0").
VERSION="$(
  grep -E '^version:' pubspec.yaml |
    head -1 |
    sed -E 's/^version:[[:space:]]*//; s/\+.*$//'
)"
VERSION="${VERSION:-unknown}"

BUILT_AT="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

JSON="$(
  cat <<EOF
{
  "version": "$VERSION",
  "commit": "$COMMIT",
  "built_at": "$BUILT_AT"
}
EOF
)"

mkdir -p web

printf '%s\n' "$JSON" >build_info.json
chmod 644 build_info.json

printf '%s\n' "$JSON" >web/version.json
chmod 644 web/version.json

echo "Wrote build_info.json + web/version.json (version $VERSION, commit $COMMIT)."
