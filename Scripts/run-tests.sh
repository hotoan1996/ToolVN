#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
echo "=== Golden (bắt buộc) ==="
swift run toolvn-test --strict
echo ""
echo "=== Full (golden + extended) ==="
swift run toolvn-test
