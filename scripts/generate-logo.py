#!/usr/bin/env python3
"""Generate MacFan logo & app icon — large turbine, Signal Night palette."""

from __future__ import annotations

import math
import os
import subprocess
import struct
import zlib
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter

ROOT = Path(__file__).resolve().parents[1]
RES = ROOT / "MacFan" / "Resources"
ICONSET = ROOT / "MacFan" / "Assets.xcassets" / "AppIcon.appiconset"
DOCS = ROOT / "docs" / "assets"

SIZE = 1024
CX = CY = SIZE // 2

# Signal Night
INK = (7, 11, 18)
INK_LIFT = (13, 20, 32)
CANVAS = (18, 26, 40)
ACCENT = (79, 156, 255)
ACCENT_HI = (126, 200, 255)
ACCENT_DEEP = (46, 107, 196)
AMBER = (224, 163, 90)
MIST = (139, 151, 171)


def lerp(a: float, b: float, t: float) -> float:
    return a + (b - a) * t


def lerp_rgb(c1: tuple[int, int, int], c2: tuple[int, int, int], t: float) -> tuple[int, int, int]:
    return tuple(int(lerp(c1[i], c2[i], t)) for i in range(3))


def radial_gradient(size: int, inner: tuple[int, int, int], outer: tuple[int, int, int]) -> Image.Image:
    img = Image.new("RGB", (size, size))
    px = img.load()
    r_max = size * 0.72
    for y in range(size):
        for x in range(size):
            d = math.hypot(x - CX, y - CY)
            t = min(1.0, d / r_max)
            px[x, y] = lerp_rgb(inner, outer, t)
    return img


def rounded_rect_mask(size: int, radius: int) -> Image.Image:
    mask = Image.new("L", (size, size), 0)
    draw = ImageDraw.Draw(mask)
    draw.rounded_rectangle((0, 0, size - 1, size - 1), radius=radius, fill=255)
    return mask


def blade_polygon(cx: float, cy: float, angle: float, length: float, width: float) -> list[tuple[float, float]]:
    """Curved turbine blade pointing at angle (radians)."""
    tip_x = cx + math.cos(angle) * length
    tip_y = cy + math.sin(angle) * length
    mid_x = cx + math.cos(angle) * (length * 0.55)
    mid_y = cy + math.sin(angle) * (length * 0.55)
    perp = angle + math.pi / 2
    w0 = width * 0.22
    w1 = width * 0.95
    w2 = width * 0.08
    base_a = angle + math.pi
    bx = cx + math.cos(base_a) * (length * 0.12)
    by = cy + math.sin(base_a) * (length * 0.12)
    return [
        (bx, by),
        (mid_x + math.cos(perp) * w0, mid_y + math.sin(perp) * w0),
        (tip_x + math.cos(perp) * w1, tip_y + math.sin(perp) * w1),
        (tip_x + math.cos(angle + math.pi * 0.92) * (length * 0.08), tip_y + math.sin(angle + math.pi * 0.92) * (length * 0.08)),
        (tip_x - math.cos(perp) * w1, tip_y - math.sin(perp) * w1),
        (mid_x - math.cos(perp) * w0, mid_y - math.sin(perp) * w0),
    ]


def draw_fan_layer(size: int, blade_len: float, blade_w: float, alpha: int = 255) -> Image.Image:
    layer = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(layer)
    blades = 5
    for i in range(blades):
        angle = (2 * math.pi / blades) * i - math.pi / 2
        t = i / blades
        fill = lerp_rgb(ACCENT_DEEP, ACCENT_HI, 0.25 + 0.75 * t) + (alpha,)
        pts = blade_polygon(CX, CY, angle, blade_len, blade_w)
        draw.polygon(pts, fill=fill)
        # Blade edge highlight
        tip = pts[2]
        draw.line([pts[1], tip], fill=ACCENT_HI + (min(255, alpha + 40),), width=max(2, int(size * 0.006)))
    return layer


def draw_gauge_ring(size: int, radius: float, width: float) -> Image.Image:
    layer = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(layer)
    bbox = (CX - radius, CY - radius, CX + radius, CY + radius)
    # Main arc ~300deg
    draw.arc(bbox, start=120, end=420, fill=ACCENT + (180,), width=int(width))
    # Amber hot segment
    draw.arc(bbox, start=350, end=30, fill=AMBER + (255,), width=int(width * 1.15))
    # Tick marks
    for deg in range(120, 421, 18):
        a = math.radians(deg)
        r0 = radius - width * 0.3
        r1 = radius + width * 0.35
        draw.line(
            [(CX + math.cos(a) * r0, CY + math.sin(a) * r0), (CX + math.cos(a) * r1, CY + math.sin(a) * r1)],
            fill=ACCENT_HI + (120,),
            width=max(1, int(size * 0.004)),
        )
    return layer


def draw_center_hub(size: int, radius: float) -> Image.Image:
    layer = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(layer)
    bbox = (CX - radius, CY - radius, CX + radius, CY + radius)
    draw.ellipse(bbox, fill=INK_LIFT + (255,))
    draw.ellipse(bbox, outline=ACCENT + (220,), width=max(3, int(size * 0.012)))
    inner = radius * 0.38
    ib = (CX - inner, CY - inner, CX + inner, CY + inner)
    draw.ellipse(ib, fill=CANVAS + (255,))
    draw.ellipse(ib, outline=ACCENT_DEEP + (180,), width=max(2, int(size * 0.006)))
    return layer


def compose_icon(*, transparent_bg: bool = False) -> Image.Image:
    if transparent_bg:
        base = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    else:
        base = radial_gradient(SIZE, (22, 34, 54), INK).convert("RGBA")
        glow = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
        gd = ImageDraw.Draw(glow)
        gd.ellipse((CX - 420, CY - 420, CX + 420, CY + 420), fill=ACCENT + (28,))
        glow = glow.filter(ImageFilter.GaussianBlur(radius=48))
        base = Image.alpha_composite(base, glow)

    # Large fan — ~82% of canvas
    blade_len = SIZE * 0.41
    blade_w = SIZE * 0.17

    ring = draw_gauge_ring(SIZE, radius=SIZE * 0.44, width=SIZE * 0.028)
    ring_blur = ring.filter(ImageFilter.GaussianBlur(radius=6))
    base = Image.alpha_composite(base, ring_blur)
    base = Image.alpha_composite(base, ring)

    fan_back = draw_fan_layer(SIZE, blade_len * 1.02, blade_w * 1.05, alpha=70)
    fan_back = fan_back.filter(ImageFilter.GaussianBlur(radius=10))
    base = Image.alpha_composite(base, fan_back)

    fan = draw_fan_layer(SIZE, blade_len, blade_w, alpha=255)
    base = Image.alpha_composite(base, fan)

    hub = draw_center_hub(SIZE, radius=SIZE * 0.095)
    base = Image.alpha_composite(base, hub)

    if not transparent_bg:
        mask = rounded_rect_mask(SIZE, radius=int(SIZE * 0.223))
        out = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
        out.paste(base, (0, 0), mask)
        return out
    return base


def write_png(path: Path, img: Image.Image) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    if img.mode != "RGBA":
        img = img.convert("RGBA")
    img.save(path, "PNG", optimize=True)


def export_sizes(master: Image.Image) -> None:
    sizes = {
        "icon_16x16.png": 16,
        "icon_16x16@2x.png": 32,
        "icon_32x32.png": 32,
        "icon_32x32@2x.png": 64,
        "icon_128x128.png": 128,
        "icon_128x128@2x.png": 256,
        "icon_256x256.png": 256,
        "icon_256x256@2x.png": 512,
        "icon_512x512.png": 512,
        "icon_512x512@2x.png": 1024,
    }
    for name, px in sizes.items():
        write_png(ICONSET / name, master.resize((px, px), Image.Resampling.LANCZOS))


def build_icns(master: Image.Image) -> None:
    iconset = ROOT / ".build" / "MacFan.iconset"
    if iconset.exists():
        for f in iconset.iterdir():
            f.unlink()
    else:
        iconset.mkdir(parents=True)

    mapping = {
        "icon_16x16.png": 16,
        "icon_16x16@2x.png": 32,
        "icon_32x32.png": 32,
        "icon_32x32@2x.png": 64,
        "icon_128x128.png": 128,
        "icon_128x128@2x.png": 256,
        "icon_256x256.png": 256,
        "icon_256x256@2x.png": 512,
        "icon_512x512.png": 512,
        "icon_512x512@2x.png": 1024,
    }
    for name, px in mapping.items():
        write_png(iconset / name, master.resize((px, px), Image.Resampling.LANCZOS))

    icns_out = RES / "AppIcon.icns"
    subprocess.run(["iconutil", "-c", "icns", str(iconset), "-o", str(icns_out)], check=True)
    import shutil
    shutil.copy2(icns_out, ROOT / "AppIcon.icns")


def main() -> None:
    icon = compose_icon(transparent_bg=False)
    logo = compose_icon(transparent_bg=True)

    write_png(RES / "AppIcon-1024.png", icon)
    write_png(RES / "MacFan-logo.png", logo)
    write_png(DOCS / "logo-512.png", icon.resize((512, 512), Image.Resampling.LANCZOS))
    write_png(DOCS / "logo.png", icon.resize((1024, 1024), Image.Resampling.LANCZOS))

    export_sizes(icon)
    build_icns(icon)

    print("Generated MacFan logo + AppIcon sizes")
    for p in [RES / "AppIcon-1024.png", RES / "MacFan-logo.png", DOCS / "logo-512.png", RES / "AppIcon.icns"]:
        kb = p.stat().st_size // 1024 if p.exists() else 0
        print(f"  {p.relative_to(ROOT)} ({kb} KB)")


if __name__ == "__main__":
    main()
