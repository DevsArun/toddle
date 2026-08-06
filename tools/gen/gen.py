"""Generate lib/data/art_specs.dart from the Python picture definitions.

Run:  python3 /data/gen/gen.py /data/work/toddler_coloring
"""

import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from pics_a import MOVE, BIGTOP, LITTLE, HOUSE  # noqa: E402
from pics_b import SEASIDE, TOWN, OUTDOORS, CUTE  # noqa: E402
from pics_c import FARM, JUNGLE, OCEAN, SPACE  # noqa: E402
from pics_d import DINO, FOOD, MACHINES, SPORTS  # noqa: E402
from pics_e import MUSIC, WEATHER, FAIRY, GARDEN  # noqa: E402
from pics_f import PARTY, DRESSUP, SCHOOL, BIRDS  # noqa: E402
from pics_g import PETS, SHAPES, ABC, NUMBERS, BEDTIME, WINTER  # noqa: E402

# Order matters: this is the order the categories appear on the home screen.
CATEGORIES = [
    ("move", "On the Move", "\U0001F697", 0xFF64B5F6, MOVE),
    ("bigtop", "Big Top Fun", "\U0001F3AA", 0xFFF06292, BIGTOP),
    ("little", "Little Things", "\u2B50", 0xFFFFB74D, LITTLE),
    ("house", "Around the House", "\U0001F3E1", 0xFF81C784, HOUSE),
    ("seaside", "Sunny Seaside", "\U0001F41A", 0xFF4DB6AC, SEASIDE),
    ("town", "Busy Town", "\U0001F3EC", 0xFFBA68C8, TOWN),
    ("outdoors", "Great Outdoors", "\U0001F333", 0xFF66BB6A, OUTDOORS),
    ("cute", "Cute Friends", "\U0001F431", 0xFF7986CB, CUTE),
    ("farm", "Farm Friends", "\U0001F414", 0xFFFFB74D, FARM),
    ("jungle", "Jungle Animals", "\U0001F405", 0xFF66BB6A, JUNGLE),
    ("ocean", "Under the Sea", "\U0001F433", 0xFF4DB6AC, OCEAN),
    ("space", "Space Adventure", "\U0001F680", 0xFF7986CB, SPACE),
    ("dino", "Dinosaurs", "\U0001F996", 0xFF81C784, DINO),
    ("food", "Yummy Food", "\U0001F34E", 0xFFE57373, FOOD),
    ("machines", "Big Machines", "\U0001F69C", 0xFFFFB74D, MACHINES),
    ("sports", "Sports Day", "\u26BD", 0xFF64B5F6, SPORTS),
    ("music", "Music Time", "\U0001F3B5", 0xFFBA68C8, MUSIC),
    ("weather", "Weather & Sky", "\u26C5", 0xFF90CAF9, WEATHER),
    ("fairy", "Fairy Tale", "\U0001F984", 0xFFF06292, FAIRY),
    ("garden", "In the Garden", "\U0001F337", 0xFF81C784, GARDEN),
    ("party", "Party Time", "\U0001F389", 0xFFF06292, PARTY),
    ("dressup", "Dress Up", "\U0001F457", 0xFFBA68C8, DRESSUP),
    ("school", "School Day", "\u270F", 0xFF64B5F6, SCHOOL),
    ("birds", "Birds", "\U0001F426", 0xFF4DB6AC, BIRDS),
    ("pets", "My Pets", "\U0001F436", 0xFFFFB74D, PETS),
    ("shapes", "Shapes", "\U0001F536", 0xFFE57373, SHAPES),
    ("abc", "ABC Letters", "\U0001F524", 0xFF7986CB, ABC),
    ("numbers", "Numbers 1-20", "\U0001F522", 0xFF66BB6A, NUMBERS),
    ("bedtime", "Bedtime", "\U0001F319", 0xFF7986CB, BEDTIME),
    ("winter", "Winter Fun", "\u2744", 0xFF90CAF9, WINTER),
]

# One free picture in every category = 30 free pages, 570 behind the unlock.
FREE_PER_CATEGORY = [1] * 30

KIND = {"r": 0, "c": 1, "o": 2, "p": 3}


def num(v):
    f = float(v)
    if f == int(f):
        return str(int(f))
    return repr(round(f, 2))


def validate():
    seen = {}
    problems = []
    for cid, title, icon, color, pics in CATEGORIES:
        if len(pics) != 20:
            problems.append("category %s has %d pictures, expected 20" % (cid, len(pics)))
        for key, (name, parts) in pics.items():
            if key in seen:
                problems.append("duplicate shape key %r in %s and %s" % (key, seen[key], cid))
            seen[key] = cid
            if len(parts) < 3:
                problems.append("%s has only %d parts" % (key, len(parts)))
            for kind, vals, col in parts:
                if kind not in KIND:
                    problems.append("%s has unknown part kind %r" % (key, kind))
                if kind == "r" and len(vals) != 5:
                    problems.append("%s rrect needs 5 values" % key)
                if kind == "c" and len(vals) != 3:
                    problems.append("%s circle needs 3 values" % key)
                if kind == "o" and len(vals) != 4:
                    problems.append("%s oval needs 4 values" % key)
                if kind == "p" and (len(vals) < 6 or len(vals) % 2 != 0):
                    problems.append("%s polygon needs >= 3 points" % key)
                if not isinstance(col, int):
                    problems.append("%s has a non-integer color" % key)
    if problems:
        for p in problems:
            print("PROBLEM:", p)
        raise SystemExit(1)
    return len(seen)


def emit(root):
    total_shapes = validate()

    out = []
    out.append("// GENERATED FILE - do not edit by hand.")
    out.append("// Produced by tools/gen/gen.py. %d unique drawings." % total_shapes)
    out.append("//")
    out.append("// Every picture is a list of parts drawn back to front inside a")
    out.append("// 1000 x 1000 art space. Tap hit-testing walks the list from the top")
    out.append("// down, so small details listed last stay reachable.")
    out.append("")
    out.append("/// One fillable region of a drawing.")
    out.append("///")
    out.append("/// [kind] 0 = rounded rect, 1 = circle, 2 = oval, 3 = polygon.")
    out.append("class ArtPart {")
    out.append("  final int kind;")
    out.append("  final List<double> v;")
    out.append("  final int hint;")
    out.append("  const ArtPart(this.kind, this.v, this.hint);")
    out.append("}")
    out.append("")

    # Pictures
    out.append("const Map<String, List<ArtPart>> kArtParts = <String, List<ArtPart>>{")
    for cid, ctitle, icon, color, pics in CATEGORIES:
        out.append("  // ---- %s ----" % ctitle)
        for key, (name, parts) in pics.items():
            out.append("  '%s': <ArtPart>[" % key)
            for kind, vals, col in parts:
                nums = ", ".join(num(v) for v in vals)
                out.append(
                    "    ArtPart(%d, <double>[%s], 0x%08X)," % (KIND[kind], nums, col)
                )
            out.append("  ],")
    out.append("};")
    out.append("")

    # Titles
    out.append("const Map<String, String> kArtTitles = <String, String>{")
    for cid, ctitle, icon, color, pics in CATEGORIES:
        for key, (name, parts) in pics.items():
            out.append("  '%s': '%s'," % (key, name.replace("'", "\\'")))
    out.append("};")
    out.append("")

    # Category definitions
    out.append("/// Static description of one category, straight from the generator.")
    out.append("class CategorySpec {")
    out.append("  final String id;")
    out.append("  final String title;")
    out.append("  final String icon;")
    out.append("  final int color;")
    out.append("  final List<String> shapeKeys;")
    out.append("  final int freeCount;")
    out.append("  const CategorySpec(")
    out.append("      this.id, this.title, this.icon, this.color, this.shapeKeys, this.freeCount);")
    out.append("}")
    out.append("")
    out.append("const List<CategorySpec> kCategorySpecs = <CategorySpec>[")
    for i, (cid, ctitle, icon, color, pics) in enumerate(CATEGORIES):
        keys = ", ".join("'%s'" % k for k in pics.keys())
        out.append("  CategorySpec(")
        out.append("    '%s'," % cid)
        out.append("    '%s'," % ctitle)
        out.append("    '%s'," % icon)
        out.append("    0x%08X," % color)
        out.append("    <String>[%s]," % keys)
        out.append("    %d," % FREE_PER_CATEGORY[i])
        out.append("  ),")
    out.append("];")
    out.append("")

    path = os.path.join(root, "lib", "data", "art_specs.dart")
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w", encoding="utf-8") as fh:
        fh.write("\n".join(out))

    total_pages = sum(len(p) for _, _, _, _, p in CATEGORIES)
    total_free = sum(FREE_PER_CATEGORY)
    print("wrote %s" % path)
    print("categories   : %d" % len(CATEGORIES))
    print("unique shapes: %d" % total_shapes)
    print("total pages  : %d" % total_pages)
    print("free pages   : %d" % total_free)
    print("paid pages   : %d" % (total_pages - total_free))


if __name__ == "__main__":
    emit(sys.argv[1] if len(sys.argv) > 1 else "/data/work/toddler_coloring")
