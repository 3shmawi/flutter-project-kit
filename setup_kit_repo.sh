#!/usr/bin/env bash
# One-time: copies your defaults and store credentials into THIS kit repo's
# GitHub variables/secrets, so the "Create project" workflow can run in the
# cloud. Re-run whenever a credential or default changes.
#
#   ./setup_kit_repo.sh            reads ~/.flutter-kit/kit.conf + credentials.env
set -euo pipefail
cd "$(dirname "$0")"

KIT_HOME=${FLUTTER_KIT_HOME:-$HOME/.flutter-kit}
CONF=${FLUTTER_KIT_CONFIG:-$KIT_HOME/kit.conf}
command -v gh >/dev/null || { echo "✗ Install the GitHub CLI: brew install gh"; exit 1; }
gh auth status >/dev/null 2>&1 || { echo "✗ Run: gh auth login"; exit 1; }
repo=$(gh repo view --json nameWithOwner --jq .nameWithOwner) || { echo "✗ Run this inside the kit repo clone."; exit 1; }
echo "Configuring $repo"

[ -f "$CONF" ] || { echo "✗ $CONF not found — cp kit.conf.example $CONF and edit it."; exit 1; }
# shellcheck source=/dev/null
. "$CONF"
expand() { case "$1" in "~/"*) printf '%s\n' "$HOME/${1#\~/}" ;; *) printf '%s\n' "$1" ;; esac; }
CRED=$(expand "${CREDENTIALS_FILE:-$KIT_HOME/credentials.env}")

echo "Variables"
for name in DEFAULT_ORG GITHUB_OWNER DEVELOPER_NAME SUPPORT_EMAIL APPLE_TEAM_ID DEFAULT_PRIMARY_COLOR FLUTTER_VERSION CODEMAGIC_ASC_INTEGRATION; do
  value=${!name:-}
  if [ -n "$value" ]; then gh variable set "$name" --body "$value" >/dev/null && echo "  ✓ $name=$value"
  else echo "  – $name (empty)"; fi
done

echo "Secrets"
set_value() { if [ -n "$2" ]; then printf '%s' "$2" | gh secret set "$1" >/dev/null && echo "  ✓ $1"; else echo "  – $1 (empty)"; fi; }
set_file() {
  local path; path=$(expand "${2:-}")
  if [ -n "${2:-}" ] && [ -s "$path" ]; then gh secret set "$1" < "$path" >/dev/null && echo "  ✓ $1"
  else echo "  – $1 (file '${2:-}' not found)"; fi
}
set_b64() {
  local path; path=$(expand "${2:-}")
  if [ -n "${2:-}" ] && [ -s "$path" ]; then base64 < "$path" | tr -d '\n' | gh secret set "$1" >/dev/null && echo "  ✓ $1"
  else echo "  – $1 (file '${2:-}' not found)"; fi
}

if [ -f "$CRED" ]; then
  # shellcheck source=/dev/null
  . "$CRED"
  set_b64   ANDROID_KEYSTORE_BASE64 "${ANDROID_KEYSTORE_PATH:-}"
  set_value ANDROID_KEYSTORE_PASSWORD "${ANDROID_KEYSTORE_PASSWORD:-}"
  set_value ANDROID_KEY_ALIAS "${ANDROID_KEY_ALIAS:-}"
  set_value ANDROID_KEY_PASSWORD "${ANDROID_KEY_PASSWORD:-}"
  set_file  PLAY_SERVICE_ACCOUNT_JSON "${PLAY_SERVICE_ACCOUNT_JSON_PATH:-}"
  set_value APP_STORE_CONNECT_ISSUER_ID "${APP_STORE_CONNECT_ISSUER_ID:-}"
  set_value APP_STORE_CONNECT_KEY_IDENTIFIER "${APP_STORE_CONNECT_KEY_IDENTIFIER:-}"
  set_file  APP_STORE_CONNECT_PRIVATE_KEY "${APP_STORE_CONNECT_PRIVATE_KEY_PATH:-}"
  set_file  CERTIFICATE_PRIVATE_KEY "${CERTIFICATE_PRIVATE_KEY_PATH:-}"
else
  echo "  – $CRED not found: store credentials skipped (projects will be created without CI secrets)"
fi

if gh secret list | grep -q '^KIT_GH_TOKEN'; then
  echo "  ✓ KIT_GH_TOKEN already set (re-run with --token to replace it)"
fi
if [ "${1:-}" = "--token" ] || ! gh secret list | grep -q '^KIT_GH_TOKEN'; then
  cat <<'MSG'

KIT_GH_TOKEN lets the workflow create repos for you. Create a token at
  https://github.com/settings/tokens/new?scopes=repo,workflow&description=flutter-project-kit
(classic token, scopes: repo + workflow, expiry of your choice), then paste it.
MSG
  printf 'Token (input hidden): '
  IFS= read -rs token; echo
  [ -n "$token" ] && printf '%s' "$token" | gh secret set KIT_GH_TOKEN >/dev/null && echo "  ✓ KIT_GH_TOKEN"
fi

echo
echo "Done. Create a project: GitHub → $repo → Actions → Create project → Run workflow"
echo "  or from the terminal:  gh workflow run create-project.yml -f app_name='My App'"
