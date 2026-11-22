#!/usr/bin/env bash
# Creates app_versions/android and app_versions/ios in Firestore when they
# don't exist yet (an existing document is never touched), so the update
# gate has something to read. Called by .github/workflows/firebase.yml.
#
#   scripts/seed_app_versions.sh <service-account.json> <project-id>
set -euo pipefail
cd "$(dirname "$0")/.."
key_file=${1:?service-account key file}
project=${2:?project id}
token=$(./scripts/gcp_token.sh "$key_file")
base="https://firestore.googleapis.com/v1/projects/$project/databases/(default)/documents/app_versions"

seed() { # platform store_url
  local body code
  body=$(jq -n --arg url "$2" '{fields: {
    latest_version: {stringValue: "1.0.0"},
    min_supported_version: {stringValue: "1.0.0"},
    store_url: {stringValue: $url},
    changelog_en: {stringValue: ""},
    changelog_ar: {stringValue: ""}}}')
  # currentDocument.exists=false: create only, fail if it is already there.
  code=$(curl -sS -o /tmp/seed.json -w '%{http_code}' -X PATCH \
    "$base/$1?currentDocument.exists=false" \
    -H "Authorization: Bearer $token" -H 'Content-Type: application/json' -d "$body")
  case "$code" in
    200) echo "✓ app_versions/$1 created (edit store_url / versions in the console or Actions → Announce update)" ;;
    400|409) if grep -q 'FAILED_PRECONDITION\|ALREADY_EXISTS' /tmp/seed.json; then echo "✓ app_versions/$1 already exists"
             else echo "::error::app_versions/$1: HTTP $code $(jq -r '.error.message // empty' /tmp/seed.json)"; return 1; fi ;;
    404) echo "::error::No Firestore database in $project — run tool/setup_secrets.sh (creates it) or create it in the console."; return 1 ;;
    *) echo "::error::app_versions/$1: HTTP $code $(jq -r '.error.message // empty' /tmp/seed.json)"; return 1 ;;
  esac
}
seed android 'https://play.google.com/store/apps/details?id=__PACKAGE_ID__'
seed ios 'https://apps.apple.com/app/idYOUR_APP_ID'
rm -f /tmp/seed.json
