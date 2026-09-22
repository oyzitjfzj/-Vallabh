#!/usr/bin/env bash
set -euo pipefail

PRIVATE_REPOSITORY="oyzitjfzj/ai-product-web"
TARGET_SHA="${TARGET_SHA:-}"
PRIVATE_READ_TOKEN="${PRIVATE_READ_TOKEN:-}"
DEST="${RUNNER_TEMP:-/tmp}/private-source"
LOG_DIR="${RUNNER_TEMP:-/tmp}/private-verify-logs"
CHECKOUT_LOG="$LOG_DIR/checkout.log"

scripts/validate-input.sh "$TARGET_SHA"

if [[ -z "$PRIVATE_READ_TOKEN" ]]; then
  echo "VERIFY_ACCESS_MISSING_CREDENTIAL" >&2
  exit 65
fi

rm -rf "$DEST"
mkdir -p "$DEST" "$LOG_DIR"
git -C "$DEST" init -q

auth="$(printf 'x-access-token:%s' "$PRIVATE_READ_TOKEN" | base64 | tr -d '\n')"

if ! git -C "$DEST" \
  -c "http.https://github.com/.extraheader=AUTHORIZATION: basic $auth" \
  fetch -q --no-tags --depth=1 \
  "https://github.com/${PRIVATE_REPOSITORY}.git" "$TARGET_SHA" \
  >"$CHECKOUT_LOG" 2>&1; then
  unset auth PRIVATE_READ_TOKEN
  echo "VERIFY_ACCESS_FETCH_FAILED" >&2
  exit 67
fi

if ! git -C "$DEST" checkout -q --detach FETCH_HEAD >>"$CHECKOUT_LOG" 2>&1; then
  unset auth PRIVATE_READ_TOKEN
  echo "VERIFY_CHECKOUT_FAILED" >&2
  exit 68
fi

actual="$(git -C "$DEST" rev-parse HEAD)"
unset auth PRIVATE_READ_TOKEN

if [[ "$actual" != "$TARGET_SHA" ]]; then
  echo "VERIFY_IDENTITY_MISMATCH" >&2
  exit 66
fi

echo "VERIFY_ACCESS_OK"
echo "VERIFY_IDENTITY_OK=$actual"
