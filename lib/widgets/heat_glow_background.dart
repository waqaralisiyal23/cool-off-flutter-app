import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../core/app_dimens.dart';

/// A slowly drifting glow behind a page, tinted by [color].
///
/// The app's ambient "temperature": cool teal on calm screens, ember on a
/// heated result, easing from one to the next when [color] changes. The
/// motion is slow (a 24-second loop) so it reads as atmosphere, not
/// animation, and stops entirely when the platform asks for reduced motion.
class HeatGlowBackground extends StatefulWidget {
  final Color color;

  /// 0 (barely there) to 1 (strong). Rises with heat.
  final double intensity;

  final Widget child;

  const HeatGlowBackground({
    super.key,
    this.color = AppColors.calm,
    this.intensity = 0.5,
    required this.child,
  });

  @override
  State<HeatGlowBackground> createState() => _HeatGlowBackgroundState();
}

class _HeatGlowBackgroundState extends State<HeatGlowBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _drift = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 24),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _drift.stop();
    } else if (!_drift.isAnimating) {
      _drift.repeat();
    }
  }

  @override
  void dispose() {
    _drift.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<Color?>(
      tween: ColorTween(end: widget.color),
      duration: AppMotion.slow,
      curve: AppMotion.standard,
      builder: (context, color, child) => TweenAnimationBuilder<double>(
        tween: Tween(end: widget.intensity),
        duration: AppMotion.slow,
        builder: (context, intensity, child) => CustomPaint(
          painter: _GlowPainter(
            drift: _drift,
            color: color ?? widget.color,
            intensity: intensity,
          ),
          child: child,
        ),
        child: child,
      ),
      child: widget.child,
    );
  }
}

class _GlowPainter extends CustomPainter {
  final Animation<double> drift;
  final Color color;
  final double intensity;

  _GlowPainter({
    required this.drift,
    required this.color,
    required this.intensity,
  }) : super(repaint: drift);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = AppColors.background);
    final t = drift.value * 2 * math.pi;
    final strength = 0.10 + 0.22 * intensity.clamp(0, 1);

    // Two blobs on slow Lissajous paths; the second is a cooler counterpoint
    // so even a heated screen keeps some depth.
    _blob(
      canvas,
      size,
      center: Offset(
        size.width * (0.25 + 0.12 * math.sin(t)),
        size.height * (0.18 + 0.06 * math.cos(t * 2)),
      ),
      radius: size.width * 0.95,
      color: color.withValues(alpha: strength),
    );
    _blob(
      canvas,
      size,
      center: Offset(
        size.width * (0.85 + 0.10 * math.cos(t)),
        size.height * (0.78 + 0.05 * math.sin(t * 2)),
      ),
      radius: size.width * 0.8,
      color: Color.lerp(
        color,
        AppColors.primaryDeep,
        0.6,
      )!.withValues(alpha: strength * 0.6),
    );
  }

  void _blob(
    Canvas canvas,
    Size size, {
    required Offset center,
    required double radius,
    required Color color,
  }) {
    final paint = Paint()
      ..shader = RadialGradient(colors: [color, color.withValues(alpha: 0)])
          .createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(_GlowPainter old) =>
      old.color != color || old.intensity != intensity;
}
