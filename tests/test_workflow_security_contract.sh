#!/usr/bin/env bash
set -euo pipefail
f=".github/workflows/private-verify.yml"

test -f "$f"
grep -Fq 'workflow_dispatch:' "$f"
grep -Fq 'push:' "$f"
grep -Fq '      - "verify/request"' "$f"
if grep -Fq 'pull_request_target:' "$f"; then
  echo "pull_request_target is forbidden" >&2
  exit 1
fi

python - "$f" <<'PY'
from pathlib import Path
import sys
text = Path(sys.argv[1]).read_text()
expected = "if: github.event_name == 'workflow_dispatch' || github.ref == 'refs/heads/verify/request'"
verify_pos = text.find("\n  verify:\n")
if verify_pos < 0:
    raise SystemExit("verify job missing")
verify_block = text[verify_pos:]
if expected not in verify_block:
    raise SystemExit("verify job is not owner-trigger gated")
if "needs: relay-self-test" not in verify_block:
    raise SystemExit("verify job must depend on relay-self-test")
if "- name: Resolve verification target" not in verify_block:
    raise SystemExit("target resolver missing")
if "verification-target.sha" not in verify_block:
    raise SystemExit("owner-trigger target file missing")
relay_pos = text.find("\n  relay-self-test:\n")
if relay_pos < 0:
    raise SystemExit("relay-self-test job missing")
relay_block = text[relay_pos:verify_pos]
if "${{ secrets.PRIVATE_READ_TOKEN }}" in relay_block:
    raise SystemExit("private token secret must not be referenced by relay self-test job")
if text.count("PRIVATE_READ_TOKEN: ${{ secrets.PRIVATE_READ_TOKEN }}") != 1:
    raise SystemExit("private token secret must be scoped exactly once")
PY
