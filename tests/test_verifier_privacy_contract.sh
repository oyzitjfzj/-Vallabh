#!/usr/bin/env bash
set -euo pipefail
f="scripts/run-private-verifier.sh"

test -f "$f"
grep -Fq 'set -euo pipefail' "$f"
grep -Fq 'VERIFY_ALL_RESULT=PASS' "$f"
grep -Fq 'VERIFY_ALL_RESULT=FAIL' "$f"
grep -Fq 'cargo fmt --check' "$f"
grep -Fq 'cargo check --workspace --all-targets' "$f"
grep -Fq 'cargo clippy --workspace --all-targets -- -D warnings' "$f"
grep -Fq 'cargo test --workspace' "$f"

if grep -Eq 'cat .*\.log|tee .*\.log' "$f"; then
  echo "raw log printing is forbidden" >&2
  exit 1
fi
