#!/usr/bin/env bash
set -euo pipefail
f="${1:-.github/workflows/format-diagnostic.yml}"

test -f "$f"
grep -Fq 'push:' "$f"
grep -Fq 'PRIVATE_READ_TOKEN: ${{ secrets.PRIVATE_READ_TOKEN }}' "$f"
grep -Fq 'feat/site-core-release' "$f"
grep -Fq 'cargo fmt --all' "$f"
grep -Fq 'openssl cms -encrypt' "$f"
grep -Fq 'actions/upload-artifact@v4' "$f"
grep -Fq 'retention-days: 1' "$f"

if grep -Fq 'cat "$RUNNER_TEMP/rustfmt.patch"' "$f"; then
  echo 'plaintext patch output is forbidden' >&2
  exit 1
fi
if grep -Fq 'pull_request:' "$f"; then
  echo 'untrusted PR trigger is forbidden' >&2
  exit 1
fi
