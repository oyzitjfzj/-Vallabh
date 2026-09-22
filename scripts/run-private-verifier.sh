#!/usr/bin/env bash
set -euo pipefail

ROOT="${RUNNER_TEMP:-/tmp}/private-source"
LOG_DIR="${RUNNER_TEMP:-/tmp}/private-verify-logs"
PINNED_RUST="1.98.1"

if [[ ! -d "$ROOT/.git" ]]; then
  echo "VERIFY_ALL_RESULT=FAIL code=source-missing" >&2
  exit 70
fi

mkdir -p "$LOG_DIR"

run_gate() {
  local name="$1"
  shift
  local log="$LOG_DIR/${name}.log"
  echo "VERIFY_PHASE=$name"
  if ! (cd "$ROOT" && "$@") >"$log" 2>&1; then
    echo "VERIFY_ALL_RESULT=FAIL code=$name" >&2
    exit 71
  fi
}

run_gate toolchain-install rustup toolchain install "$PINNED_RUST" --profile minimal --component rustfmt --component clippy --no-self-update
run_gate toolchain-pin rustup override set "$PINNED_RUST"
run_gate rust-version rustc --version
run_gate cargo-version cargo --version

if [[ -x "$ROOT/tools/verify_all.sh" ]]; then
  run_gate canonical-verifier bash tools/verify_all.sh
else
  run_gate fmt cargo fmt --check
  run_gate check cargo check --workspace --all-targets
  run_gate clippy cargo clippy --workspace --all-targets -- -D warnings
  run_gate test cargo test --workspace

  if [[ -x "$ROOT/scripts/build-release.sh" ]]; then
    run_gate release-build bash scripts/build-release.sh
  fi
fi

verified_sha="$(git -C "$ROOT" rev-parse HEAD)"
echo "VERIFY_ALL_RESULT=PASS sha=$verified_sha"
