#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck source=ime-common.sh
source "$ROOT/Scripts/ime-common.sh"

IM_DIR="$HOME/Library/Input Methods"
DEST_TELEX="$IM_DIR/ToolVN-Telex.app"
DEST_VNI="$IM_DIR/ToolVN-VNI.app"

ok=0
warn=0

check() {
  local label="$1"
  local status="$2"
  if [[ "$status" == "ok" ]]; then
    echo "  ✓ $label"
    ok=$((ok + 1))
  else
    echo "  ✗ $label"
    echo "    → $status"
    warn=$((warn + 1))
  fi
}

eval "$(python3 <<'PY'
import plistlib
import subprocess
from pathlib import Path

TOOLVN_BUNDLES = frozenset({
    "com.toolvn.inputmethod.telex",
    "com.toolvn.inputmethod.vni",
})
TOOLVN_MODES = frozenset({
    "com.toolvn.inputmethod.telex.v10",
    "com.toolvn.inputmethod.vni.v10",
})

toolvn_count = 0
apple_viet = 0
exported = subprocess.run(
    ["defaults", "export", "com.apple.HIToolbox", "-"],
    capture_output=True,
    check=False,
)
if exported.returncode == 0 and exported.stdout:
    d = plistlib.loads(exported.stdout)
    sources = d.get("AppleEnabledInputSources") or []
    for x in sources:
        if not isinstance(x, dict):
            continue
        bundle = str(x.get("Bundle ID") or "")
        mode = str(x.get("Input Mode") or "")
        layout = str(x.get("KeyboardLayout Name") or x.get("Keyboard Layout Name") or "")
        if bundle in TOOLVN_BUNDLES and mode in TOOLVN_MODES:
            toolvn_count += 1
        if "VietnameseIM" in bundle or "VietnameseSimple" in mode:
            apple_viet += 1
        elif "vietnamese" in bundle.lower() or "vietnamese" in mode.lower():
            apple_viet += 1
        elif layout and "viet" in layout.lower():
            apple_viet += 1
has_toolvn = 1 if toolvn_count > 0 else 0

lsregister = "/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister"
dump = subprocess.run(
    [lsregister, "-dump"],
    capture_output=True,
    text=True,
    encoding="utf-8",
    errors="replace",
    check=False,
).stdout
records = []
current = {}
for line in dump.splitlines():
    if line.startswith("bundle id:"):
        if current:
            records.append(current)
        current = {}
    elif line.startswith("path:"):
        current.setdefault(
            "path", line.split(":", 1)[1].rsplit(" (0x", 1)[0].strip()
        )
    elif line.startswith("identifier:"):
        current.setdefault("identifier", line.split(":", 1)[1].strip())
if current:
    records.append(current)

toolvn_records = [r for r in records if r.get("identifier") in TOOLVN_BUNDLES]
expected_paths = {
    str(Path.home() / "Library/Input Methods/ToolVN-Telex.app"),
    str(Path.home() / "Library/Input Methods/ToolVN-VNI.app"),
}
installed_records = [r for r in toolvn_records if r.get("path") in expected_paths]

print(f"TOOLVN_COUNT={toolvn_count}")
print(f"APPLE_VIET_LEFT={apple_viet}")
print(f"HAS_TOOLVN={has_toolvn}")
print(f"LS_TOOLVN_COUNT={len(toolvn_records)}")
print(f"LS_INSTALLED_COUNT={len(installed_records)}")
PY
)"

echo "ToolVN doctor"
echo ""

if [[ -d "$DEST_TELEX" ]]; then
  check "Đã cài ToolVN-Telex.app" ok
else
  check "Đã cài ToolVN-Telex.app" "Chạy: make install"
fi

if [[ -d "$DEST_VNI" ]]; then
  check "Đã cài ToolVN-VNI.app" ok
else
  check "Đã cài ToolVN-VNI.app" "Chạy: make install"
fi

if [[ -f "$DEST_TELEX/Contents/Resources/ToolVN-Telex.icns" ]]; then
  check "Icon Telex (ToolVN-Telex.icns)" ok
else
  check "Icon Telex (ToolVN-Telex.icns)" "Thiếu — make build-dual"
fi

if [[ -f "$DEST_VNI/Contents/Resources/ToolVN-VNI.icns" ]]; then
  check "Icon VNI (ToolVN-VNI.icns)" ok
else
  check "Icon VNI (ToolVN-VNI.icns)" "Thiếu — make build-dual"
fi

if [[ ! -d "$IM_DIR/ToolVN.app" ]]; then
  check "Không còn bundle cũ ToolVN.app" ok
else
  check "Không còn bundle cũ ToolVN.app" "Gỡ $IM_DIR/ToolVN.app rồi make install"
fi

if [[ -x "$DEST_TELEX/Contents/MacOS/ToolVNTelex" ]] && [[ -x "$DEST_VNI/Contents/MacOS/ToolVNVNI" ]]; then
  check "Binary ToolVN (cả hai IME)" ok
else
  check "Binary ToolVN (cả hai IME)" "Thiếu hoặc không thực thi được"
fi

if [[ -x "$LSREGISTER" ]]; then
  check "lsregister (đường dẫn hệ thống)" ok
else
  check "lsregister" "Không tìm thấy $LSREGISTER"
fi

if [[ "${LS_TOOLVN_COUNT:-0}" -eq 2 ]] && [[ "${LS_INSTALLED_COUNT:-0}" -eq 2 ]]; then
  check "Launch Services chỉ có đúng 2 bản đã cài" ok
else
  check "Launch Services chỉ có đúng 2 bản đã cài" \
    "Đang có ${LS_TOOLVN_COUNT:-0} đăng ký ToolVN (${LS_INSTALLED_COUNT:-0} bản đúng vị trí) — chạy: make setup-vi"
fi

if swift "$ROOT/Scripts/manage-input-sources.swift" --check >/dev/null 2>&1; then
  check "TIS chỉ có đúng 2 input method ToolVN đang bật" ok
else
  check "TIS chỉ có đúng 2 input method ToolVN đang bật" "Chạy: make setup-vi"
fi

if [[ "${APPLE_VIET_LEFT:-0}" -gt 0 ]]; then
  check "Không còn bộ gõ Việt Apple" "Chạy: make setup-vi"
else
  check "Không còn bộ gõ Việt Apple" ok
fi

if [[ "${TOOLVN_COUNT:-0}" -eq 2 ]]; then
  check "Đúng 2 mục ToolVN (Telex + VNI)" ok
elif [[ "${TOOLVN_COUNT:-0}" -gt 2 ]]; then
  check "Đúng 2 mục ToolVN (Telex + VNI)" "Đang trùng ($TOOLVN_COUNT mục) — chạy: make setup-vi"
else
  check "Đúng 2 mục ToolVN (Telex + VNI)" "Thiếu ($TOOLVN_COUNT mục) — chạy: make setup-vi"
fi

if [[ "${HAS_TOOLVN:-0}" -eq 1 ]]; then
  check "ToolVN trong nguồn nhập đã bật" ok
else
  check "ToolVN trong nguồn nhập đã bật" "Chạy: make setup-vi"
fi

if pgrep -xq ToolVNTelex || pgrep -xq ToolVNVNI; then
  check "Tiến trình ToolVN đang chạy" ok
else
  echo "  · Tiến trình ToolVN: chưa chạy (chọn IME trên menu Input là được)"
  ok=$((ok + 1))
fi

echo ""
echo "Hai IME riêng — không mở cửa sổ khi double-click."
echo "⌃Space → ToolVN Telex hoặc ToolVN VNI (cùng icon VI)"
echo ""
if [[ $warn -gt 0 ]]; then
  echo "Gợi ý nhanh: make setup-vi"
  exit 1
fi
echo "Cấu hình cơ bản ổn ($ok kiểm tra đạt)."
