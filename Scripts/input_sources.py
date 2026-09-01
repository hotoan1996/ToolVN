#!/usr/bin/env python3
"""Dọn nguồn nhập: gỡ mọi bàn phím/IME tiếng Việt (Apple + ToolVN cũ), thêm ToolVN Telex & VNI (hai bundle IME)."""
from __future__ import annotations

import plistlib
import subprocess
import sys
import tempfile
from pathlib import Path
from typing import Any

HITOOLBOX = Path.home() / "Library/Preferences/com.apple.HIToolbox.plist"

TOOLVN_TELEX_BUNDLE = "com.toolvn.inputmethod.telex"
TOOLVN_VNI_BUNDLE = "com.toolvn.inputmethod.vni"
MODE_TELEX = "com.toolvn.inputmethod.telex.v10"
MODE_VNI = "com.toolvn.inputmethod.vni.v10"

TOOLVN_BUNDLES = frozenset({TOOLVN_TELEX_BUNDLE, TOOLVN_VNI_BUNDLE})

APPLE_VIET_BUNDLES = frozenset(
    {
        "com.apple.inputmethod.VietnameseIM",
        "com.apple.VietnameseIM",
    }
)

APPLE_VIET_MODE_PREFIXES = (
    "com.apple.inputmethod.Vietnamese",
    "com.apple.Vietnamese",
)


def load_hitoolbox() -> dict[str, Any]:
    exported = subprocess.run(
        ["defaults", "export", "com.apple.HIToolbox", "-"],
        capture_output=True,
        check=False,
    )
    if exported.returncode == 0 and exported.stdout:
        return plistlib.loads(exported.stdout)
    if HITOOLBOX.exists():
        with HITOOLBOX.open("rb") as f:
            return plistlib.load(f)
    return {}


def save_hitoolbox(data: dict[str, Any]) -> None:
    # Ghi qua `defaults import` để đồng bộ với cfprefsd; ghi thẳng plist có
    # thể bị daemon ghi đè lại ngay sau khi script kết thúc.
    with tempfile.NamedTemporaryFile(suffix=".plist") as f:
        plistlib.dump(data, f)
        f.flush()
        subprocess.run(
            ["defaults", "import", "com.apple.HIToolbox", f.name],
            check=True,
            stdout=subprocess.DEVNULL,
        )


def _str(v: Any) -> str:
    return v if isinstance(v, str) else ""


def is_toolvn_source(item: Any) -> bool:
    if not isinstance(item, dict):
        return False
    bundle = _str(item.get("Bundle ID"))
    mode = _str(item.get("Input Mode"))
    return bundle.startswith("com.toolvn.") or mode.startswith("com.toolvn.")


def is_apple_vietnamese_source(item: Any) -> bool:
    if not isinstance(item, dict):
        return False
    bundle = _str(item.get("Bundle ID"))
    mode = _str(item.get("Input Mode"))
    kind = _str(item.get("InputSourceKind"))
    layout_name = _str(item.get("KeyboardLayout Name") or item.get("Keyboard Layout Name"))

    if bundle in APPLE_VIET_BUNDLES or "vietnamese" in bundle.lower():
        return True
    if mode and any(mode.startswith(p) for p in APPLE_VIET_MODE_PREFIXES):
        return True
    if "vietnamese" in mode.lower():
        return True
    if layout_name and "viet" in layout_name.lower():
        return True
    if kind == "Keyboard Input Method" and "vietnamese" in bundle.lower():
        return True
    return False


def toolvn_modes() -> list[dict[str, str]]:
    return [
        {
            "Bundle ID": TOOLVN_TELEX_BUNDLE,
            "Input Mode": MODE_TELEX,
            "InputSourceKind": "Input Mode",
        },
        {
            "Bundle ID": TOOLVN_VNI_BUNDLE,
            "Input Mode": MODE_VNI,
            "InputSourceKind": "Input Mode",
        },
    ]


def toolvn_enabled_entries() -> list[dict[str, str]]:
    return [
        {
            "Bundle ID": TOOLVN_TELEX_BUNDLE,
            "InputSourceKind": "Keyboard Input Method",
        },
        *toolvn_modes()[:1],
        {
            "Bundle ID": TOOLVN_VNI_BUNDLE,
            "InputSourceKind": "Keyboard Input Method",
        },
        *toolvn_modes()[1:],
    ]


def apply_clean_install(*, remove_apple_viet: bool = True) -> tuple[int, int]:
    data = load_hitoolbox()
    sources = data.get("AppleEnabledInputSources")
    if not isinstance(sources, list):
        sources = []

    removed = 0
    kept: list[Any] = []
    for item in sources:
        # Luôn xóa mọi ToolVN cũ/trùng. Cờ keep chỉ áp dụng cho IME Apple.
        if is_toolvn_source(item) or (
            remove_apple_viet and is_apple_vietnamese_source(item)
        ):
            removed += 1
            continue
        kept.append(item)

    modes = toolvn_modes()
    kept.extend(toolvn_enabled_entries())
    data["AppleEnabledInputSources"] = kept

    history = data.get("AppleInputSourceHistory")
    if isinstance(history, list):
        cleaned = [
            h
            for h in history
            if not is_toolvn_source(h)
            and (not remove_apple_viet or not is_apple_vietnamese_source(h))
        ]
        cleaned.extend(modes)
        uniq: list[Any] = []
        keys: set[tuple[str, str]] = set()
        for h in cleaned:
            if not isinstance(h, dict):
                continue
            key = (_str(h.get("Bundle ID")), _str(h.get("Input Mode")))
            if key in keys:
                continue
            keys.add(key)
            uniq.append(h)
        data["AppleInputSourceHistory"] = uniq[-8:]

    save_hitoolbox(data)
    return removed, 2


def count_toolvn_in_sources() -> int:
    data = load_hitoolbox()
    sources = data.get("AppleEnabledInputSources")
    if not isinstance(sources, list):
        return 0
    n = 0
    for item in sources:
        if (
            isinstance(item, dict)
            and _str(item.get("Bundle ID")) in TOOLVN_BUNDLES
            and _str(item.get("Input Mode")) in {MODE_TELEX, MODE_VNI}
        ):
            n += 1
    return n


def main() -> int:
    remove = "--keep-apple-viet" not in sys.argv
    manager = Path(__file__).with_name("manage-input-sources.swift")
    # TIS enable cập nhật trạng thái live trước; defaults import chạy sau cùng
    # để trạng thái bền vững không bị TIS ghi đè.
    subprocess.run(["swift", str(manager), "--enable"], check=True)
    removed, added = apply_clean_install(remove_apple_viet=remove)
    subprocess.run(
        ["killall", "TextInputMenuAgent"], check=False, stderr=subprocess.DEVNULL
    )
    subprocess.run(["sleep", "1"], check=True)
    subprocess.run(["swift", str(manager), "--check"], check=True)
    if remove:
        print(f"Đã gỡ {removed} mục tiếng Việt / ToolVN trùng (Apple + cũ).")
    print("Đã bật đúng 2 nguồn nhập (2 IME riêng):")
    print("  • ToolVN Telex  (icon VI)")
    print("  • ToolVN VNI    (icon VI)")
    print("")
    print("⌃Space: chọn ToolVN Telex hoặc ToolVN VNI.")
    print(f"(Hiện có {count_toolvn_in_sources()} mục ToolVN trong danh sách — kỳ vọng 2)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
