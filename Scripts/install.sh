#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck source=ime-common.sh
source "$ROOT/Scripts/ime-common.sh"

IM_DIR="$HOME/Library/Input Methods"
APPS=(
  "ToolVN-Telex.app:com.toolvn.inputmethod.telex:ToolVN-Telex.icns"
  "ToolVN-VNI.app:com.toolvn.inputmethod.vni:ToolVN-VNI.icns"
)

if [[ ! -d "$ROOT/build/ToolVN-Telex.app" ]] || [[ ! -d "$ROOT/build/ToolVN-VNI.app" ]]; then
  "$ROOT/Scripts/build-im.sh"
fi

mkdir -p "$IM_DIR"
# Bundle cũ một-app-hai-mode phải bị loại bỏ. Không unregister hai bundle
# hiện tại: đăng ký lại cùng path sau mỗi build làm TIS tích lũy object trùng.
ime_unregister_bundle "$IM_DIR/ToolVN.app"
ime_unregister_build_bundles "$ROOT"

# Gỡ bundle cũ (một app hai mode).
rm -rf "$IM_DIR/ToolVN.app"

pkill -x ToolVNTelex 2>/dev/null || true
pkill -x ToolVNVNI 2>/dev/null || true

for spec in "${APPS[@]}"; do
  IFS=: read -r app_name _bundle icon_name <<< "$spec"
  src="$ROOT/build/$app_name"
  dest="$IM_DIR/$app_name"
  if [[ ! -d "$src" ]]; then
    echo "Thiếu $src — chạy: make build-dual" >&2
    exit 1
  fi
  executable=$(/usr/libexec/PlistBuddy -c "Print CFBundleExecutable" "$src/Contents/Info.plist")
  exec_path="$src/Contents/MacOS/$executable"
  icns_path="$src/Contents/Resources/$icon_name"
  if [[ ! -f "$exec_path" || ! -f "$icns_path" ]]; then
    echo "Bundle không đủ: $src" >&2
    exit 1
  fi
  # Giữ inode của thư mục .app ổn định để TIS coi đây là update, không phải
  # một input source mới. Chỉ thay Contents.
  mkdir -p "$dest"
  rm -rf "$dest/Contents"
  ditto "$src/Contents" "$dest/Contents"
  xattr -cr "$dest" 2>/dev/null || true
done

# Không cho hai bản build xuất hiện song song với hai bản đã cài.
ime_unregister_build_bundles "$ROOT"

echo "Đã cài 2 Input Method:"
for spec in "${APPS[@]}"; do
  IFS=: read -r app_name bundle icon_name <<< "$spec"
  dest="$IM_DIR/$app_name"
  ver=$(/usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" "$dest/Contents/Info.plist" 2>/dev/null || echo "?")
  echo "  $dest  ($bundle, v$ver)"
  echo "    Icon: $dest/Contents/Resources/$icon_name"
done
echo ""
echo "Lưu ý: không có cửa sổ khi double-click — chọn trên menu Input (⌃Space)."
echo "  make setup-vi  — gỡ bộ gõ Việt Apple + bật Telex/VNI"
echo "  ./Scripts/reload-im.sh"
