import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart';

import '../models/art.dart';
import '../services/drawing_storage.dart';

enum ColoringTool { fill, brush, marker, pencil, sticker, eraser }

extension ColoringToolInfo on ColoringTool {
  double get strokeWidth {
    switch (this) {
      case ColoringTool.brush:
        return 34;
      case ColoringTool.marker:
        return 56;
      case ColoringTool.pencil:
        return 14;
      case ColoringTool.eraser:
        return 70;
      case ColoringTool.fill:
      case ColoringTool.sticker:
        return 0;
    }
  }

  bool get isStroke =>
      this == ColoringTool.brush ||
      this == ColoringTool.marker ||
      this == ColoringTool.pencil ||
      this == ColoringTool.eraser;
}

/// One reversible edit.
class _Action {
  _Action.fill(this.regionIndex, this.previous, this.next) : stroke = null;
  _Action.stroke(this.stroke)
      : regionIndex = -1,
        previous = null,
        next = null;

  final int regionIndex;
  final Color? previous;
  final Color? next;
  final Stroke? stroke;

  bool get isStroke => stroke != null;
}

/// Holds the colouring state for one picture.
///
/// Memory is deliberately bounded: undo history is capped, and only one picture
/// is ever live at a time. This keeps 1 GB Fire tablets comfortable.
class CanvasController extends ChangeNotifier {
  CanvasController({required this.pageId, required this.art});

  static const int maxHistory = 20;

  final String pageId;
  final ArtDef art;

  final Map<int, Color> fills = <int, Color>{};
  final List<Stroke> strokes = <Stroke>[];

  final List<_Action> _undo = <_Action>[];
  final List<_Action> _redo = <_Action>[];

  Stroke? _active;
  Timer? _saveTimer;

  ColoringTool tool = ColoringTool.fill;
  Color color = const Color(0xFFE53935);

  bool get canUndo => _undo.isNotEmpty;
  bool get canRedo => _redo.isNotEmpty;
  bool get isEmpty => fills.isEmpty && strokes.isEmpty;
  Stroke? get activeStroke => _active;

  void selectTool(ColoringTool value) {
    tool = value;
    notifyListeners();
  }

  void selectColor(Color value) {
    color = value;
    if (tool == ColoringTool.eraser) {
      tool = ColoringTool.fill;
    }
    notifyListeners();
  }

  // --------------------------------------------------------------- editing

  /// Returns true when the tap landed inside a fillable region.
  bool tapAt(Offset artPoint) {
    // Search from the top-most region downwards so small details win.
    for (int i = art.regions.length - 1; i >= 0; i--) {
      if (art.regions[i].path.contains(artPoint)) {
        final Color? previous = fills[i];
        final Color? next = tool == ColoringTool.eraser ? null : color;
        if (previous == next) return true;
        _push(_Action.fill(i, previous, next));
        if (next == null) {
          fills.remove(i);
        } else {
          fills[i] = next;
        }
        _scheduleSave();
        notifyListeners();
        return true;
      }
    }
    return false;
  }

  void startStroke(Offset artPoint) {
    if (!tool.isStroke) return;
    _active = Stroke(
      color: tool == ColoringTool.eraser ? const Color(0xFFFFFDF7) : color,
      width: tool.strokeWidth,
      points: <Offset>[artPoint],
    );
    notifyListeners();
  }

  void extendStroke(Offset artPoint) {
    final Stroke? s = _active;
    if (s == null) return;
    // Skip near duplicate points to keep the stroke list small.
    final Offset last = s.points.last;
    if ((artPoint - last).distanceSquared < 9) return;
    s.points.add(artPoint);
    notifyListeners();
  }

  void endStroke() {
    final Stroke? s = _active;
    _active = null;
    if (s == null || s.points.length < 2) {
      notifyListeners();
      return;
    }
    strokes.add(s);
    _push(_Action.stroke(s));
    _scheduleSave();
    notifyListeners();
  }

  void undo() {
    if (_undo.isEmpty) return;
    final _Action a = _undo.removeLast();
    if (a.isStroke) {
      strokes.remove(a.stroke);
    } else if (a.previous == null) {
      fills.remove(a.regionIndex);
    } else {
      fills[a.regionIndex] = a.previous!;
    }
    _redo.add(a);
    _scheduleSave();
    notifyListeners();
  }

  void redo() {
    if (_redo.isEmpty) return;
    final _Action a = _redo.removeLast();
    if (a.isStroke) {
      strokes.add(a.stroke!);
    } else if (a.next == null) {
      fills.remove(a.regionIndex);
    } else {
      fills[a.regionIndex] = a.next!;
    }
    _undo.add(a);
    _scheduleSave();
    notifyListeners();
  }

  void clearAll() {
    fills.clear();
    strokes.clear();
    _undo.clear();
    _redo.clear();
    _scheduleSave();
    notifyListeners();
  }

  void _push(_Action action) {
    _undo.add(action);
    if (_undo.length > maxHistory) {
      _undo.removeAt(0);
    }
    _redo.clear();
  }

  // -------------------------------------------------------------- autosave

  void _scheduleSave() {
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 700), save);
  }

  Future<void> save() async {
    await DrawingStorage.instance.writeAutosave(pageId, toJson());
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'fills': fills.map(
          (int key, Color value) => MapEntry<String, int>('$key', value.value),
        ),
        'strokes': strokes.map((Stroke s) => s.toJson()).toList(),
      };

  void restore(Map<String, dynamic> json) {
    fills.clear();
    strokes.clear();
    final Map<String, dynamic> f =
        (json['fills'] as Map<String, dynamic>?) ?? <String, dynamic>{};
    f.forEach((String key, dynamic value) {
      final int? index = int.tryParse(key);
      if (index != null && index < art.regions.length) {
        fills[index] = Color(value as int);
      }
    });
    final List<dynamic> s = (json['strokes'] as List<dynamic>?) ?? <dynamic>[];
    for (final dynamic item in s) {
      strokes.add(Stroke.fromJson(item as Map<String, dynamic>));
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _saveTimer?.cancel();
    super.dispose();
  }
}
