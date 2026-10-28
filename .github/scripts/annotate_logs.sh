#!/usr/bin/env bash
# Turns analyze/test/flavorizr logs into GitHub error annotations (readable
# from the run page and the API without downloading logs).
set -uo pipefail
dir=${1:?project dir}
emit() { # title text
  local text=$2 chunk i=0
  while [ -n "$text" ] && [ $i -lt 8 ]; do
    chunk=${text:0:3500}; text=${text:3500}; i=$((i + 1))
    chunk=${chunk//'%'/'%25'}; chunk=${chunk//$'\r'/}; chunk=${chunk//$'\n'/'%0A'}
    echo "::error title=$1 ($i)::$chunk"
  done
}
for f in "$dir"/*/analyze.log; do [ -f "$f" ] && emit "analyze" "$(grep -E ' • ' "$f" | head -60)"; done
for f in "$dir"/*/test.log; do
  [ -f "$f" ] && emit "tests" "$(grep -E -B2 -A25 '\[E\]|EXCEPTION CAUGHT|Expected:|Some tests failed' "$f" | head -150)"
done
for f in "$dir"/*/flavorizr.log; do [ -f "$f" ] && emit "flavorizr" "$(tail -40 "$f")"; done
exit 0
