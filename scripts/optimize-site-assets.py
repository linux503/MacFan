#!/usr/bin/env python3
"""Compress large showcase PNGs to web JPEGs for faster loading."""

from pathlib import Path

from PIL import Image

ASSETS = Path(__file__).resolve().parents[1] / "docs" / "assets"

# Large screenshots → JPEG (no alpha needed)
JPEG_TARGETS = [
    "hero-home",
    "poster-modes",
    "poster-scenes",
    "poster-og",
    "poster-dashboard",
    "poster-start",
]

QUALITY = 90


def optimize_png(path: Path) -> None:
    img = Image.open(path)
    if img.mode not in ("RGB", "RGBA"):
        img = img.convert("RGBA")
    img.save(path, "PNG", optimize=True, compress_level=9)


def png_to_jpg(name: str) -> None:
    src = ASSETS / f"{name}.png"
    dst = ASSETS / f"{name}.jpg"
    if not src.exists():
        print(f"skip {name}: no png")
        return
    img = Image.open(src).convert("RGB")
    img.save(dst, "JPEG", quality=QUALITY, optimize=True, progressive=True)
    src_kb = src.stat().st_size // 1024
    dst_kb = dst.stat().st_size // 1024
    print(f"{name}: PNG {src_kb} KB → JPG {dst_kb} KB")


def main() -> None:
    for name in ("logo-512", "logo"):
        p = ASSETS / f"{name}.png"
        if p.exists():
            optimize_png(p)
            print(f"optimized {name}.png ({p.stat().st_size // 1024} KB)")

    for name in JPEG_TARGETS:
        png_to_jpg(name)
        png = ASSETS / f"{name}.png"
        if png.exists():
            png.unlink()
            print(f"removed {name}.png")


if __name__ == "__main__":
    main()
