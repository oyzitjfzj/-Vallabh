#!/usr/bin/env bash
set -euo pipefail

input="${TARGET_SHA_INPUT:-}"
file="${VERIFY_TARGET_FILE:-.ci/verification-target}"

if [[ -n "$input" ]]; then
  target="$input"
elif [[ -f "$file" ]]; then
  IFS= read -r target < "$file"
else
  echo "VERIFY_TARGET_MISSING" >&2
  exit 69
fi

scripts/validate-input.sh "$target"
printf '%s\n' "$target"
