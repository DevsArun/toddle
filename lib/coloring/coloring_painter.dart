import 'package:flutter/material.dart';

import '../app_theme.dart';
import '../models/art.dart';
import 'canvas_controller.dart';

/// Paints one picture: paper, fills, child strokes, then the black outline.
class ColoringPainter extends CustomPainter {
  ColoringPainter({required this.controller}) : super(repaint: controller);

  final CanvasController controller;

  @override
  void paint(Canvas canvas, Size size) {
    final double scale = size.shortestSide / ArtDef.space;

    final Paint paper = Paint()..color = AppTheme.paper;
    canvas.drawRect(Offset.zero & size, paper);

    canvas.save();
    canvas.scale(scale);
    canvas.clipRect(const Rect.fromLTWH(0, 0, ArtDef.space, ArtDef.space));

    final ArtDef art = controller.art;

    // 1. Flat region fills.
    final Paint fillPaint = Paint()..style = PaintingStyle.fill;
    for (int i = 0; i < art.regions.length; i++) {
      final Color? c = controller.fills[i];
      if (c == null) continue;
      fillPaint.color = c;
      canvas.drawPath(art.regions[i].path, fillPaint);
    }

    // 2. Freehand strokes on top of the fills.
    for (final Stroke s in controller.strokes) {
      _drawStroke(canvas, s);
    }
    final Stroke? active = controller.activeStroke;
    if (active != null) {
      _drawStroke(canvas, active);
    }

    // 3. The line art always stays visible.
    final Paint outline = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFF2B2B2B);
    for (final Path p in art.outlines) {
      canvas.drawPath(p, outline);
    }

    canvas.restore();
  }

  void _drawStroke(Canvas canvas, Stroke s) {
    if (s.points.isEmpty) return;
    final Paint paint = Paint()
      ..color = s.color
      ..strokeWidth = s.width
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true;

    if (s.points.length == 1) {
      canvas.drawCircle(s.points.first, s.width / 2, paint..style = PaintingStyle.fill);
      return;
    }

    final Path path = Path()..moveTo(s.points.first.dx, s.points.first.dy);
    for (int i = 1; i < s.points.length; i++) {
      path.lineTo(s.points[i].dx, s.points[i].dy);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant ColoringPainter oldDelegate) => true;
}

/// Small, cheap preview used in the picture grid.
class ThumbnailPainter extends CustomPainter {
  const ThumbnailPainter({required this.art, required this.showColor});

  final ArtDef art;
  final bool showColor;

  @override
  void paint(Canvas canvas, Size size) {
    final double scale = size.shortestSide / ArtDef.space;
    canvas.drawRect(Offset.zero & size, Paint()..color = AppTheme.paper);
    canvas.save();
    canvas.scale(scale);

    if (showColor) {
      final Paint fill = Paint()..style = PaintingStyle.fill;
      for (final ArtRegion r in art.regions) {
        if (r.hint == null) continue;
        fill.color = r.hint!;
        canvas.drawPath(r.path, fill);
      }
    }

    final Paint outline = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 16
      ..strokeJoin = StrokeJoin.round
      ..color = const Color(0xFF2B2B2B);
    for (final Path p in art.outlines) {
      canvas.drawPath(p, outline);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant ThumbnailPainter oldDelegate) =>
      oldDelegate.showColor != showColor || oldDelegate.art != art;
}
