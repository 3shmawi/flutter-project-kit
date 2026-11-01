#!/usr/bin/env bash
# Warns about service keys that are empty in an env file. The app turns a
# service off when its key is empty (no events in PostHog, no errors in
# Sentry), so a build without them looks fine but reports nothing.
#
# Prints key names only, never values. In GitHub Actions each gap is a
# ::warning:: annotation on the run.
#
# Usage: scripts/check_env.sh <env/prod.json> [--strict]
#   --strict  exit 1 when a key is missing (default: warn only)
set -euo pipefail

file=${1:?usage: scripts/check_env.sh <env file> [--strict]}
strict=${2:-}
[ -f "$file" ] || { echo "✗ $file not found"; exit 1; }

problems=$(python3 - "$file" <<'PY'
import json, sys
env = json.load(open(sys.argv[1]))
need = {
    "SUPABASE_URL": "backend",
    "SUPABASE_PUBLISHABLE_KEY": "backend",
    "POSTHOG_API_KEY": "analytics + feature flags",
    "SENTRY_DSN": "crash reporting",
}
for key, what in need.items():
    if not str(env.get(key, "")).strip():
        print(f"{key} is empty: {what} is off in this build")
key = str(env.get("POSTHOG_API_KEY", "")).strip()
if key and not key.startswith("phc_"):
    print("POSTHOG_API_KEY is not a project API key (starts with phc_); "
          "use Project settings -> Project API key, not a personal key")
host = str(env.get("POSTHOG_HOST", "")).strip()
if key and host and not host.startswith("https://"):
    print("POSTHOG_HOST must start with https://")
PY
)

if [ -z "$problems" ]; then
  echo "✓ $file: every service key is set"
  exit 0
fi
while IFS= read -r line; do
  if [ "${GITHUB_ACTIONS:-}" = true ]; then
    echo "::warning title=$file::$line"
  else
    echo "! $file: $line"
  fi
done <<<"$problems"
[ "$strict" = --strict ] && exit 1
exit 0
