"""Primitives for authoring the 160 coloring pictures.

Everything is defined in a 1000 x 1000 art space. Parts are listed back to
front: the first part is the furthest layer, the last part is on top. Tap
hit-testing searches from the top down, so small details placed last are always
reachable.
"""

import math

RED = 0xFFE57373
ORANGE = 0xFFFFB74D
YELLOW = 0xFFFFF176
GREEN = 0xFF81C784
LEAF = 0xFF66BB6A
TEAL = 0xFF4DB6AC
BLUE = 0xFF64B5F6
SKY = 0xFF90CAF9
INDIGO = 0xFF7986CB
PURPLE = 0xFFBA68C8
PINK = 0xFFF06292
ROSE = 0xFFF8BBD0
BROWN = 0xFFA1887F
WOOD = 0xFFBCAAA4
GREY = 0xFFB0BEC5
WHITE = 0xFFFAFAFA
DARK = 0xFF546E7A
CREAM = 0xFFFFE0B2
SAND = 0xFFFFCC80
BLACK = 0xFF757575
SILVER = 0xFFCFD8DC


def rr(l, t, r, b, rad, col):
    """Rounded rectangle."""
    return ("r", [l, t, r, b, rad], col)


def ci(x, y, rad, col):
    """Circle."""
    return ("c", [x, y, rad], col)


def ov(l, t, r, b, col):
    """Oval inscribed in a rectangle."""
    return ("o", [l, t, r, b], col)


def po(points, col):
    """Closed polygon from a list of (x, y) pairs."""
    flat = []
    for x, y in points:
        flat.append(x)
        flat.append(y)
    return ("p", flat, col)


# ----------------------------------------------------------------- motifs


def ground(col=GREEN, top=830):
    return rr(0, top, 1000, 950, 30, col)


def water(col=BLUE, top=740):
    return rr(0, top, 1000, 950, 30, col)


def sun(x=840, y=170, rad=90, col=YELLOW):
    return ci(x, y, rad, col)


def wheels(y, left, right, rad=95, tyre=BLACK, hub=SILVER):
    return [
        ci(left, y, rad, tyre),
        ci(right, y, rad, tyre),
        ci(left, y, round(rad * 0.42, 1), hub),
        ci(right, y, round(rad * 0.42, 1), hub),
    ]


def eyes(lx, rx, y, rad=34, col=WHITE, pupil=DARK):
    return [
        ci(lx, y, rad, col),
        ci(rx, y, rad, col),
        ci(lx, y, round(rad * 0.45, 1), pupil),
        ci(rx, y, round(rad * 0.45, 1), pupil),
    ]


def star(cx, cy, outer, inner, col):
    pts = []
    for i in range(10):
        radius = outer if i % 2 == 0 else inner
        angle = -math.pi / 2 + i * math.pi / 5
        pts.append(
            (
                round(cx + radius * math.cos(angle), 1),
                round(cy + radius * math.sin(angle), 1),
            )
        )
    return po(pts, col)
