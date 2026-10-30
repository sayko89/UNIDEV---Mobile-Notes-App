#!/usr/bin/env bash
# Runs a command in CI and, if it fails, turns the relevant part of its output into GitHub
# error annotations, so the reason is visible on the run page (and through the API).
#   tool/ci_run.sh "flutter analyze" flutter analyze
set -uo pipefail
title="$1"; shift
log="$(mktemp)"
"$@" 2>&1 | tee "$log"
status=${PIPESTATUS[0]}
if [ "$status" -ne 0 ]; then
  # Drop test-progress lines (keep the ones that mark a failure) and pub noise.
  grep -v -E '^[0-9]{2}:[0-9]{2} \+[0-9]+.*: (loading|[^[]*$)' "$log" \
    | grep -v -E '^(Downloading packages|Got dependencies|Resolving dependencies|  [a-z_]+ [0-9.]+ \([0-9.]+ available\)|[0-9]+ packages? ha(s|ve) newer|Try `flutter pub outdated`)' \
    | tail -n 150 > "$log.tail"
  # For Flutter test failures, the first lines of each exception say what went wrong; the
  # stack traces after them are long and mostly noise.
  if grep -q 'EXCEPTION CAUGHT BY' "$log"; then
    awk '/EXCEPTION CAUGHT BY/ {n=28; c++} n>0 && c<=8 {print; n--}' "$log" > "$log.short"
    grep -A6 '^Failing tests:' "$log.tail" >> "$log.short" || true
  else
    mv "$log.tail" "$log.short"
  fi
  # Annotations are cut at about 4 KB, so send the output in chunks (GitHub shows up to 10).
  split -b 3500 -d "$log.short" "$log.part."
  n=0
  for part in "$log".part.*; do
    n=$((n + 1)); [ "$n" -gt 9 ] && break
    body="$(cat "$part")"
    body="${body//'%'/'%25'}"; body="${body//$'\r'/'%0D'}"; body="${body//$'\n'/'%0A'}"
    echo "::error title=${title} failed (${n})::${body}"
  done
fi
exit "$status"
