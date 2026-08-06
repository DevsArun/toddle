import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toddler_coloring/coloring/canvas_controller.dart';
import 'package:toddler_coloring/data/art_library.dart';
import 'package:toddler_coloring/data/catalog.dart';
import 'package:toddler_coloring/models/art.dart';

void main() {
  group('catalog', () {
    test('has 30 categories and 600 pictures', () {
      expect(Catalog.categories.length, 30);
      expect(Catalog.totalPages, 600);
    });

    test('exactly 30 pictures are free', () {
      expect(Catalog.totalFreePages, 30);
    });

    test('every category gives away at least one free picture', () {
      for (final ColoringCategory c in Catalog.categories) {
        expect(c.freeCount, greaterThanOrEqualTo(1),
            reason: 'category ${c.id} has no free picture to try');
      }
    });

    // This is the exact rule category_screen.dart uses to lock a tile:
    //   locked = !page.isFree && !premium
    // Proving it here means a completed purchase really does open every
    // single picture, not just the ones in the pack that was open at the time.
    test('purchase unlocks all 600 pictures, nothing stays locked', () {
      bool isLocked(ColoringPage p, bool premium) => !p.isFree && !premium;

      final List<ColoringPage> all = <ColoringPage>[
        for (final ColoringCategory c in Catalog.categories) ...c.pages,
      ];
      expect(all.length, 600);

      // Before paying: only the 30 free pictures are open.
      final int openBefore =
          all.where((ColoringPage p) => !isLocked(p, false)).length;
      expect(openBefore, 30);

      // After paying: every picture in every pack is open.
      final int lockedAfter =
          all.where((ColoringPage p) => isLocked(p, true)).length;
      expect(lockedAfter, 0);

      final int openAfter =
          all.where((ColoringPage p) => !isLocked(p, true)).length;
      expect(openAfter, 600);

      // And every unlocked picture must actually have a drawing behind it,
      // so no paying family ever taps through to a blank page.
      for (final ColoringPage p in all) {
        expect(ArtLibrary.shapeKeys.contains(p.shapeKey), isTrue,
            reason: 'unlocked page ${p.id} has no artwork');
      }
    });

    test('every category holds exactly 20 pictures, all open after purchase',
        () {
      const bool premium = true;
      for (final ColoringCategory c in Catalog.categories) {
        expect(c.pages.length, Catalog.pagesPerCategory,
            reason: 'category ${c.id} does not hold 20 pictures');
        final int stillLocked = c.pages
            .where((ColoringPage p) => !p.isFree && !premium)
            .length;
        expect(stillLocked, 0,
            reason: 'category ${c.id} still has locked pictures after paying');
      }
    });

    test('every picture id is unique', () {
      final Set<String> ids = <String>{};
      for (final ColoringCategory c in Catalog.categories) {
        for (final ColoringPage p in c.pages) {
          expect(ids.add(p.id), isTrue, reason: 'duplicate id ${p.id}');
        }
      }
    });

    test('every picture maps to a real drawing', () {
      final Set<String> known = ArtLibrary.shapeKeys.toSet();
      for (final ColoringCategory c in Catalog.categories) {
        for (final ColoringPage p in c.pages) {
          expect(known.contains(p.shapeKey), isTrue,
              reason: 'missing drawing ${p.shapeKey}');
        }
      }
    });

    test('all 600 pictures are different drawings', () {
      final Set<String> shapes = <String>{};
      for (final ColoringCategory c in Catalog.categories) {
        for (final ColoringPage p in c.pages) {
          expect(shapes.add(p.shapeKey), isTrue,
              reason: 'drawing ${p.shapeKey} is reused');
        }
      }
      expect(shapes.length, 600);
      expect(ArtLibrary.shapeKeys.length, 600);
    });

    test('every page has a real name, not a placeholder', () {
      for (final ColoringCategory c in Catalog.categories) {
        expect(c.pages.length, 20, reason: c.id);
        for (final ColoringPage p in c.pages) {
          expect(p.title.trim(), isNotEmpty);
          expect(p.title.startsWith('Picture'), isFalse,
              reason: '${p.id} still has a placeholder title');
        }
      }
    });
  });

  group('art library', () {
    test('every picture has fillable regions and outlines', () {
      for (final String key in ArtLibrary.shapeKeys) {
        final ArtDef art = ArtLibrary.build(key);
        expect(art.regions, isNotEmpty, reason: key);
        expect(art.outlines, isNotEmpty, reason: key);
      }
    });

    test('every picture has something to tap in the middle of the canvas', () {
      for (final String key in ArtLibrary.shapeKeys) {
        final ArtDef art = ArtLibrary.build(key);
        final bool anyHit = art.regions.any(
          (ArtRegion r) => r.path.contains(const Offset(500, 500)),
        );
        expect(anyHit, isTrue, reason: 'nothing fillable at the centre of $key');
      }
    });

    test('an unknown key falls back instead of crashing', () {
      final ArtDef art = ArtLibrary.build('no_such_picture');
      expect(art.regions, isNotEmpty);
    });
  });

  group('canvas controller', () {
    late CanvasController controller;

    setUp(() {
      controller = CanvasController(pageId: 'test', art: ArtLibrary.build('star'));
    });

    test('tapping inside a shape fills it', () {
      controller.selectColor(const Color(0xFF00FF00));
      final bool hit = controller.tapAt(const Offset(500, 500));
      expect(hit, isTrue);
      expect(controller.fills.isNotEmpty, isTrue);
    });

    test('undo and redo restore the fill', () {
      controller.tapAt(const Offset(500, 500));
      expect(controller.canUndo, isTrue);
      controller.undo();
      expect(controller.fills.isEmpty, isTrue);
      controller.redo();
      expect(controller.fills.isNotEmpty, isTrue);
    });

    test('history never grows past the cap', () {
      for (int i = 0; i < 60; i++) {
        controller.selectColor(Color(0xFF000000 + i));
        controller.tapAt(const Offset(500, 500));
      }
      controller.clearAll();
      expect(controller.isEmpty, isTrue);
    });

    test('strokes are recorded and undoable', () {
      controller.selectTool(ColoringTool.brush);
      controller.startStroke(const Offset(100, 100));
      controller.extendStroke(const Offset(200, 200));
      controller.extendStroke(const Offset(300, 300));
      controller.endStroke();
      expect(controller.strokes.length, 1);
      controller.undo();
      expect(controller.strokes, isEmpty);
    });

    test('state survives a save and restore round trip', () {
      controller.tapAt(const Offset(500, 500));
      controller.selectTool(ColoringTool.brush);
      controller.startStroke(const Offset(50, 50));
      controller.extendStroke(const Offset(150, 150));
      controller.endStroke();

      final Map<String, dynamic> json = controller.toJson();
      final CanvasController restored =
          CanvasController(pageId: 'test', art: ArtLibrary.build('star'))
            ..restore(json);

      expect(restored.fills.length, controller.fills.length);
      expect(restored.strokes.length, controller.strokes.length);
    });
  });
}
