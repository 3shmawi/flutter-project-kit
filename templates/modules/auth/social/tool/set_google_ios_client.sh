#!/usr/bin/env bash
# Writes the reversed iOS client id for Google Sign-In into
# ios/Runner/Info.plist (CFBundleURLSchemes), from GOOGLE_IOS_CLIENT_ID in
# env/prod.json (or the env file given). Google sends the user back to the
# app through that URL scheme; without it Google sign-in can't finish on iOS.
#
#   tool/set_google_ios_client.sh [env/prod.json]
#
# The client id is a public identifier (it ships in every app binary).
set -euo pipefail
cd "$(dirname "$0")/.."
env_file=${1:-env/prod.json}
plist=ios/Runner/Info.plist
[ -f "$env_file" ] || { echo "✗ $env_file not found"; exit 1; }
client_id=$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1])).get("GOOGLE_IOS_CLIENT_ID",""))' "$env_file")
case "$client_id" in
  "") echo "✗ GOOGLE_IOS_CLIENT_ID is empty in $env_file (docs/features/auth.md → Google)"; exit 1 ;;
  *.apps.googleusercontent.com) ;;
  *) echo "✗ GOOGLE_IOS_CLIENT_ID should end with .apps.googleusercontent.com"; exit 1 ;;
esac
# 123-abc.apps.googleusercontent.com → com.googleusercontent.apps.123-abc
reversed="com.googleusercontent.apps.${client_id%.apps.googleusercontent.com}"
T_NEW="$reversed" perl -0pi -e 's/com\.googleusercontent\.apps\.[A-Za-z0-9._-]+/$ENV{T_NEW}/g' "$plist"
grep -q "$reversed" "$plist" || { echo "✗ No Google URL scheme found in $plist"; exit 1; }
echo "✓ $plist → $reversed"
