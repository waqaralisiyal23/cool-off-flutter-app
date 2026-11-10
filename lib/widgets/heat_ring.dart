import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../core/app_dimens.dart';

/// A glowing progress ring: the check's timer, the cool-down's clock and the
/// result's heat gauge.
///
/// [progress] (0–1) and [color] animate to new values on their own.
class HeatRing extends StatelessWidget {
  final double progress;
  final Color color;

  /// Where the gradient starts; defaults to a softer [color].
  final Color? startColor;

  final double size;
  final double strokeWidth;
  final Widget? child;

  /// Animates [progress] changes over this long. Zero jumps.
  final Duration duration;

  const HeatRing({
    super.key,
    required this.progress,
    this.color = AppColors.calm,
    this.startColor,
    this.size = 240,
    this.strokeWidth = 10,
    this.child,
    this.duration = AppMotion.medium,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(end: progress.clamp(0, 1)),
      duration: duration,
      curve: AppMotion.standard,
      builder: (context, value, child) => TweenAnimationBuilder<Color?>(
        tween: ColorTween(end: color),
        duration: AppMotion.slow,
        builder: (context, animatedColor, child) => CustomPaint(
          size: Size.square(size),
          painter: _RingPainter(
            progress: value,
            color: animatedColor ?? color,
            startColor: startColor,
            strokeWidth: strokeWidth,
          ),
          child: child,
        ),
        child: child,
      ),
      child: SizedBox.square(
        dimension: size,
        child: child == null ? null : Center(child: child),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color? startColor;
  final double strokeWidth;

  _RingPainter({
    required this.progress,
    required this.color,
    required this.startColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = (size.shortestSide - strokeWidth) / 2 - 6;
    final rect = Rect.fromCircle(center: center, radius: radius);

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..color = AppColors.border,
    );
    if (progress <= 0) {
      return;
    }

    final sweep = 2 * math.pi * progress;
    final gradient = SweepGradient(
      endAngle: sweep,
      colors: [startColor ?? color.withValues(alpha: 0.35), color],
      transform: const GradientRotation(-math.pi / 2),
    ).createShader(rect);

    // Glow under the arc.
    canvas.drawArc(
      rect,
      -math.pi / 2,
      sweep,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth * 1.6
        ..strokeCap = StrokeCap.round
        ..color = color.withValues(alpha: 0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );
    canvas.drawArc(
      rect,
      -math.pi / 2,
      sweep,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..shader = gradient,
    );

    // A bright head on the arc's leading end.
    final headAngle = -math.pi / 2 + sweep;
    final head =
        center + Offset(math.cos(headAngle), math.sin(headAngle)) * radius;
    canvas.drawCircle(
      head,
      strokeWidth * 0.32,
      Paint()..color = AppColors.textPrimary,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress ||
      old.color != color ||
      old.startColor != startColor ||
      old.strokeWidth != strokeWidth;
}
