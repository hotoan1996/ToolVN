#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
RES="$ROOT/InputMethod/Resources"

echo "→ Tạo icon VI cho Telex & VNI…"
swift "$ROOT/Scripts/build-icon.swift" "$ROOT"

for base in ToolVN-Telex ToolVN-VNI; do
  ICONSET="$RES/${base}.iconset"
  ICNS="$RES/${base}.icns"
  rm -f "$ICNS"
  if [[ ! -f "$ICONSET/Contents.json" ]]; then
    echo "Thiếu $ICONSET/Contents.json" >&2
    exit 1
  fi
  iconutil -c icns "$ICONSET" -o "$ICNS"
  echo "→ Xong: $ICNS"
done
