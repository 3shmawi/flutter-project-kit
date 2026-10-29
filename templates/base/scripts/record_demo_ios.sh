#!/usr/bin/env bash
# Records an integration test on an iOS Simulator, with full Liquid Glass
# (the simulator renders with Metal; the Android emulator in CI has no GPU).
# Used by the Demo video workflow on a macOS runner; works on a Mac too.
#   scripts/record_demo_ios.sh <integration_test/file.dart> <out.mp4> [simulator-udid]
# Without a udid it boots the newest available iPhone simulator.
# Uses --dart-define=DEMO=true so `beat()` pauses make the video readable.
set -euo pipefail
cd "$(dirname "$0")/.."
. ./.project-kit.env
test_file=${1:-integration_test/app_test.dart}
out=${2:-build/demo/raw.mp4}
udid=${3:-}
mkdir -p "$(dirname "$out")"

flavor=()
[ "$HAS_FLAVORS" = true ] && flavor=(--flavor "$DEFAULT_ENV")
env_file="env/$DEFAULT_ENV.json"; [ -f "$env_file" ] || env_file=env/example.json

if [ -z "$udid" ]; then
  udid=$(xcrun simctl list devices available -j | jq -r \
    '[.devices | to_entries[] | select(.key | test("iOS")) | .value[] | select(.name | test("^iPhone [0-9]+( Pro)?$"))] | last | .udid')
  [ -n "$udid" ] && [ "$udid" != null ] || { echo "No iPhone simulator found." >&2; exit 1; }
fi
xcrun simctl boot "$udid" 2>/dev/null || true
xcrun simctl bootstatus "$udid" -b >/dev/null
echo "Simulator: $(xcrun simctl list devices -j | jq -r --arg u "$udid" '.devices[][] | select(.udid == $u) | .name') ($udid)"

# Build first so the recording starts at app launch, not at the build.
flutter build ios --simulator --debug ${flavor[@]+"${flavor[@]}"} \
  --dart-define-from-file="$env_file" --dart-define=DEMO=true >/dev/null

xcrun simctl io "$udid" recordVideo --codec=h264 --force "$out" &
recorder=$!
sleep 3
status=0
# 15-minute ceiling so a stuck test can't hold the runner.
flutter test "$test_file" -d "$udid" ${flavor[@]+"${flavor[@]}"} \
  --dart-define-from-file="$env_file" --dart-define=DEMO=true &
test_pid=$!
( sleep 900; kill "$test_pid" 2>/dev/null ) &
watchdog=$!
wait "$test_pid" || status=$?
kill "$watchdog" 2>/dev/null || true
sleep 2
kill -INT "$recorder" 2>/dev/null || true
wait "$recorder" 2>/dev/null || true
echo "Recorded $out (test exit $status)"
exit "$status"
