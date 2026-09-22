#!/usr/bin/env bash
set -euo pipefail

ROOT="${RUNNER_TEMP:-/tmp}/private-source"
LOG_DIR="${RUNNER_TEMP:-/tmp}/private-verify-logs"
TARGET_SHA="${TARGET_SHA:-}"

scripts/validate-input.sh "$TARGET_SHA"

if [[ ! -d "$ROOT/.git" ]]; then
  echo "VERIFY_ALL_RESULT=FAIL code=source-missing" >&2
  exit 70
fi

actual="$(git -C "$ROOT" rev-parse HEAD 2>/dev/null || true)"
if [[ "$actual" != "$TARGET_SHA" ]]; then
  echo "VERIFY_ALL_RESULT=FAIL code=identity-mismatch" >&2
  exit 71
fi

rm -rf "$LOG_DIR"
mkdir -p "$LOG_DIR"
trap 'rm -rf "$LOG_DIR"' EXIT

run_gate() {
  local name="$1"
  shift
  local log="$LOG_DIR/${name}.log"

  echo "VERIFY_PHASE=$name"
  if ! "$@" >"$log" 2>&1; then
    echo "VERIFY_ALL_RESULT=FAIL code=$name" >&2
    exit 72
  fi
}

cd "$ROOT"

run_gate toolchain-install rustup toolchain install 1.98.1 --profile minimal --component rustfmt --component clippy --no-self-update
export RUSTUP_TOOLCHAIN=1.98.1
echo "VERIFY_TOOLCHAIN=rust-1.98.1"

if [[ -x tools/verify_all.sh ]]; then
  run_gate canonical bash ./tools/verify_all.sh
else
  cargo_locked=()
  if [[ -f Cargo.lock ]]; then
    cargo_locked=(--locked)
  fi

  run_gate fmt cargo fmt --check
  run_gate check cargo check --workspace --all-targets "${cargo_locked[@]}"
  run_gate clippy cargo clippy --workspace --all-targets "${cargo_locked[@]}" -- -D warnings
  run_gate test cargo test --workspace "${cargo_locked[@]}"

  if [[ -x scripts/build-release.sh ]]; then
    run_gate release bash ./scripts/build-release.sh
  fi
fi

final_sha="$(git rev-parse HEAD 2>/dev/null || true)"
if [[ "$final_sha" != "$TARGET_SHA" ]]; then
  echo "VERIFY_ALL_RESULT=FAIL code=post-verify-identity-mismatch" >&2
  exit 73
fi

echo "VERIFY_ALL_RESULT=PASS sha=$final_sha"
