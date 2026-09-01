#!/usr/bin/env bash
# Đăng ký 2 IME ToolVN + (mặc định) gỡ bộ gõ Việt của Apple, bật Telex & VNI.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck source=ime-common.sh
source "$ROOT/Scripts/ime-common.sh"

IM_DIR="$HOME/Library/Input Methods"
DESTS=(
  "$IM_DIR/ToolVN-Telex.app"
  "$IM_DIR/ToolVN-VNI.app"
)

for dest in "${DESTS[@]}"; do
  if [[ ! -d "$dest" ]]; then
    echo "Chưa cài đủ 2 IME (thiếu $dest). Chạy: make install"
    exit 1
  fi
  ime_register_bundle "$dest"
done

ARGS=()
if [[ "${KEEP_APPLE_VIET:-}" == "1" ]]; then
  ARGS+=(--keep-apple-viet)
fi
python3 "$ROOT/Scripts/input_sources.py" "${ARGS[@]}"
