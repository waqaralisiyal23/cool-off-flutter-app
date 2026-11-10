import 'dart:math' as math;

import 'package:flutter/rendering.dart';

/// The Cool Off app icon, drawn in code with the brand colours
/// (docs/12-design-system.md): the heat ring sweeping from ember through
/// amber to ice, around a cool heart. A pulse cooling off.
///
/// Rendered to PNGs by `render_icon_test.dart`, then turned into every
/// Android/iOS size with `flutter_launcher_icons`.
class CoolOffIconPainter extends CustomPainter {
  const CoolOffIconPainter({
    this.background = true,
    this.artwork = true,
    this.scale = 1,
    this.monochrome = false,
  });

  /// The dark ink backdrop with its soft glow.
  final bool background;

  /// The ring and heart.
  final bool artwork;

  /// Artwork size relative to the canvas: smaller for Android's adaptive
  /// foreground, which must fit its safe zone.
  final double scale;

  /// White silhouette only (Android 13+ themed icons).
  final bool monochrome;

  static const _ink900 = Color(0xFF0A1020);
  static const _ink800 = Color(0xFF151F36);
  static const _ink950 = Color(0xFF060A14);
  static const _track = Color(0xFF1E2A45);
  static const _ember = Color(0xFFFF5E4D);
  static const _amber = Color(0xFFFFB547);
  static const _ice = Color(0xFF3FD5E6);
  static const _iceLight = Color(0xFF9AF0F7);
  static const _iceDeep = Color(0xFF14A3B8);
  static const _white = Color(0xFFF1F6FF);

  /// The ring's open arc: it starts at the top and sweeps 300° clockwise.
  static const double _sweep = 300 / 360 * 2 * math.pi;
  static const double _start = -math.pi / 2;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final center = size.center(Offset.zero);
    if (background) {
      _paintBackground(canvas, size, center, s);
    }
    if (artwork) {
      _paintArtwork(canvas, center, s * scale);
    }
  }

  void _paintBackground(Canvas canvas, Size size, Offset center, double s) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(0, -0.15),
          radius: 0.85,
          colors: [_ink800, _ink900, _ink950],
          stops: [0, 0.6, 1],
        ).createShader(rect),
    );
    // A cool glow where the heart sits.
    canvas.drawCircle(
      center,
      s * 0.36,
      Paint()
        ..shader = RadialGradient(
          colors: [_ice.withValues(alpha: 0.20), _ice.withValues(alpha: 0)],
        ).createShader(Rect.fromCircle(center: center, radius: s * 0.36)),
    );
  }

  void _paintArtwork(Canvas canvas, Offset center, double a) {
    final radius = a * 0.32;
    final stroke = a * 0.062;
    final ring = Rect.fromCircle(center: center, radius: radius);

    if (!monochrome) {
      // Track: the rest of the circle, faint.
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke
          ..color = _track,
      );
      // Glow under the arc.
      canvas.drawArc(
        ring,
        _start,
        _sweep,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke * 1.7
          ..strokeCap = StrokeCap.round
          ..shader = _sweepShader(ring, alpha: 0.35)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, a * 0.03),
      );
    }

    // The ring: hot at the top, cooling clockwise to ice.
    canvas.drawArc(
      ring,
      _start,
      _sweep,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..color = _white
        ..shader = monochrome ? null : _sweepShader(ring),
    );

    if (!monochrome) {
      // A bright head on the cool end, as on the app's own rings.
      const end = _start + _sweep;
      final head = center + Offset(math.cos(end), math.sin(end)) * radius;
      canvas.drawCircle(head, stroke * 0.30, Paint()..color = _white);
    }

    // The heart.
    final heartWidth = a * 0.34;
    final heart = _heart(
      Rect.fromCenter(
        center: center + Offset(0, a * 0.012),
        width: heartWidth,
        height: heartWidth * 0.9,
      ),
    );
    if (!monochrome) {
      canvas.drawPath(
        heart.shift(Offset(0, a * 0.012)),
        Paint()
          ..color = _ice.withValues(alpha: 0.45)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, a * 0.035),
      );
    }
    final bounds = heart.getBounds();
    canvas.drawPath(
      heart,
      Paint()
        ..color = _white
        ..shader = monochrome
            ? null
            : const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [_iceLight, _ice, _iceDeep],
              ).createShader(bounds),
    );
    if (!monochrome) {
      // A small highlight on the upper-left lobe.
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(
            bounds.left + bounds.width * 0.28,
            bounds.top + bounds.height * 0.24,
          ),
          width: bounds.width * 0.16,
          height: bounds.height * 0.10,
        ),
        Paint()..color = _white.withValues(alpha: 0.55),
      );
    }
  }

  /// The gradient starts a little before the arc, so the round cap at the
  /// start stays ember instead of wrapping round to the ice colour.
  static const double _capMargin = 20 / 360 * 2 * math.pi;

  Shader _sweepShader(Rect ring, {double alpha = 1}) => SweepGradient(
    endAngle: _sweep + _capMargin,
    colors: [
      _ember.withValues(alpha: alpha),
      _amber.withValues(alpha: alpha),
      _ice.withValues(alpha: alpha),
    ],
    stops: const [0.08, 0.48, 0.92],
    transform: const GradientRotation(_start - _capMargin),
  ).createShader(ring);

  /// A classic heart filling [box].
  static Path _heart(Rect box) {
    Offset p(double x, double y) =>
        Offset(box.left + x * box.width, box.top + y * box.height);
    final path = Path()..moveTo(p(0.5, 1).dx, p(0.5, 1).dy);
    void cubic(Offset c1, Offset c2, Offset end) =>
        path.cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, end.dx, end.dy);
    cubic(p(0.18, 0.76), p(0, 0.55), p(0, 0.32));
    cubic(p(0, 0.13), p(0.14, 0), p(0.29, 0));
    cubic(p(0.40, 0), p(0.47, 0.06), p(0.5, 0.15));
    cubic(p(0.53, 0.06), p(0.60, 0), p(0.71, 0));
    cubic(p(0.86, 0), p(1, 0.13), p(1, 0.32));
    cubic(p(1, 0.55), p(0.82, 0.76), p(0.5, 1));
    return path..close();
  }

  @override
  bool shouldRepaint(CoolOffIconPainter old) => false;
}
