#!/usr/bin/env bash
set -euo pipefail
f=".github/workflows/private-verify.yml"

test -f "$f"
grep -Fq 'workflow_dispatch:' "$f"
grep -Fq 'pull_request:' "$f"
grep -Fq '      - "verify/request"' "$f"
if grep -Fq 'pull_request_target:' "$f"; then
  echo "pull_request_target is forbidden" >&2
  exit 1
fi

python - "$f" <<'PY'
from pathlib import Path
import sys

text = Path(sys.argv[1]).read_text()

expected_job_gate = "if: github.event_name == 'workflow_dispatch' || github.ref == 'refs/heads/verify/request'"
verify_marker = "  verify:\n"
start = text.find(verify_marker)
if start < 0:
    raise SystemExit("missing verify job")
verify_block = text[start:]
if expected_job_gate not in verify_block:
    raise SystemExit("verify job is not restricted to trusted triggers")

for step_name in (
    "Resolve verification target",
    "Validate immutable target",
    "Exact private checkout",
    "Canonical private verification",
):
    if f"- name: {step_name}" not in verify_block:
        raise SystemExit(f"missing trusted verification step: {step_name}")

if "secrets.PRIVATE_READ_TOKEN" not in verify_block:
    raise SystemExit("missing private read secret")
if "secrets.PRIVATE_READ_TOKEN" in text[:start]:
    raise SystemExit("private read secret must not be available to self-test job")
PY
