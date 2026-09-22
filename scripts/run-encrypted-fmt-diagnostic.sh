#!/usr/bin/env bash
set -euo pipefail

ROOT="${RUNNER_TEMP:-/tmp}/private-source"
TARGET_SHA="${TARGET_SHA:-}"
CERT="${DIAGNOSTIC_CERT:-diagnostics/recipient-cert.pem}"
EXPECTED_FP="3B:99:FF:49:BC:1A:1D:3C:EE:7A:F4:F4:A8:A9:77:0F:95:3D:56:FF:DC:7B:9E:D7:55:AC:AA:B3:98:E7:C0:F6"
BUNDLE="${RUNNER_TEMP:-/tmp}/private-diagnostic-bundle"
ARCHIVE="${RUNNER_TEMP:-/tmp}/private-diagnostic.tgz"
CIPHERTEXT="${RUNNER_TEMP:-/tmp}/encrypted.cms"

scripts/validate-input.sh "$TARGET_SHA"

if [[ ! -d "$ROOT/.git" ]]; then
  echo "VERIFY_DIAGNOSTIC_SOURCE_MISSING" >&2
  exit 80
fi

actual="$(git -C "$ROOT" rev-parse HEAD 2>/dev/null || true)"
if [[ "$actual" != "$TARGET_SHA" ]]; then
  echo "VERIFY_DIAGNOSTIC_IDENTITY_MISMATCH" >&2
  exit 81
fi

cert_fp="$(openssl x509 -in "$CERT" -noout -fingerprint -sha256 | cut -d= -f2)"
if [[ "$cert_fp" != "$EXPECTED_FP" ]]; then
  echo "VERIFY_DIAGNOSTIC_CERT_MISMATCH" >&2
  exit 82
fi

rm -rf "$BUNDLE" "$ARCHIVE" "$CIPHERTEXT"
mkdir -p "$BUNDLE"
cleanup_plaintext() {
  rm -rf "$BUNDLE" "$ARCHIVE"
}
trap cleanup_plaintext EXIT

set +e
(
  cd "$ROOT"
  cargo +1.98.1 fmt --all -- --check
) >"$BUNDLE/fmt-check.log" 2>&1
fmt_check_rc=$?

(
  cd "$ROOT"
  cargo +1.98.1 fmt --all
) >"$BUNDLE/fmt-apply.log" 2>&1
fmt_apply_rc=$?

if [[ "$fmt_apply_rc" -eq 0 ]]; then
  (
    cd "$ROOT"
    git diff --binary -- '*.rs'
  ) >"$BUNDLE/rustfmt.diff" 2>&1
  (
    cd "$ROOT"
    git diff --name-only -- '*.rs'
  ) >"$BUNDLE/rustfmt-paths.txt" 2>&1
  (
    cd "$ROOT"
    cargo +1.98.1 check --workspace --all-targets
  ) >"$BUNDLE/check-after-format.log" 2>&1
  check_after_format_rc=$?
else
  : >"$BUNDLE/rustfmt.diff"
  : >"$BUNDLE/rustfmt-paths.txt"
  check_after_format_rc=125
fi
set -e

printf '%s\n' "$TARGET_SHA" >"$BUNDLE/target-sha.txt"
printf '%s\n' "$fmt_check_rc" >"$BUNDLE/fmt-check.rc"
printf '%s\n' "$fmt_apply_rc" >"$BUNDLE/fmt-apply.rc"
printf '%s\n' "$check_after_format_rc" >"$BUNDLE/check-after-format.rc"

tar -C "$BUNDLE" -czf "$ARCHIVE" .

openssl cms -encrypt -binary -aes-256-cbc \
  -outform DER \
  -in "$ARCHIVE" \
  -out "$CIPHERTEXT" \
  "$CERT"

cleanup_plaintext
trap - EXIT

echo "VERIFY_DIAG_FMT_CHECK_RC=$fmt_check_rc"
echo "VERIFY_DIAG_FMT_APPLY_RC=$fmt_apply_rc"
echo "VERIFY_DIAG_CHECK_AFTER_FORMAT_RC=$check_after_format_rc"
echo "VERIFY_DIAGNOSTIC_CERT_FINGERPRINT_OK=YES"
echo "VERIFY_ENCRYPTED_DIAGNOSTIC_READY=YES"
