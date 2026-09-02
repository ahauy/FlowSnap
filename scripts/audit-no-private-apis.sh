#!/usr/bin/env bash
# TC-013-07 — Public macOS APIs only.
#
# Greps FlowSnap/Infrastructure/ for any reference to private CGS or SLS
# symbols. The `\b` word boundary avoids false positives on benign names
# like `CGSize`. Returns 0 (pass) on zero matches, 1 (fail) otherwise.
#
# Wired into CI as a gating step. Run locally with:
#   scripts/audit-no-private-apis.sh

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TARGET_DIR="$ROOT/FlowSnap/Infrastructure"

if [[ ! -d "$TARGET_DIR" ]]; then
  echo "[audit] ERROR: $TARGET_DIR not found" >&2
  exit 2
fi

MATCHES=$(grep -rE "\bCGS[A-Z_]|\bSLS[A-Z_]" "$TARGET_DIR" || true)

if [[ -n "$MATCHES" ]]; then
  echo "[audit] FAIL: private CGS/SLS symbols found:" >&2
  echo "$MATCHES" >&2
  exit 1
fi

echo "[audit] OK: no private CGS/SLS symbols in $TARGET_DIR"
exit 0
