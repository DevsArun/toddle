# Artwork

## What ships in this build

- **30 categories x 20 pages = 600 pages**
- **600 different drawings.** No picture is repeated anywhere in the app.
- **30 free pages** (one in every pack), 570 unlocked by the one time purchase.
- Every page has a real name (Fire Engine, Lighthouse, Hedgehog), not "Picture 7".

This replaces the earlier build, which filled its slots by repeating the
same 10 drawings sixteen times each.

## How the pictures are stored

Each drawing is plain geometry inside a 1000 x 1000 art space: rounded
rectangles, circles, ovals and polygons. There are no image files at all.

That choice matters for this app:

- The APK stays tiny, which helps on entry level Fire tablets.
- Pictures stay perfectly sharp on every screen size and in both orientations.
- Memory use is negligible, so the grid of thumbnails scrolls smoothly.
- Colouring works by hit testing the shapes, so a tap always lands on a real
  fillable region.

## Where they live

| File | Role |
| --- | --- |
| tools/gen/prim.py | Drawing primitives and shared motifs |
| tools/gen/pics_a.py | 80 pictures: On the Move, Big Top Fun, Little Things, Around the House |
| tools/gen/pics_b.py | 80 pictures: Sunny Seaside, Busy Town, Great Outdoors, Cute Friends |
| tools/gen/gen.py | Validates everything and writes the Dart file |
| lib/data/art_specs.dart | GENERATED. Do not edit by hand |
| lib/data/art_library.dart | Turns the specs into paintable paths |
| lib/data/catalog.dart | Builds the categories and pages from the specs |

To change or add artwork, edit the Python files and regenerate:

    python3 tools/gen/gen.py .

The generator refuses to write the file if a category does not have exactly 20
pictures, if a shape key is duplicated, or if a picture has malformed geometry.

## Honest limitation

These are clean, bright, geometric illustrations. They are all different and
they are genuinely usable, but they are not hand illustrated character art. If
you later commission richer artwork, only the picture definitions need to
change. The colouring engine, the categories, the free/paid split and the
purchase flow all stay exactly as they are.
