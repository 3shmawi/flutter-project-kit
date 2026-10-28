#!/usr/bin/env bash
# Writes kit.conf and the answers file for a CI run, from
# repository variables/secrets and workflow inputs (all passed as env vars).
# Values are shell-quoted with %q so nothing in them is ever executed.
set -euo pipefail
out=${1:?output dir}
mkdir -p "$out"

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
} > "$out/kit.conf"

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
