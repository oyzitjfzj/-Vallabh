#!/usr/bin/env bash
set -euo pipefail
f="scripts/run-private-verifier.sh"

test -f "$f"
grep -Fq 'set -euo pipefail' "$f"
grep -Fq 'VERIFY_ALL_RESULT=PASS' "$f"
grep -Fq 'VERIFY_ALL_RESULT=FAIL' "$f"
grep -Fq 'VERIFY_PHASE=' "$f"
grep -Fq 'cargo fmt --check' "$f"
grep -Fq 'cargo check --workspace --all-targets' "$f"
grep -Fq 'cargo clippy --workspace --all-targets' "$f"
grep -Fq 'cargo test --workspace' "$f"
grep -Fq 'private-verify-logs' "$f"
grep -Fq 'tools/verify_all.sh' "$f"

if grep -Eq 'cat .*\.log|tee .*\.log' "$f"; then
  echo "raw log printing is forbidden" >&2
  exit 1
fi
if grep -Eq 'actions/upload-artifact|gh .*upload|curl .*artifact' "$f"; then
  echo "artifact upload is forbidden" >&2
  exit 1
fi
