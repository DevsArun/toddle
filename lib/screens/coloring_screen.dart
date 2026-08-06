import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import '../app_theme.dart';
import '../coloring/canvas_controller.dart';
import '../coloring/coloring_painter.dart';
import '../data/art_library.dart';
import '../data/catalog.dart';
import '../models/art.dart';
import '../services/drawing_storage.dart';
import '../widgets/common.dart';

class ColoringScreen extends StatefulWidget {
  const ColoringScreen({super.key, required this.page});

  final ColoringPage page;

  @override
  State<ColoringScreen> createState() => _ColoringScreenState();
}

class _ColoringScreenState extends State<ColoringScreen> {
  late final ArtDef _art = ArtLibrary.build(widget.page.shapeKey);
  late final CanvasController _controller =
      CanvasController(pageId: widget.page.id, art: _art);
  final GlobalKey _canvasKey = GlobalKey();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _restoreAutosave();
  }

  Future<void> _restoreAutosave() async {
    final Map<String, dynamic>? saved =
        await DrawingStorage.instance.readAutosave(widget.page.id);
    if (saved != null && mounted) {
      _controller.restore(saved);
    }
  }

  @override
  void dispose() {
    _controller.save();
    _controller.dispose();
    super.dispose();
  }

  Offset _toArt(Offset local, double side) {
    final double scale = ArtDef.space / side;
    return Offset(local.dx * scale, local.dy * scale);
  }

  Future<void> _saveToGallery() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final RenderObject? render = _canvasKey.currentContext?.findRenderObject();
      if (render is! RenderRepaintBoundary) {
        _toast('Could not save right now. Please try again.');
        return;
      }
      // pixelRatio 1.5 keeps the exported PNG sharp while staying well inside
      // the memory budget of a 1 GB Fire tablet.
      final ui.Image image = await render.toImage(pixelRatio: 1.5);
      final ByteData? data =
          await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      if (data == null) {
        _toast('Could not save right now. Please try again.');
        return;
      }
      await DrawingStorage.instance.saveArtwork(data.buffer.asUint8List());
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (BuildContext context) => const _CelebrateDialog(),
      );
    } catch (e) {
      debugPrint('Save failed: $e');
      _toast('Could not save right now. Please try again.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _confirmClear() async {
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: const Text('Start again?'),
        content: const Text('This will remove all the colors on this picture.'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Keep coloring'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Start again'),
          ),
        ],
      ),
    );
    if (ok ?? false) _controller.clearAll();
  }

  @override
  Widget build(BuildContext context) {
    return PlayfulBackground(
      seed: widget.page.id.hashCode,
      child: SafeArea(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (BuildContext context, Widget? _) {
            return Column(
              children: <Widget>[
                _topBar(),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Center(
                      child: LayoutBuilder(
                        builder: (BuildContext context, BoxConstraints outer) {
                          // Pick the largest square that fits. Doing the maths
                          // here instead of with AspectRatio avoids overflow in
                          // landscape on short Fire tablet screens.
                          final double box = math.max(
                            120,
                            math.min(outer.maxWidth, outer.maxHeight),
                          );
                          return SizedBox(
                            width: box,
                            height: box,
                            child: GlossCard(
                              padding: const EdgeInsets.all(8),
                              radius: 34,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(26),
                                child: LayoutBuilder(builder:
                                    (BuildContext context, BoxConstraints c) {
                                  // The canvas is measured here, inside the
                                  // card, so touch coordinates line up exactly
                                  // with the painted picture.
                                  final double side = c.biggest.shortestSide;
                                  return GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTapUp: (TapUpDetails d) {
                                    if (_controller.tool ==
                                            ColoringTool.fill ||
                                        _controller.tool ==
                                            ColoringTool.eraser) {
                                      final bool hit = _controller
                                          .tapAt(_toArt(d.localPosition, side));
                                      if (hit) HapticFeedback.selectionClick();
                                    }
                                  },
                                  onPanStart: (DragStartDetails d) =>
                                      _controller.startStroke(
                                          _toArt(d.localPosition, side)),
                                  onPanUpdate: (DragUpdateDetails d) =>
                                      _controller.extendStroke(
                                          _toArt(d.localPosition, side)),
                                  onPanEnd: (_) => _controller.endStroke(),
                                    child: RepaintBoundary(
                                      key: _canvasKey,
                                      child: CustomPaint(
                                        painter: ColoringPainter(
                                            controller: _controller),
                                        size: Size.square(side),
                                      ),
                                    ),
                                  );
                                }),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
                _toolDock(),
                _paletteBar(),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _topBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
      child: Row(
        children: <Widget>[
          RoundIconButton(
            icon: Icons.arrow_back_rounded,
            onTap: () => Navigator.of(context).pop(),
          ),
          const Spacer(),
          RoundIconButton(
            icon: Icons.undo_rounded,
            iconColor: _controller.canUndo ? AppTheme.ink : Colors.black26,
            onTap: _controller.canUndo ? _controller.undo : null,
          ),
          const SizedBox(width: 10),
          RoundIconButton(
            icon: Icons.redo_rounded,
            iconColor: _controller.canRedo ? AppTheme.ink : Colors.black26,
            onTap: _controller.canRedo ? _controller.redo : null,
          ),
          const SizedBox(width: 10),
          RoundIconButton(
            icon: Icons.restart_alt_rounded,
            iconColor: AppTheme.brandDark,
            onTap: _controller.isEmpty ? null : _confirmClear,
          ),
          const SizedBox(width: 10),
          SquishButton(
            onTap: _saving ? null : _saveToGallery,
            child: Container(
              height: AppTheme.touchTarget,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(40),
                gradient: const LinearGradient(
                  colors: <Color>[Color(0xFF66BB6A), Color(0xFF43A047)],
                ),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: AppTheme.grass.withOpacity(0.5),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: <Widget>[
                  Icon(_saving ? Icons.hourglass_top_rounded : Icons.check_rounded,
                      color: Colors.white, size: 30),
                  const SizedBox(width: 8),
                  const Text(
                    'Done',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 21,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _toolDock() {
    const List<(ColoringTool, IconData, String)> tools =
        <(ColoringTool, IconData, String)>[
      (ColoringTool.fill, Icons.format_color_fill_rounded, 'Fill'),
      (ColoringTool.brush, Icons.brush_rounded, 'Brush'),
      (ColoringTool.marker, Icons.edit_rounded, 'Marker'),
      (ColoringTool.pencil, Icons.create_rounded, 'Pencil'),
      (ColoringTool.eraser, Icons.cleaning_services_rounded, 'Eraser'),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: tools.map(((ColoringTool, IconData, String) t) {
            final bool active = _controller.tool == t.$1;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: SquishButton(
                onTap: () => _controller.selectTool(t.$1),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 18, vertical: 10),
                  decoration: BoxDecoration(
                    color: active ? AppTheme.brand : Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: (active ? AppTheme.brand : AppTheme.ink)
                            .withOpacity(active ? 0.4 : 0.12),
                        blurRadius: 16,
                        offset: const Offset(0, 7),
                      ),
                    ],
                  ),
                  child: Row(
                    children: <Widget>[
                      Icon(t.$2,
                          size: 30,
                          color: active ? Colors.white : AppTheme.ink),
                      const SizedBox(width: 8),
                      Text(
                        t.$3,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: active ? Colors.white : AppTheme.ink,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _paletteBar() {
    return Container(
      height: 96,
      margin: const EdgeInsets.fromLTRB(14, 4, 14, 12),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppTheme.ink.withOpacity(0.14),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: AppTheme.palette.length,
        itemBuilder: (BuildContext context, int index) {
          final Color c = AppTheme.palette[index];
          final bool active = _controller.color == c &&
              _controller.tool != ColoringTool.eraser;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 12),
            child: SquishButton(
              onTap: () => _controller.selectColor(c),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                width: active ? 68 : 58,
                decoration: BoxDecoration(
                  color: c,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: active ? AppTheme.ink : Colors.black12,
                    width: active ? 4 : 2,
                  ),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: c.withOpacity(0.55),
                      blurRadius: active ? 18 : 8,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _CelebrateDialog extends StatelessWidget {
  const _CelebrateDialog();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      content: const Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(Icons.emoji_events_rounded,
              size: 76, color: AppTheme.sunshine),
          SizedBox(height: 12),
          Text(
            'Beautiful work!',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
          ),
          SizedBox(height: 6),
          Text(
            'Your picture is saved in My Drawings.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 17),
          ),
        ],
      ),
      actions: <Widget>[
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Yay!'),
        ),
      ],
    );
  }
}
