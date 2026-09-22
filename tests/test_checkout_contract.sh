#!/usr/bin/env bash
set -euo pipefail
f="scripts/checkout-private.sh"

test -f "$f"
grep -Fq 'set -euo pipefail' "$f"
grep -Fq 'PRIVATE_REPOSITORY="oyzitjfzj/ai-product-web"' "$f"
grep -Fq 'scripts/validate-input.sh "$TARGET_SHA"' "$f"
grep -Fq 'fetch -q --no-tags --depth=1' "$f"
grep -Fq 'rev-parse HEAD' "$f"
grep -Fq 'VERIFY_IDENTITY_MISMATCH' "$f"
grep -Fq 'VERIFY_ACCESS_FAILED' "$f"
grep -Fq 'ACCESS_LOG=' "$f"
if grep -Fq 'set -x' "$f"; then
  echo "shell tracing is forbidden" >&2
  exit 1
fi
if grep -Eq 'echo .*PRIVATE_READ_TOKEN|printf .*PRIVATE_READ_TOKEN.*>&[12]' "$f"; then
  echo "token printing is forbidden" >&2
  exit 1
fi
