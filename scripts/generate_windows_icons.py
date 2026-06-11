#!/usr/bin/env python3
"""Generate Windows .ico from the circular app logo PNG."""

from __future__ import annotations

from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
PNG_PATH = ROOT / "asset/image/app_logo.png"
ICO_PATH = ROOT / "windows/runner/resources/app_icon.ico"

ICON_SIZES = [16, 24, 32, 48, 64, 128, 256]


def main() -> None:
    if not PNG_PATH.exists():
        raise SystemExit(
            f"Missing {PNG_PATH}. Run scripts/generate_app_icons.py first."
        )

    source = Image.open(PNG_PATH).convert("RGBA")
    icons = [source.resize((size, size), Image.Resampling.LANCZOS) for size in ICON_SIZES]
    ICO_PATH.parent.mkdir(parents=True, exist_ok=True)
    icons[0].save(
        ICO_PATH,
        format="ICO",
        sizes=[(icon.width, icon.height) for icon in icons],
        append_images=icons[1:],
    )
    print(f"Wrote {ICO_PATH}")


if __name__ == "__main__":
    main()
