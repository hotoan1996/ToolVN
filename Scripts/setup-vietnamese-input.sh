#!/usr/bin/env bash
# Gỡ bộ gõ tiếng Việt mặc định của macOS, cài & bật ToolVN Telex + VNI (hai IME).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck source=ime-common.sh
source "$ROOT/Scripts/ime-common.sh"

IM_DIR="$HOME/Library/Input Methods"
DEST_TELEX="$IM_DIR/ToolVN-Telex.app"
DEST_VNI="$IM_DIR/ToolVN-VNI.app"

if [[ ! -d "$DEST_TELEX" ]] || [[ ! -d "$DEST_VNI" ]]; then
  echo "→ Chưa đủ 2 IME — đang build & cài…"
  "$ROOT/Scripts/build-im.sh"
  "$ROOT/Scripts/install.sh"
fi

# Tránh trùng menu: chỉ hai bundle đã cài được giữ đăng ký.
ime_unregister_build_bundles "$ROOT"
ime_unregister_bundle "$IM_DIR/ToolVN.app"

xattr -cr "$DEST_TELEX" "$DEST_VNI" 2>/dev/null || true
pkill -x ToolVNTelex 2>/dev/null || true
pkill -x ToolVNVNI 2>/dev/null || true

python3 "$ROOT/Scripts/input_sources.py"
ime_unregister_build_bundles "$ROOT"

echo ""
echo "Hoàn tất. Mở Cài đặt → Bàn phím → Nguồn nhập nếu menu chưa đổi."
echo "Chạy ./Scripts/doctor.sh để kiểm tra."
