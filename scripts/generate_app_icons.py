#!/usr/bin/env python3
"""Generate circular SVG logo and macOS app icons from the source artwork."""

from __future__ import annotations

import base64
import re
from io import BytesIO
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
SVG_SOURCE = ROOT / "asset/image/Gemini_Generated_Image_i96t3ei96t3ei96t 1.svg"
SVG_LOGO = ROOT / "asset/image/app_logo.svg"
ICON_DIR = ROOT / "macos/Runner/Assets.xcassets/AppIcon.appiconset"

MAC_ICON_SIZES = {
    "app_icon_16.png": 16,
    "app_icon_32.png": 32,
    "app_icon_64.png": 64,
    "app_icon_128.png": 128,
    "app_icon_256.png": 256,
    "app_icon_512.png": 512,
    "app_icon_1024.png": 1024,
}


def extract_png_from_svg(svg_path: Path) -> Image.Image:
    data = svg_path.read_text(encoding="utf-8")
    match = re.search(r"xlink:href=\"data:image/png;base64,([^\"]+)\"", data)
    if not match:
        raise SystemExit(f"No embedded PNG found in {svg_path}")
    raw = base64.b64decode(match.group(1))
    return Image.open(BytesIO(raw)).convert("RGBA")


def extract_png_data_uri(svg_path: Path) -> str:
    data = svg_path.read_text(encoding="utf-8")
    match = re.search(r"(data:image/png;base64,[^\"]+)", data)
    if not match:
        raise SystemExit(f"No embedded PNG found in {svg_path}")
    return match.group(1)


def write_circular_svg(output_svg: Path, data_uri: str) -> None:
    """Write a square SVG with a true circular clip (not rounded square)."""
    output_svg.write_text(
    f"""<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" viewBox="0 0 1024 1024" fill="none">
  <defs>
    <clipPath id="logoCircle">
      <circle cx="512" cy="512" r="512"/>
    </clipPath>
  </defs>
  <g clip-path="url(#logoCircle)">
    <image xlink:href="{data_uri}" x="0" y="0" width="1024" height="1024" preserveAspectRatio="xMidYMid slice"/>
  </g>
</svg>
""",
        encoding="utf-8",
    )


def make_circular(image: Image.Image, size: int) -> Image.Image:
    """Center-crop to a filled circle."""
    width, height = image.size
    scale = max(size / width, size / height)
    resized = image.resize(
        (int(width * scale), int(height * scale)),
        Image.Resampling.LANCZOS,
    )
    left = (resized.width - size) // 2
    top = (resized.height - size) // 2
    square = resized.crop((left, top, left + size, top + size))

    mask = Image.new("L", (size, size), 0)
    draw = ImageDraw.Draw(mask)
    draw.ellipse((0, 0, size - 1, size - 1), fill=255)
    square.putalpha(mask)
    return square


def main() -> None:
    if not SVG_SOURCE.exists():
        raise SystemExit(f"Source SVG not found: {SVG_SOURCE}")

    data_uri = extract_png_data_uri(SVG_SOURCE)
    SVG_LOGO.parent.mkdir(parents=True, exist_ok=True)
    write_circular_svg(SVG_LOGO, data_uri)

    source = extract_png_from_svg(SVG_SOURCE)
    ICON_DIR.mkdir(parents=True, exist_ok=True)
    for filename, icon_size in MAC_ICON_SIZES.items():
        make_circular(source, icon_size).save(ICON_DIR / filename, format="PNG", optimize=True)

    print(f"Wrote {SVG_LOGO}")
    print(f"Wrote {len(MAC_ICON_SIZES)} icons to {ICON_DIR}")


if __name__ == "__main__":
    main()
