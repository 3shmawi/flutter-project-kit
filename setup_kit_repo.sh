#!/usr/bin/env bash
# One-time: copies your defaults (~/.flutter-kit/kit.conf) into THIS kit
# repo's GitHub variables and stores KIT_GH_TOKEN, so the "Create project"
# workflow can run in the cloud. Re-run whenever a default changes.
#
#   ./setup_kit_repo.sh            variables (+ asks for the token the first time)
#   ./setup_kit_repo.sh --token    replace KIT_GH_TOKEN
#
# Store credentials are NOT stored here: each project's tool/setup_secrets.sh
# uploads them from ~/.app-secrets (and creates that app's Android keystore).
set -euo pipefail
cd "$(dirname "$0")"

KIT_HOME=${FLUTTER_KIT_HOME:-$HOME/.flutter-kit}
CONF=${FLUTTER_KIT_CONFIG:-$KIT_HOME/kit.conf}
command -v gh >/dev/null || { echo "✗ Install the GitHub CLI: brew install gh"; exit 1; }
gh auth status >/dev/null 2>&1 || { echo "✗ Run: gh auth login"; exit 1; }
repo=$(gh repo view --json nameWithOwner --jq .nameWithOwner) || { echo "✗ Run this inside the kit repo clone."; exit 1; }
echo "Configuring $repo"

[ -f "$CONF" ] || { mkdir -p "$KIT_HOME"; cp kit.conf.example "$CONF"; echo "Created $CONF — fill it in, then run this again."; exit 0; }
# shellcheck source=/dev/null
. "$CONF"

# Fall back to values you already keep in ~/.app-secrets/shared.env
shared="${APP_SECRETS_DIR:-$HOME/.app-secrets}"; shared="${shared/#\~/$HOME}/shared.env"
if [ -z "${APPLE_TEAM_ID:-}" ] || [ "${APPLE_TEAM_ID:-}" = "ABCDE12345" ]; then
  [ -f "$shared" ] && APPLE_TEAM_ID=$(sed -n 's/^APPLE_TEAM_ID=//p' "$shared" | tr -d '"' | head -n 1)
fi

# Refuse the example placeholders — they would end up in every new project.
placeholders=""
case "${DEFAULT_ORG:-}" in ""|com.yourname|com.example) placeholders="$placeholders DEFAULT_ORG" ;; esac
case "${DEVELOPER_NAME:-}" in ""|"Your Name") placeholders="$placeholders DEVELOPER_NAME" ;; esac
case "${SUPPORT_EMAIL:-}" in ""|support@example.com) placeholders="$placeholders SUPPORT_EMAIL" ;; esac
case "${GITHUB_OWNER:-}" in your-github-username) placeholders="$placeholders GITHUB_OWNER" ;; esac
if [ -n "$placeholders" ]; then
  echo "✗ Fill these in $CONF first:$placeholders"
  exit 1
fi
[ "${APPLE_TEAM_ID:-}" = "ABCDE12345" ] && APPLE_TEAM_ID=""

echo "Variables"
# GitHub forbids variable names starting with GITHUB_, so the owner is KIT_OWNER.
KIT_OWNER=${GITHUB_OWNER:-}
for name in DEFAULT_ORG KIT_OWNER DEVELOPER_NAME SUPPORT_EMAIL APPLE_TEAM_ID DEFAULT_PRIMARY_COLOR FLUTTER_VERSION CODEMAGIC_ASC_INTEGRATION; do
  value=${!name:-}
  if [ -n "$value" ]; then gh variable set "$name" --body "$value" >/dev/null && echo "  ✓ $name=$value"
  else echo "  – $name (empty)"; fi
done

# Secrets left over from older kit versions (store credentials now live in
# ~/.app-secrets and go to each project, never to the kit repo).
for old in ANDROID_KEYSTORE_BASE64 ANDROID_KEYSTORE_PASSWORD ANDROID_KEY_ALIAS ANDROID_KEY_PASSWORD \
  PLAY_SERVICE_ACCOUNT_JSON APP_STORE_CONNECT_ISSUER_ID APP_STORE_CONNECT_KEY_IDENTIFIER \
  APP_STORE_CONNECT_PRIVATE_KEY CERTIFICATE_PRIVATE_KEY; do
  if gh secret list 2>/dev/null | grep -q "^$old[[:space:]]"; then
    gh secret delete "$old" >/dev/null && echo "  ✓ removed old secret $old"
  fi
done

echo "Secrets"
has_token=false
gh secret list 2>/dev/null | grep -q '^KIT_GH_TOKEN' && has_token=true
if $has_token && [ "${1:-}" != "--token" ]; then
  echo "  ✓ KIT_GH_TOKEN already set (./setup_kit_repo.sh --token to replace it)"
else
  cat <<'MSG'

KIT_GH_TOKEN lets the workflow create repos and enable Pages for you.
Create a classic token (scopes: repo + workflow):
  https://github.com/settings/tokens/new?scopes=repo,workflow&description=flutter-project-kit
MSG
  printf 'Paste the token (hidden): '
  IFS= read -rs token; echo
  if [ -n "$token" ]; then printf '%s' "$token" | gh secret set KIT_GH_TOKEN >/dev/null && echo "  ✓ KIT_GH_TOKEN"
  else echo "  – skipped"; fi
fi

echo
echo "Done. Create a project: GitHub → $repo → Actions → Create project → Run workflow"
echo "  or:  gh workflow run create-project.yml -R $repo -f app_name='My App'"
