#!/usr/bin/env bash
set -euo pipefail

validator="${1:-./scripts/validate-input.sh}"

expect_ok() {
  "$validator" "$1" >/dev/null
}

expect_fail() {
  if "$validator" "$1" >/dev/null 2>&1; then
    echo "expected rejection: $1" >&2
    exit 1
  fi
}

expect_ok "0123456789abcdef0123456789abcdef01234567"
expect_ok "ABCDEF0123456789ABCDEF0123456789ABCDEF01"
expect_fail ""
expect_fail "main"
expect_fail "0123456789abcdef"
expect_fail "0123456789abcdef0123456789abcdef0123456g"
expect_fail "0123456789abcdef0123456789abcdef012345678"
