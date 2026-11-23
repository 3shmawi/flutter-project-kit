#!/usr/bin/env bash
# Sends a notification to the app's update topics through the FCM HTTP v1
# API: English to `updates_en`, Arabic to `updates_ar` (the app subscribes
# each user to their language, core/push/push.dart).
#
#   scripts/send_push.sh <service-account.json> <firebase-project-id> \
#     <title_en> <body_en> [title_ar] [body_ar] [route]
#
# Called by Actions → Announce update (input *push*). The key file must
# already be masked (scripts/mask_secrets.sh); the token is masked by
# scripts/gcp_token.sh. Needs the role "Firebase Cloud Messaging API Admin"
# (roles/firebasecloudmessaging.admin) on the service account.
set -euo pipefail
key_file=${1:?service-account key file}
project=${2:?Firebase project id}
title_en=${3:?English title}
body_en=${4:-}
title_ar=${5:-$title_en}
body_ar=${6:-$body_en}
route=${7:-/}

token=$(GCP_SCOPE=https://www.googleapis.com/auth/firebase.messaging \
  "$(dirname "$0")/gcp_token.sh" "$key_file")

send() { # topic title body
  local body code out
  out=$(mktemp)
  body=$(jq -n --arg topic "$1" --arg title "$2" --arg text "$3" --arg route "$route" '{
    message: {
      topic: $topic,
      notification: {title: $title, body: $text},
      data: {route: $route},
      android: {priority: "normal"},
      apns: {payload: {aps: {sound: "default"}}}
    }}')
  code=$(curl -sS -o "$out" -w '%{http_code}' -X POST \
    "https://fcm.googleapis.com/v1/projects/$project/messages:send" \
    -H "Authorization: Bearer $token" -H "Content-Type: application/json" -d "$body")
  if [ "$code" = 200 ]; then
    echo "✓ push → $1"
  else
    echo "::error::push to $1 failed (HTTP $code): $(jq -r '.error.message // empty' "$out")"
    rm -f "$out"
    return 1
  fi
  rm -f "$out"
}

send updates_en "$title_en" "$body_en"
send updates_ar "$title_ar" "$body_ar"
