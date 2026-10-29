#!/usr/bin/env bash
# Runs a command in CI and, if it fails, turns the end of its output into a GitHub error
# annotation so the failure reason is visible on the run page (and through the API).
#   tool/ci_run.sh "flutter analyze" flutter analyze
set -uo pipefail
title="$1"; shift
log="$(mktemp)"
"$@" 2>&1 | tee "$log"
status=${PIPESTATUS[0]}
if [ "$status" -ne 0 ]; then
  body="$(tail -n 120 "$log")"
  body="${body//'%'/'%25'}"; body="${body//$'\r'/'%0D'}"; body="${body//$'\n'/'%0A'}"
  echo "::error title=${title} failed::${body}"
fi
exit "$status"
