#!/usr/bin/env bash
set -euo pipefail

resolver="./scripts/resolve-target.sh"
fixture_dir="$(mktemp -d)"
trap 'rm -rf "$fixture_dir"' EXIT

manual_sha="0123456789abcdef0123456789abcdef01234567"
push_sha="89abcdef0123456789abcdef0123456789abcdef"

manual="$(
  GITHUB_EVENT_NAME=workflow_dispatch \
  INPUT_TARGET_SHA="$manual_sha" \
  TARGET_FILE="$fixture_dir/target.sha" \
  "$resolver"
)"
[[ "$manual" == "$manual_sha" ]]

printf '%s\n' "$push_sha" > "$fixture_dir/target.sha"
pushed="$(
  GITHUB_EVENT_NAME=push \
  INPUT_TARGET_SHA="" \
  TARGET_FILE="$fixture_dir/target.sha" \
  "$resolver"
)"
[[ "$pushed" == "$push_sha" ]]

set +e
GITHUB_EVENT_NAME=pull_request INPUT_TARGET_SHA="$manual_sha" TARGET_FILE="$fixture_dir/target.sha" \
  "$resolver" >/dev/null 2>&1
status=$?
set -e
[[ "$status" -ne 0 ]]
