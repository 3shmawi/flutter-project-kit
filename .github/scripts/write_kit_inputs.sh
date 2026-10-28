#!/usr/bin/env bash
# Writes kit.conf, credentials.env and the answers file for a CI run, from
# repository variables/secrets and workflow inputs (all passed as env vars).
# Values are shell-quoted with %q so nothing in them is ever executed.
set -euo pipefail
out=${1:?output dir}
mkdir -p "$out/creds"
chmod 700 "$out/creds"

q() { printf '%s=%q\n' "$1" "${2:-}"; }

# ---- kit.conf (repository variables) ----
{
  q DEFAULT_ORG "${DEFAULT_ORG:-com.example}"
  q GITHUB_OWNER "${GITHUB_OWNER:-}"
  q DEVELOPER_NAME "${DEVELOPER_NAME:-}"
  q SUPPORT_EMAIL "${SUPPORT_EMAIL:-}"
  q APPLE_TEAM_ID "${APPLE_TEAM_ID:-}"
  q DEFAULT_PRIMARY_COLOR "${DEFAULT_PRIMARY_COLOR:-#4F46E5}"
  q FLUTTER_VERSION "${FLUTTER_VERSION:-}"
  q CODEMAGIC_ASC_INTEGRATION "${CODEMAGIC_ASC_INTEGRATION:-codemagic}"
  q CREDENTIALS_FILE "$out/creds/credentials.env"
} > "$out/kit.conf"

# ---- credentials.env (secrets → temporary files, deleted with the runner) ----
write_file() { # var-with-content path
  if [ -n "${!1:-}" ]; then printf '%s' "${!1}" > "$2"; printf '%s' "$2"; fi
}
keystore=""
if [ -n "${ANDROID_KEYSTORE_BASE64:-}" ]; then
  printf '%s' "$ANDROID_KEYSTORE_BASE64" | base64 --decode > "$out/creds/upload.jks"
  keystore="$out/creds/upload.jks"
fi
{
  q ANDROID_KEYSTORE_PATH "$keystore"
  q ANDROID_KEYSTORE_PASSWORD "${ANDROID_KEYSTORE_PASSWORD:-}"
  q ANDROID_KEY_ALIAS "${ANDROID_KEY_ALIAS:-}"
  q ANDROID_KEY_PASSWORD "${ANDROID_KEY_PASSWORD:-}"
  q PLAY_SERVICE_ACCOUNT_JSON_PATH "$(write_file PLAY_SERVICE_ACCOUNT_JSON "$out/creds/play.json")"
  q APP_STORE_CONNECT_ISSUER_ID "${APP_STORE_CONNECT_ISSUER_ID:-}"
  q APP_STORE_CONNECT_KEY_IDENTIFIER "${APP_STORE_CONNECT_KEY_IDENTIFIER:-}"
  q APP_STORE_CONNECT_PRIVATE_KEY_PATH "$(write_file APP_STORE_CONNECT_PRIVATE_KEY "$out/creds/asc.p8")"
  q CERTIFICATE_PRIVATE_KEY_PATH "$(write_file CERTIFICATE_PRIVATE_KEY "$out/creds/cert_key")"
} > "$out/creds/credentials.env"

# ---- answers (workflow inputs) ----
visibility=public
[ "${IN_CI:-github}" = codemagic ] && visibility=private
{
  q APP_NAME "${IN_APP_NAME:?app name is required}"
  [ -n "${IN_PACKAGE_ID:-}" ] && q PACKAGE_ID "$IN_PACKAGE_ID"
  [ -n "${IN_DESCRIPTION:-}" ] && q DESCRIPTION "$IN_DESCRIPTION"
  q ENVIRONMENTS "${IN_ENVIRONMENTS:-full}"
  q ARCHITECTURE "${IN_ARCHITECTURE:-simple}"
  q STATE "${IN_STATE:-bloc}"
  q MONITORING "${IN_MONITORING:-sentry}"
  q CI "${IN_CI:-github}"
  q VISIBILITY "$visibility"
  [ -n "${IN_PRIMARY_COLOR:-}" ] && q PRIMARY_COLOR "$IN_PRIMARY_COLOR"
  q DEEPLINK_DOMAIN "${IN_DEEPLINK_DOMAIN:-}"
  q CREATE_REPO "${IN_CREATE_REPO:-yes}"
  q OUTPUT_DIR "$out/projects"
} > "$out/answers.env"
mkdir -p "$out/projects"
