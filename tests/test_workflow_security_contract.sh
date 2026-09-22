#!/usr/bin/env bash
set -euo pipefail
f=".github/workflows/private-verify.yml"

test -f "$f"
grep -Fq 'workflow_dispatch:' "$f"
grep -Fq 'pull_request:' "$f"
if grep -Fq 'pull_request_target:' "$f"; then
  echo "pull_request_target is forbidden" >&2
  exit 1
fi

python - "$f" <<'PY'
from pathlib import Path
import sys
text = Path(sys.argv[1]).read_text()
for step_name in ("Exact private checkout", "Canonical private verification"):
    marker = f"- name: {step_name}"
    start = text.find(marker)
    if start < 0:
        raise SystemExit(f"missing step: {step_name}")
    end = text.find("\n      - name:", start + len(marker))
    block = text[start:] if end < 0 else text[start:end]
    if "if: github.event_name == 'workflow_dispatch'" not in block:
        raise SystemExit(f"secret/private step not gated: {step_name}")
PY
