#!/usr/bin/env bash
set -euo pipefail
f=".github/workflows/private-verify.yml"

test -f "$f"
grep -Fq 'workflow_dispatch:' "$f"
grep -Fq 'pull_request:' "$f"
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
for step_name in ("Resolve verification target", "Validate immutable target", "Exact private checkout", "Canonical private verification"):
    marker = f"- name: {step_name}"
    start = text.find(marker)
    if start < 0:
        raise SystemExit(f"missing step: {step_name}")
    end = text.find("\n      - name:", start + len(marker))
    block = text[start:] if end < 0 else text[start:end]
    if_lines = [line.strip() for line in block.splitlines() if line.strip().startswith("if:")]
    if if_lines != [expected]:
        raise SystemExit(f"verification step gate mismatch: {step_name}: {if_lines}")
PY
