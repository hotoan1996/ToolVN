#!/usr/bin/env bash
# Đường dẫn cố định — `lsregister` thường KHÔNG có trong PATH trên macOS.
LSREGISTER="/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister"

ime_register_bundle() {
  local app_path="$1"
  if [[ ! -d "$app_path" ]]; then
    echo "Không tìm thấy: $app_path" >&2
    return 1
  fi
  if [[ ! -x "$LSREGISTER" ]]; then
    echo "Thiếu lsregister tại $LSREGISTER" >&2
    return 1
  fi
  "$LSREGISTER" -f "$app_path"
}

ime_unregister_bundle() {
  local app_path="$1"
  if [[ -x "$LSREGISTER" ]]; then
    "$LSREGISTER" -u "$app_path" 2>/dev/null || true
  fi
}

# Chỉ hai bundle trong ~/Library/Input Methods được phép đăng ký.
# Các app trong build/ nếu còn trong Launch Services sẽ tạo mục trùng.
ime_unregister_build_bundles() {
  local root="$1"
  ime_unregister_bundle "$root/build/ToolVN.app"
  ime_unregister_bundle "$root/build/ToolVN-Telex.app"
  ime_unregister_bundle "$root/build/ToolVN-VNI.app"
}
