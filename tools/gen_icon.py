#!/usr/bin/env python3
"""Generates the launcher icon for Baby Coloring: Toddler Games.

A bunch of rainbow crayons fanned out over a warm circle.

The fan is drawn on an oversized scratch canvas, cropped to its real bounding
box and only then scaled into the disc. That is what keeps the crayon tips from
ever being clipped and keeps the artwork optically centred, whatever the fan
angles are.

Run it from the project root:

    python3 tools/gen_icon.py
"""
import math
import os
import sys

from PIL import Image, ImageDraw, ImageFilter

SS = 4  # supersample factor, everything is drawn big and shrunk down

BG_TOP = (255, 246, 224)
BG_BOTTOM = (255, 205, 152)
DISC = (255, 253, 248)
DISC_EDGE = (255, 176, 59)

CRAYONS = [
    (229, 57, 53),    # red
    (245, 124, 0),    # orange
    (251, 192, 45),   # yellow
    (56, 142, 60),    # green
    (25, 118, 210),   # blue
    (142, 36, 170),   # purple
]


def lighten(rgb, amount):
    return tuple(int(c + (255 - c) * amount) for c in rgb)


def vertical_gradient(size, top, bottom):
    grad = Image.new("RGB", (1, size))
    px = grad.load()
    for y in range(size):
        t = y / max(1, size - 1)
        px[0, y] = (
            int(top[0] + (bottom[0] - top[0]) * t),
            int(top[1] + (bottom[1] - top[1]) * t),
            int(top[2] + (bottom[2] - top[2]) * t),
        )
    return grad.resize((size, size), Image.NEAREST)


def draw_crayon(length, width, colour):
    """One upright crayon, tip pointing up, on its own transparent layer."""
    pad = width
    layer = Image.new("RGBA", (width + pad * 2, length + pad * 2), (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)

    left, right = pad, pad + width
    top, bottom = pad, pad + length
    tip_h = width * 0.9
    body_top = top + tip_h

    # Waxy body first, so the tip overlaps it cleanly.
    d.rounded_rectangle([left, body_top, right, bottom],
                        radius=width * 0.30, fill=colour)
    # Sharpened tip.
    d.polygon([(left + width / 2.0, top), (right, body_top + 1), (left, body_top + 1)],
              fill=lighten(colour, 0.30))
    # Paper wrapper.
    band_top = body_top + length * 0.16
    band_bottom = bottom - length * 0.14
    d.rounded_rectangle([left, band_top, right, band_bottom],
                        radius=width * 0.16, fill=lighten(colour, 0.60))
    # Wrapper edge stripes.
    for frac in (0.0, 1.0):
        y = band_top + (band_bottom - band_top) * frac
        d.rounded_rectangle([left, y - width * 0.075, right, y + width * 0.075],
                            radius=width * 0.075, fill=colour)
    # Highlight down the left side.
    d.rounded_rectangle(
        [left + width * 0.16, body_top + width * 0.35,
         left + width * 0.34, bottom - width * 0.30],
        radius=width * 0.09, fill=lighten(colour, 0.45),
    )
    return layer


def fan_layer(unit):
    """The whole crayon fan, cropped tight to its own artwork.

    `unit` is a nominal size; the result is cropped so callers must scale it.
    """
    s = unit * 3
    canvas = Image.new("RGBA", (s, s), (0, 0, 0, 0))
    cx = cy = s / 2.0

    length = int(unit * 1.15)
    width = int(unit * 0.26)
    spread = 19.0          # degrees between neighbouring crayons
    pivot = unit * 0.52    # how far the fan radiates from the pivot point

    n = len(CRAYONS)
    order = sorted(range(n), key=lambda i: -abs(i - (n - 1) / 2.0))

    for i in order:
        angle = (i - (n - 1) / 2.0) * spread
        rotated = draw_crayon(length, width, CRAYONS[i]).rotate(
            -angle, resample=Image.BICUBIC, expand=True)
        rad = math.radians(angle)
        px = int(cx + math.sin(rad) * pivot - rotated.width / 2.0)
        py = int(cy - math.cos(rad) * pivot - rotated.height / 2.0)
        canvas.alpha_composite(rotated, (px, py))

    bbox = canvas.getbbox()
    return canvas.crop(bbox)


def place_fan(base, box_w, box_h, centre_x, centre_y, shadow=True):
    """Scales the fan to fit box_w x box_h and centres it on the base image."""
    fan = fan_layer(int(max(box_w, box_h)))
    scale = min(box_w / fan.width, box_h / fan.height)
    fan = fan.resize((max(1, int(fan.width * scale)),
                      max(1, int(fan.height * scale))), Image.LANCZOS)

    x = int(centre_x - fan.width / 2.0)
    y = int(centre_y - fan.height / 2.0)

    if shadow:
        blur = max(1.0, base.width * 0.012)
        sh = Image.new("RGBA", base.size, (0, 0, 0, 0))
        tinted = Image.new("RGBA", fan.size, (120, 70, 20, 90))
        tinted.putalpha(Image.eval(fan.split()[3], lambda a: int(a * 0.38)))
        sh.alpha_composite(tinted, (x, y + int(base.width * 0.012)))
        base.alpha_composite(sh.filter(ImageFilter.GaussianBlur(blur)))

    base.alpha_composite(fan, (x, y))
    return base


def build_full_icon(size):
    """Background plus crayons as one opaque square icon."""
    s = size * SS
    icon = vertical_gradient(s, BG_TOP, BG_BOTTOM).convert("RGBA")
    d = ImageDraw.Draw(icon)

    m = s * 0.085
    d.ellipse([m, m, s - m, s - m], fill=DISC_EDGE)
    m2 = s * 0.115
    d.ellipse([m2, m2, s - m2, s - m2], fill=DISC)

    # Keep the fan comfortably inside the white disc.
    inner = s - 2 * m2
    place_fan(icon, inner * 0.86, inner * 0.86, s / 2.0, s / 2.0)
    return icon.resize((size, size), Image.LANCZOS).convert("RGB")


def build_adaptive_foreground(size):
    """Adaptive icons crop hard, so everything sits inside the safe circle."""
    s = size * SS
    layer = Image.new("RGBA", (s, s), (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    m = s * 0.255
    d.ellipse([m, m, s - m, s - m], fill=DISC)
    inner = s - 2 * m
    place_fan(layer, inner * 0.84, inner * 0.84, s / 2.0, s / 2.0)
    return layer.resize((size, size), Image.LANCZOS)


DENSITIES = [
    ("mipmap-mdpi", 48),
    ("mipmap-hdpi", 72),
    ("mipmap-xhdpi", 96),
    ("mipmap-xxhdpi", 144),
    ("mipmap-xxxhdpi", 192),
]

ADAPTIVE_XML = """<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@color/ic_launcher_background" />
    <foreground android:drawable="@drawable/ic_launcher_fg" />
</adaptive-icon>
"""

COLORS_XML = """<?xml version="1.0" encoding="utf-8"?>
<resources>
    <color name="ic_launcher_background">#FFF1D4</color>
</resources>
"""


def main():
    root = sys.argv[1] if len(sys.argv) > 1 else "."
    res = os.path.join(root, "android_overlay", "app", "src", "main", "res")
    store = os.path.join(root, "store")
    written = []

    for folder, px in DENSITIES:
        out_dir = os.path.join(res, folder)
        os.makedirs(out_dir, exist_ok=True)
        icon = build_full_icon(px)
        for name in ("ic_launcher.png", "ic_launcher_round.png"):
            path = os.path.join(out_dir, name)
            icon.save(path, "PNG", optimize=True)
            written.append(path)

    draw_dir = os.path.join(res, "drawable")
    os.makedirs(draw_dir, exist_ok=True)
    fg_path = os.path.join(draw_dir, "ic_launcher_fg.png")
    build_adaptive_foreground(432).save(fg_path, "PNG", optimize=True)
    written.append(fg_path)

    any_dir = os.path.join(res, "mipmap-anydpi-v26")
    os.makedirs(any_dir, exist_ok=True)
    for name in ("ic_launcher.xml", "ic_launcher_round.xml"):
        path = os.path.join(any_dir, name)
        with open(path, "w", encoding="utf-8") as f:
            f.write(ADAPTIVE_XML)
        written.append(path)

    val_dir = os.path.join(res, "values")
    os.makedirs(val_dir, exist_ok=True)
    col_path = os.path.join(val_dir, "ic_launcher_colors.xml")
    with open(col_path, "w", encoding="utf-8") as f:
        f.write(COLORS_XML)
    written.append(col_path)

    os.makedirs(store, exist_ok=True)
    for px, name in ((512, "icon_512.png"), (114, "icon_114.png")):
        path = os.path.join(store, name)
        build_full_icon(px).save(path, "PNG", optimize=True)
        written.append(path)

    for p in written:
        print("wrote", os.path.relpath(p, root))
    print("\n%d files" % len(written))


if __name__ == "__main__":
    main()
