#!/usr/bin/env bash
# shellcheck disable=SC2016 # hostile strings are literal on purpose
# shellcheck source=test/lib.sh
# Smoke tests for action.yml. Usage: bash test/run.sh
. "$(dirname "$0")/lib.sh"

deploy() { # deploy <token> [VAR=value ...]
  local token=$1; shift
  run_step 0 FLARE_TOKEN="$token" FLARE_API_URL="$API/api/webhooks/deploy" \
    DEPLOY_COMMIT_SHA=abc123 DEPLOY_BRANCH="$HOSTILE" DEPLOY_ENVIRONMENT="${ENVIRONMENT-}" "$@"
}

deploy flr_test_token
check "queued deploy exits 0" "$RC" 0
check "queued output" "$(output queued)" true
check "analysis_at output" "$(output analysis_at)" 2026-10-05T12:00:00Z
check "hostile branch sent verbatim" \
  "$(last_request | "$PY" -c 'import json,sys; print(json.load(sys.stdin)["body"]["branch"])')" "$HOSTILE"
check "environment omitted when empty" \
  "$(last_request | "$PY" -c 'import json,sys; print("environment" in json.load(sys.stdin)["body"])')" False

ENVIRONMENT='prod $(id)' deploy flr_test_token
check "environment sent verbatim" \
  "$(last_request | "$PY" -c 'import json,sys; print(json.load(sys.stdin)["body"]["environment"])')" 'prod $(id)'

deploy ""
check "missing token fails" "$RC" 1

deploy bad-token-0000
check "invalid token fails" "$RC" 1
check "invalid token queued=false" "$(output queued)" false

deploy limit-token-000
check "daily cap warns but passes" "$RC" 0
check "daily cap queued=false" "$(output queued)" false

finish
