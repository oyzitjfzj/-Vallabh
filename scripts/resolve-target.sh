#!/usr/bin/env bash
set -euo pipefail

event="${GITHUB_EVENT_NAME:-}"
input_sha="${INPUT_TARGET_SHA:-}"
target_file="${TARGET_FILE:-verification-target.sha}"

case "$event" in
  workflow_dispatch)
    candidate="$input_sha"
    ;;
  push)
    if [[ ! -f "$target_file" ]]; then
      echo "VERIFY_TARGET_FILE_MISSING" >&2
      exit 74
    fi
    candidate="$(tr -d '[:space:]' < "$target_file")"
    ;;
  *)
    echo "VERIFY_TRIGGER_UNTRUSTED" >&2
    exit 75
    ;;
esac

scripts/validate-input.sh "$candidate"
printf '%s\n' "$candidate"
