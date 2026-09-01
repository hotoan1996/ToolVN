#!/usr/bin/env bash
# Tải lại Input Method sau khi cài (không cần đăng xuất).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck source=ime-common.sh
source "$ROOT/Scripts/ime-common.sh"

IM_DIR="$HOME/Library/Input Methods"
DESTS=(
  "$IM_DIR/ToolVN-Telex.app"
  "$IM_DIR/ToolVN-VNI.app"
)

missing=0
for dest in "${DESTS[@]}"; do
  if [[ ! -d "$dest" ]]; then
    missing=1
  fi
done
if [[ $missing -eq 1 ]]; then
  echo "Chưa cài đủ 2 IME. Chạy: make install"
  exit 1
fi

echo "→ Dừng tiến trình ToolVN cũ (nếu có)…"
pkill -x ToolVNTelex 2>/dev/null || true
pkill -x ToolVNVNI 2>/dev/null || true
sleep 0.3

swift "$ROOT/Scripts/manage-input-sources.swift" --enable
ime_unregister_build_bundles "$ROOT"
killall TextInputMenuAgent 2>/dev/null || true
for dest in "${DESTS[@]}"; do
  ver=$(/usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" "$dest/Contents/Info.plist" 2>/dev/null || echo "?")
  echo "Đã nạp lại: $dest (v$ver)"
done

echo ""
echo "Trên menu Input: chọn ToolVN Telex hoặc ToolVN VNI (cùng icon VI)."
echo "Nếu icon/menu cũ: đăng xuất macOS một lần (cache Input Method)."
