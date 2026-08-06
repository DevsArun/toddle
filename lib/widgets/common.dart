import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_theme.dart';

/// A button that squishes when pressed. Used everywhere so the whole app feels
/// physical and playful rather than like a form.
class SquishButton extends StatefulWidget {
  const SquishButton({
    super.key,
    required this.child,
    required this.onTap,
    this.scale = 0.93,
    this.haptics = true,
  });

  final Widget child;
  final VoidCallback? onTap;
  final double scale;
  final bool haptics;

  @override
  State<SquishButton> createState() => _SquishButtonState();
}

class _SquishButtonState extends State<SquishButton> {
  bool _down = false;

  void _set(bool value) {
    if (_down != value && mounted) setState(() => _down = value);
  }

  @override
  Widget build(BuildContext context) {
    final bool enabled = widget.onTap != null;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: enabled ? (_) => _set(true) : null,
      onTapCancel: enabled ? () => _set(false) : null,
      onTapUp: enabled
          ? (_) {
              _set(false);
              if (widget.haptics) {
                HapticFeedback.lightImpact();
              }
              widget.onTap!();
            }
          : null,
      child: AnimatedScale(
        scale: _down ? widget.scale : 1,
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOut,
        child: Opacity(opacity: enabled ? 1 : 0.5, child: widget.child),
      ),
    );
  }
}

/// Soft studio-grade card surface.
class GlossCard extends StatelessWidget {
  const GlossCard({
    super.key,
    required this.child,
    this.color = Colors.white,
    this.radius = 32,
    this.padding = const EdgeInsets.all(20),
    this.elevated = true,
  });

  final Widget child;
  final Color color;
  final double radius;
  final EdgeInsets padding;
  final bool elevated;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: elevated
            ? <BoxShadow>[
                const BoxShadow(
                  color: Color(0x1F3E2723),
                  blurRadius: 26,
                  offset: Offset(0, 12),
                ),
                const BoxShadow(
                  color: Color(0xA6FFFFFF),
                  blurRadius: 12,
                  offset: Offset(0, -4),
                ),
              ]
            : null,
      ),
      child: child,
    );
  }
}

/// Warm animated background used behind every screen.
///
/// This widget also supplies the [Scaffold] for the screen. Every screen in the
/// app is wrapped in it, which guarantees that Material widgets such as
/// buttons, snack bars and dialogs always have the Material ancestor they
/// require. Forgetting that is the classic cause of a blank or crashing screen.
class PlayfulBackground extends StatefulWidget {
  const PlayfulBackground({super.key, required this.child, this.seed = 0});

  final Widget child;
  final int seed;

  @override
  State<PlayfulBackground> createState() => _PlayfulBackgroundState();
}

class _PlayfulBackgroundState extends State<PlayfulBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 18),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.paper,
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: <Widget>[
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: <Color>[
                    Color(0xFFFFF3E0),
                    Color(0xFFFDE7F3),
                    Color(0xFFE3F2FD),
                  ],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: RepaintBoundary(
              child: AnimatedBuilder(
                animation: _c,
                builder: (BuildContext context, Widget? _) => CustomPaint(
                  painter: _BubblePainter(_c.value, widget.seed),
                ),
              ),
            ),
          ),
          Positioned.fill(child: widget.child),
        ],
      ),
    );
  }
}

class _BubblePainter extends CustomPainter {
  _BubblePainter(this.t, this.seed);

  final double t;
  final int seed;

  static const List<Color> _colors = <Color>[
    Color(0x33FFB74D),
    Color(0x3381D4FA),
    Color(0x33F48FB1),
    Color(0x33AED581),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    final math.Random rnd = math.Random(seed.abs() % 100000 + 7);
    final Paint paint = Paint();
    for (int i = 0; i < 10; i++) {
      final double baseX = rnd.nextDouble() * size.width;
      final double baseY = rnd.nextDouble() * size.height;
      final double radius = 28 + rnd.nextDouble() * 70;
      final double phase = rnd.nextDouble();
      final double dy = math.sin((t + phase) * math.pi * 2) * 22;
      final double dx = math.cos((t + phase) * math.pi * 2) * 14;
      paint.color = _colors[i % _colors.length];
      canvas.drawCircle(Offset(baseX + dx, baseY + dy), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _BubblePainter oldDelegate) =>
      oldDelegate.t != t || oldDelegate.seed != seed;
}

/// Rounded pill title used in headers.
class TitlePill extends StatelessWidget {
  const TitlePill({super.key, required this.text, this.color = AppTheme.brand});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(40),
      ),
      child: Text(
        text,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 26,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

/// Circular icon button sized for small hands.
class RoundIconButton extends StatelessWidget {
  const RoundIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.color = Colors.white,
    this.iconColor = AppTheme.ink,
    this.size = AppTheme.touchTarget,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final Color color;
  final Color iconColor;
  final double size;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    return SquishButton(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: const <BoxShadow>[
            BoxShadow(
              color: Color(0x293E2723),
              blurRadius: 14,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Icon(icon, size: size * 0.46, color: iconColor),
      ),
    );
  }
}
