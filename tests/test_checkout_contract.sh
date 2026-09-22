#!/usr/bin/env bash
set -euo pipefail
f="scripts/checkout-private.sh"

test -f "$f"
grep -Fq 'set -euo pipefail' "$f"
grep -Fq 'PRIVATE_REPOSITORY="oyzitjfzj/ai-product-web"' "$f"
grep -Fq 'scripts/validate-input.sh "$TARGET_SHA"' "$f"
grep -Eq 'git .*rev-parse HEAD' "$f"
grep -Fq 'VERIFY_IDENTITY_MISMATCH' "$f"
if grep -Fq 'set -x' "$f"; then
  echo "shell tracing is forbidden" >&2
  exit 1
fi
