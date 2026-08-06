import 'dart:ui';

/// A single fillable area of a coloring picture.
class ArtRegion {
  const ArtRegion(this.path, {this.hint});

  /// Path is defined in a 1000 x 1000 "art space" and scaled at paint time.
  final Path path;

  /// Optional suggested colour, only used for the thumbnail preview.
  final Color? hint;
}

/// A full picture: fillable regions plus the black outline drawn on top.
class ArtDef {
  const ArtDef({required this.regions, required this.outlines});

  final List<ArtRegion> regions;
  final List<Path> outlines;

  static const double space = 1000;
}

/// One freehand stroke drawn by the child.
class Stroke {
  Stroke({required this.color, required this.width, required this.points});

  final Color color;
  final double width;
  final List<Offset> points;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'c': color.value,
        'w': width,
        'p': points.expand((Offset o) => <double>[o.dx, o.dy]).toList(),
      };

  static Stroke fromJson(Map<String, dynamic> json) {
    final List<dynamic> raw = json['p'] as List<dynamic>;
    final List<Offset> pts = <Offset>[];
    for (int i = 0; i + 1 < raw.length; i += 2) {
      pts.add(Offset((raw[i] as num).toDouble(), (raw[i + 1] as num).toDouble()));
    }
    return Stroke(
      color: Color(json['c'] as int),
      width: (json['w'] as num).toDouble(),
      points: pts,
    );
  }
}
