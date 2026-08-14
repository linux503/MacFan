#!/usr/bin/env python3
"""MacFan mark: vermillion impeller on ink squircle, plus menu-bar template."""

from __future__ import annotations

import math
import shutil
import subprocess
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter

ROOT = Path(__file__).resolve().parents[1]
RES = ROOT / "MacFan" / "Resources"
ICONSET = ROOT / "MacFan" / "Assets.xcassets" / "AppIcon.appiconset"
MENUBAR = ROOT / "MacFan" / "Assets.xcassets" / "MenuBarIcon.imageset"
DOCS = ROOT / "docs" / "assets"

MASTER = 1024
CX = CY = MASTER // 2

INK = (25, 27, 30)
INK_LIFT = (48, 52, 58)
INK_EDGE = (16, 17, 19)
VERMILLION = (226, 59, 46)
VERMILLION_DEEP = (176, 40, 32)
VERMILLION_HI = (240, 98, 84)
PINE = (31, 107, 82)
PINE_HI = (56, 140, 108)
ALUMINUM = (241, 242, 244)
ALUMINUM_DIM = (214, 218, 222)


def lerp(a: float, b: float, t: float) -> float:
    return a + (b - a) * t


def lerp_rgb(c1: tuple[int, int, int], c2: tuple[int, int, int], t: float) -> tuple[int, int, int]:
    t = max(0.0, min(1.0, t))
    return tuple(int(lerp(c1[i], c2[i], t)) for i in range(3))


def rounded_mask(size: int, radius: float) -> Image.Image:
    mask = Image.new("L", (size, size), 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, size - 1, size - 1), radius=radius, fill=255)
    return mask


def hard_light_bg(size: int) -> Image.Image:
    img = Image.new("RGB", (size, size))
    px = img.load()
    lx, ly = size * 0.28, size * 0.22
    r_max = size * 0.95
    for y in range(size):
        for x in range(size):
            d = math.hypot(x - lx, y - ly) / r_max
            shade = lerp_rgb(INK_LIFT, INK_EDGE, min(1.0, d ** 0.85))
            # slight cool falloff toward bottom-right
            t = (x + y) / (2 * size)
            shade = lerp_rgb(shade, INK, t * 0.22)
            px[x, y] = shade
    return img


def blade_poly(
    cx: float,
    cy: float,
    angle: float,
    r_hub: float,
    r_tip: float,
    width: float,
    sweep: float,
) -> list[tuple[float, float]]:
    leading: list[tuple[float, float]] = []
    trailing: list[tuple[float, float]] = []
    steps = 48
    for i in range(steps + 1):
        t = i / steps
        r = r_hub + (r_tip - r_hub) * (t ** 0.9)
        a = angle + sweep * (t ** 1.12)
        env = 0.16 + 0.84 * math.sin(math.pi * t) ** 0.58
        if t < 0.1:
            env *= (t / 0.1) ** 0.45
        w = width * env
        px = cx + math.cos(a) * r
        py = cy + math.sin(a) * r
        nx, ny = -math.sin(a), math.cos(a)
        camber = 0.55
        leading.append((px + nx * w, py + ny * w))
        trailing.append((px - nx * w * camber, py - ny * w * camber))
    tip_a = angle + sweep
    tip = (cx + math.cos(tip_a) * r_tip, cy + math.sin(tip_a) * r_tip)
    leading[-1] = tip
    trailing[-1] = tip
    return leading + list(reversed(trailing))


def draw_impeller(
    size: int,
    *,
    fill: tuple[int, int, int, int],
    edge: tuple[int, int, int, int] | None = None,
    hub_fill: tuple[int, int, int, int] | None = None,
    hub_core: tuple[int, int, int, int] | None = None,
    shroud: tuple[int, int, int, int] | None = None,
    simple: bool = False,
) -> Image.Image:
    layer = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(layer)
    cx = cy = size / 2
    s = size
    blades = 3
    r_hub = s * (0.16 if simple else 0.132)
    r_tip = s * (0.36 if simple else 0.392)
    width = s * (0.132 if simple else 0.108)
    sweep = 0.68 if simple else 0.72
    start = -math.pi / 2 - 0.18

    if shroud:
        r = s * (0.42 if simple else 0.438)
        w = max(2, int(s * (0.055 if simple else 0.028)))
        bbox = (cx - r, cy - r, cx + r, cy + r)
        draw.ellipse(bbox, outline=shroud, width=w)

    for i in range(blades):
        ang = start + i * (2 * math.pi / blades)
        pts = blade_poly(cx, cy, ang, r_hub, r_tip, width, sweep)
        draw.polygon(pts, fill=fill)
        tip_a = ang + sweep
        tx = cx + math.cos(tip_a) * r_tip
        ty = cy + math.sin(tip_a) * r_tip
        cap = max(2.0, width * 0.22)
        draw.ellipse((tx - cap, ty - cap, tx + cap, ty + cap), fill=fill)

    hub_r = s * (0.125 if simple else 0.118)
    hb = (cx - hub_r, cy - hub_r, cx + hub_r, cy + hub_r)
    if hub_fill:
        draw.ellipse(hb, fill=hub_fill)
        if not simple:
            draw.ellipse(hb, outline=fill, width=max(2, int(s * 0.01)))
    core_r = s * (0.048 if simple else 0.046)
    if hub_core:
        cb = (cx - core_r, cy - core_r, cx + core_r, cy + core_r)
        draw.ellipse(cb, fill=hub_core)
    return layer


def compose_icon(*, size: int = MASTER, transparent_bg: bool = False) -> Image.Image:
    simple = size <= 64
    canvas = size * 4

    if transparent_bg:
        base = Image.new("RGBA", (canvas, canvas), (0, 0, 0, 0))
    else:
        bg = hard_light_bg(max(size, 256)).resize((canvas, canvas), Image.Resampling.BILINEAR)
        base = bg.convert("RGBA")

    shadow = draw_impeller(canvas, fill=(0, 0, 0, 55), simple=simple)
    shadow = shadow.filter(ImageFilter.GaussianBlur(radius=max(1, canvas * 0.01)))
    offset = Image.new("RGBA", (canvas, canvas), (0, 0, 0, 0))
    offset.paste(shadow, (0, max(1, int(canvas * 0.01))), shadow)
    base = Image.alpha_composite(base, offset)

    fan = draw_impeller(
        canvas,
        fill=VERMILLION + (255,),
        edge=None,
        hub_fill=(VERMILLION if simple else PINE) + (255,),
        hub_core=ALUMINUM + (255,),
        shroud=ALUMINUM_DIM + (160,) if not simple else None,
        simple=simple,
    )
    base = Image.alpha_composite(base, fan)

    if not transparent_bg:
        radius = canvas * 0.223
        mask = rounded_mask(canvas, radius)
        out = Image.new("RGBA", (canvas, canvas), (0, 0, 0, 0))
        out.paste(base, (0, 0), mask)
        rim = Image.new("RGBA", (canvas, canvas), (0, 0, 0, 0))
        rd = ImageDraw.Draw(rim)
        pad = max(1, int(canvas * 0.01))
        rd.rounded_rectangle(
            (pad, pad, canvas - 1 - pad, canvas - 1 - pad),
            radius=max(1, radius - pad),
            outline=(255, 255, 255, 32),
            width=max(1, int(canvas * 0.005)),
        )
        base = Image.alpha_composite(out, rim)

    return base.resize((size, size), Image.Resampling.LANCZOS)


def compose_template(size: int) -> Image.Image:
    """Solid black template for the macOS menu bar."""
    scale = 8
    canvas = size * scale
    layer = draw_impeller(
        canvas,
        fill=(0, 0, 0, 255),
        hub_fill=(0, 0, 0, 255),
        hub_core=None,
        shroud=(0, 0, 0, 255),
        simple=True,
    )
    cx = cy = canvas / 2
    core_r = canvas * (0.055 if size <= 24 else 0.048)
    hole = Image.new("L", (canvas, canvas), 0)
    ImageDraw.Draw(hole).ellipse((cx - core_r, cy - core_r, cx + core_r, cy + core_r), fill=255)
    clear = Image.new("RGBA", (canvas, canvas), (0, 0, 0, 0))
    layer.paste(clear, (0, 0), hole)
    return layer.resize((size, size), Image.Resampling.LANCZOS)


def write_png(path: Path, img: Image.Image) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    img.convert("RGBA").save(path, "PNG", optimize=True)


def export_appicon(master: Image.Image) -> None:
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
        # redraw small sizes instead of crushing 1024
        if px <= 64:
            img = compose_icon(size=px)
        else:
            img = master.resize((px, px), Image.Resampling.LANCZOS)
        write_png(ICONSET / name, img)


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
        src = ICONSET / name
        if src.exists():
            shutil.copy2(src, iconset / name)
        else:
            write_png(iconset / name, master.resize((px, px), Image.Resampling.LANCZOS))

    icns_out = RES / "AppIcon.icns"
    subprocess.run(["iconutil", "-c", "icns", str(iconset), "-o", str(icns_out)], check=True)
    shutil.copy2(icns_out, ROOT / "AppIcon.icns")


def export_menubar() -> None:
    one = compose_template(22)
    two = compose_template(44)
    three = compose_template(66)
    write_png(MENUBAR / "MenuBarIcon-1x.png", one)
    write_png(MENUBAR / "MenuBarIcon-2x.png", two)
    write_png(MENUBAR / "MenuBarIcon-3x.png", three)
    write_png(RES / "MenuBarIcon@1x.png", one)
    write_png(RES / "MenuBarIcon.png", two)
    write_png(RES / "MenuBarIcon@3x.png", three)


def main() -> None:
    icon = compose_icon(size=MASTER, transparent_bg=False)
    logo = compose_icon(size=MASTER, transparent_bg=False)

    write_png(RES / "AppIcon-1024.png", icon)
    write_png(RES / "MacFan-logo.png", logo)
    write_png(ROOT / "MacFan-logo.png", logo.resize((512, 512), Image.Resampling.LANCZOS))
    write_png(DOCS / "logo.png", icon)
    write_png(DOCS / "logo-512.png", icon.resize((512, 512), Image.Resampling.LANCZOS))
    write_png(DOCS / "apple-touch-icon.png", icon.resize((180, 180), Image.Resampling.LANCZOS))

    export_appicon(icon)
    build_icns(icon)
    export_menubar()

    print("Generated MacFan logo + AppIcon + menu bar")
    for p in [
        RES / "AppIcon-1024.png",
        RES / "MacFan-logo.png",
        DOCS / "logo-512.png",
        RES / "AppIcon.icns",
        MENUBAR / "MenuBarIcon-2x.png",
    ]:
        kb = p.stat().st_size // 1024 if p.exists() else 0
        print(f"  {p.relative_to(ROOT)} ({kb} KB)")


if __name__ == "__main__":
    main()
