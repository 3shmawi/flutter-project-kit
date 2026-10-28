#!/usr/bin/env bash
# Uploads your store credentials (kept on your machine) to this repo's
# GitHub Actions secrets. Safe to re-run any time.
#
# Reads ~/.flutter-kit/credentials.env (override with FLUTTER_KIT_CREDENTIALS).
set -euo pipefail
cd "$(dirname "$0")/.."

CRED_FILE=${FLUTTER_KIT_CREDENTIALS:-$HOME/.flutter-kit/credentials.env}
[ -f "$CRED_FILE" ] || { echo "✗ $CRED_FILE not found — copy credentials.env.example from the kit and fill it."; exit 1; }
command -v gh >/dev/null || { echo "✗ GitHub CLI (gh) is required."; exit 1; }
# shellcheck source=/dev/null
. "$CRED_FILE"

expand() { case "$1" in "~/"*) printf '%s\n' "$HOME/${1#\~/}" ;; *) printf '%s\n' "$1" ;; esac; }
missing=0

secret_value() { # name value
  if [ -z "$2" ]; then echo "  – $1 (empty, skipped)"; missing=1; return 0; fi
  printf '%s' "$2" | gh secret set "$1" >/dev/null && echo "  ✓ $1"
}
secret_file() { # name path
  local path; path=$(expand "$2")
  if [ -z "$2" ] || [ ! -f "$path" ]; then echo "  – $1 (file '$2' not found, skipped)"; missing=1; return 0; fi
  gh secret set "$1" < "$path" >/dev/null && echo "  ✓ $1"
}
secret_base64() { # name path
  local path; path=$(expand "$2")
  if [ -z "$2" ] || [ ! -f "$path" ]; then echo "  – $1 (file '$2' not found, skipped)"; missing=1; return 0; fi
  base64 < "$path" | tr -d '\n' | gh secret set "$1" >/dev/null && echo "  ✓ $1"
}

echo "Android"
secret_base64 ANDROID_KEYSTORE_BASE64 "${ANDROID_KEYSTORE_PATH:-}"
secret_value  ANDROID_KEYSTORE_PASSWORD "${ANDROID_KEYSTORE_PASSWORD:-}"
secret_value  ANDROID_KEY_ALIAS "${ANDROID_KEY_ALIAS:-}"
secret_value  ANDROID_KEY_PASSWORD "${ANDROID_KEY_PASSWORD:-}"
secret_file   PLAY_SERVICE_ACCOUNT_JSON "${PLAY_SERVICE_ACCOUNT_JSON_PATH:-}"

echo "iOS"
secret_value  APP_STORE_CONNECT_ISSUER_ID "${APP_STORE_CONNECT_ISSUER_ID:-}"
secret_value  APP_STORE_CONNECT_KEY_IDENTIFIER "${APP_STORE_CONNECT_KEY_IDENTIFIER:-}"
secret_file   APP_STORE_CONNECT_PRIVATE_KEY "${APP_STORE_CONNECT_PRIVATE_KEY_PATH:-}"
secret_file   CERTIFICATE_PRIVATE_KEY "${CERTIFICATE_PRIVATE_KEY_PATH:-}"

echo "App environment"
if [ -f env/prod.json ]; then secret_file ENV_PROD_JSON env/prod.json; else echo "  – ENV_PROD_JSON (env/prod.json missing)"; fi

# Release behaviour (repository variables, change any time in Settings → Variables)
gh variable list 2>/dev/null | grep -q '^PLAY_TRACK' || gh variable set PLAY_TRACK --body internal >/dev/null
gh variable list 2>/dev/null | grep -q '^PLAY_RELEASE_STATUS' || gh variable set PLAY_RELEASE_STATUS --body draft >/dev/null
echo "  ✓ variables PLAY_TRACK=internal, PLAY_RELEASE_STATUS=draft (set to 'completed' after Google reviews the app once)"

[ "$missing" -eq 0 ] || echo "Some values were skipped — fill them in $CRED_FILE and run this again."
