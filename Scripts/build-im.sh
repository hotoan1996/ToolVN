#!/usr/bin/env bash
# Build một hoặc hai bundle Input Method (Telex / VNI).
# Mặc định: cả hai — build/ToolVN-Telex.app + build/ToolVN-VNI.app
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck source=ime-common.sh
source "$ROOT/Scripts/ime-common.sh"
BUILD="$ROOT/build"

VARIANT="${TOOLVN_VARIANT:-dual}"

build_core() {
  echo "→ Build ToolVNCore…"
  swift build -c release --package-path "$ROOT" --product ToolVNCore 2>/dev/null || swift build -c release --package-path "$ROOT"

  CORE_PATH="$ROOT/.build/release"
  SWIFTC_FLAGS=()
  if [[ -d "$CORE_PATH/ToolVNCore.swiftmodule" ]]; then
    SWIFTC_FLAGS=(-I "$CORE_PATH" -L "$CORE_PATH" -lToolVNCore)
  fi

}

package_variant() {
  local key="$1"
  local app_name plist_src bundle_id icon_base display_name mode_id
  local executable compile_define

  case "$key" in
    telex)
      app_name="ToolVN-Telex.app"
      plist_src="$ROOT/InputMethod/Info-Telex.plist"
      bundle_id="com.toolvn.inputmethod.telex"
      icon_base="ToolVN-Telex"
      display_name="ToolVN Telex"
      mode_id="com.toolvn.inputmethod.telex.v10"
      executable="ToolVNTelex"
      compile_define="TOOLVN_TELEX"
      ;;
    vni)
      app_name="ToolVN-VNI.app"
      plist_src="$ROOT/InputMethod/Info-VNI.plist"
      bundle_id="com.toolvn.inputmethod.vni"
      icon_base="ToolVN-VNI"
      display_name="ToolVN VNI"
      mode_id="com.toolvn.inputmethod.vni.v10"
      executable="ToolVNVNI"
      compile_define="TOOLVN_VNI"
      ;;
    *)
      echo "variant không hợp lệ: $key" >&2
      return 1
      ;;
  esac

  local app="$BUILD/$app_name"
  local macos="$app/Contents/MacOS"
  local resources="$app/Contents/Resources"

  rm -rf "$app"
  mkdir -p "$macos" "$resources"

  echo "→ Biên dịch $display_name thành executable riêng…"
  swiftc -O \
    -D "$compile_define" \
    -framework Cocoa \
    -framework InputMethodKit \
    "${SWIFTC_FLAGS[@]}" \
    "$ROOT/Sources/ToolVNCore/"*.swift \
    "$ROOT/InputMethod/VietnameseInputController.swift" \
    "$ROOT/InputMethod/main.swift" \
    -o "$macos/$executable"
  cp "$plist_src" "$app/Contents/Info.plist"
  printf 'APPL????' > "$app/Contents/PkgInfo"
  cp "$ROOT/InputMethod/Resources/${icon_base}.icns" "$resources/${icon_base}.icns"

  for lang in en vi; do
    mkdir -p "$resources/${lang}.lproj"
    {
      printf '"CFBundleDisplayName" = "%s";\n' "$display_name"
      printf '"CFBundleName" = "%s";\n' "$display_name"
      printf '"%s" = "%s";\n' "$bundle_id" "$display_name"
      printf '"%s" = "%s";\n' "$mode_id" "$display_name"
    } > "$resources/${lang}.lproj/InfoPlist.strings"
  done

  echo "-> Ky bundle ${bundle_id}..."
  codesign --force --deep -s - --identifier "$bundle_id" "$app" 2>/dev/null || true
  echo "-> Xong: $app"
}

rm -rf \
  "$BUILD/ToolVN.app" \
  "$BUILD/ToolVN-Telex.app" \
  "$BUILD/ToolVN-VNI.app"
build_core
"$ROOT/Scripts/build-icon.sh"

case "$VARIANT" in
  telex)
    package_variant telex
    ;;
  vni)
    package_variant vni
    ;;
  dual | both | "")
    package_variant telex
    package_variant vni
    ;;
  *)
    echo "TOOLVN_VARIANT không hợp lệ: $VARIANT (telex | vni | dual)" >&2
    exit 1
    ;;
esac

# macOS có thể tự phát hiện .app trong build/. Hủy các đăng ký này để menu
# chỉ lấy hai bundle đã cài trong ~/Library/Input Methods.
ime_unregister_build_bundles "$ROOT"

echo ""
echo "Build IME xong. Cài: make install hoặc make setup-vi"
