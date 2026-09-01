#!/usr/bin/env bash
# Cấu hình ToolVN (UserDefaults của IME)
set -euo pipefail

usage() {
  echo "Cách dùng:"
  echo "  $0 telex     — bật bộ gõ Telex (mặc định)"
  echo "  $0 vni       — bật bộ gõ VNI"
  echo "  $0 on        — bật gõ tiếng Việt"
  echo "  $0 off       — tắt (chuyển sang gõ ASCII thuần trong IME)"
  echo "  $0 status    — xem cấu hình hiện tại"
}

case "${1:-status}" in
  telex)
    defaults write com.toolvn.inputmethod.telex ToolVN.inputMethod -string telex
    ;;
  vni)
    defaults write com.toolvn.inputmethod.vni ToolVN.inputMethod -string vni
    ;;
  on)
    defaults write com.toolvn.inputmethod.telex ToolVN.enabled -bool true
    defaults write com.toolvn.inputmethod.vni ToolVN.enabled -bool true
    ;;
  off)
    defaults write com.toolvn.inputmethod.telex ToolVN.enabled -bool false
    defaults write com.toolvn.inputmethod.vni ToolVN.enabled -bool false
    ;;
  status)
    echo "telex.inputMethod=$(defaults read com.toolvn.inputmethod.telex ToolVN.inputMethod 2>/dev/null || echo telex)"
    echo "vni.inputMethod=$(defaults read com.toolvn.inputmethod.vni ToolVN.inputMethod 2>/dev/null || echo vni)"
    echo "telex.enabled=$(defaults read com.toolvn.inputmethod.telex ToolVN.enabled 2>/dev/null || echo true)"
    echo "vni.enabled=$(defaults read com.toolvn.inputmethod.vni ToolVN.enabled 2>/dev/null || echo true)"
    ;;
  *) usage; exit 1 ;;
esac

echo "Chọn ToolVN Telex hoặc ToolVN VNI trên menu Input (⌃Space), hoặc ./Scripts/reload-im.sh"
