#!/usr/bin/env bash
# Uploads the obfuscation symbols of the last release build to Sentry, so
# crash stack traces stay readable. Needs SENTRY_AUTH_TOKEN, SENTRY_ORG and
# SENTRY_PROJECT (secrets set by tool/setup_secrets.sh). Skips quietly when
# Sentry isn't used or not configured.
set -euo pipefail
cd "$(dirname "$0")/.."

if ! grep -q '^sentry:' pubspec.yaml; then
  echo "Sentry isn't used in this project — symbols kept as a CI artifact only."
  exit 0
fi
if [ -z "${SENTRY_AUTH_TOKEN:-}" ] || [ -z "${SENTRY_ORG:-}" ] || [ -z "${SENTRY_PROJECT:-}" ]; then
  echo "::warning::SENTRY_AUTH_TOKEN / SENTRY_ORG / SENTRY_PROJECT not set — symbols not uploaded (run tool/setup_secrets.sh)."
  exit 0
fi
dart run sentry_dart_plugin
