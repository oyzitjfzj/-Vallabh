#!/usr/bin/env bash
set -euo pipefail

workflow=".github/workflows/encrypted-fmt-diagnostic.yml"
script="scripts/run-encrypted-fmt-diagnostic.sh"
cert="diagnostics/recipient-cert.pem"

test -f "$workflow"
test -f "$script"
test -f "$cert"

grep -Fq '      - "diagnose/request"' "$workflow"
grep -Fq 'actions/upload-artifact@043fb46d1a93c77aae656e7c1c64a875d1fc6a0a' "$workflow"
grep -Fq 'name: encrypted-private-diagnostic' "$workflow"
grep -Fq 'path: ${{ runner.temp }}/encrypted.cms' "$workflow"
if grep -Fq 'pull_request_target:' "$workflow"; then
  echo "pull_request_target is forbidden" >&2
  exit 1
fi

grep -Fq 'cargo +1.98.1 fmt --all -- --check' "$script"
grep -Fq 'cargo +1.98.1 fmt --all' "$script"
grep -Fq "git diff --binary -- '*.rs'" "$script"
grep -Fq 'openssl cms -encrypt' "$script"
grep -Fq 'VERIFY_ENCRYPTED_DIAGNOSTIC_READY=YES' "$script"

if grep -Eq 'cat .*\.log|tee .*\.log' "$script"; then
  echo "plaintext diagnostic log printing is forbidden" >&2
  exit 1
fi
