import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../core/app_typography.dart';

/// A soft halo that grows for 4 seconds and shrinks for 6: a pace to
/// breathe with during the cool-down. A visual guide only; breathing is
/// never measured (docs/02-features.md).
class BreathingHalo extends StatefulWidget {
  final double size;
  final Color color;
  final Widget child;

  const BreathingHalo({
    super.key,
    required this.size,
    this.color = AppColors.calm,
    required this.child,
  });

  @override
  State<BreathingHalo> createState() => _BreathingHaloState();
}

class _BreathingHaloState extends State<BreathingHalo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _breath = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 10),
  );

  static const double _inhaleShare = 0.4;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _breath.stop();
    } else if (!_breath.isAnimating) {
      _breath.repeat();
    }
  }

  @override
  void dispose() {
    _breath.dispose();
    super.dispose();
  }

  /// 0 (empty) to 1 (full) along the breath.
  double get _fullness {
    final t = _breath.value;
    if (t < _inhaleShare) {
      return Curves.easeInOutSine.transform(t / _inhaleShare);
    }
    return 1 -
        Curves.easeInOutSine.transform((t - _inhaleShare) / (1 - _inhaleShare));
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _breath,
      builder: (context, child) {
        final fullness = _fullness;
        final inhaling = _breath.value < _inhaleShare;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox.square(
              dimension: widget.size,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: widget.size * (0.78 + 0.22 * fullness),
                    height: widget.size * (0.78 + 0.22 * fullness),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          widget.color.withValues(
                            alpha: 0.05 + 0.25 * fullness,
                          ),
                          widget.color.withValues(alpha: 0),
                        ],
                      ),
                      border: Border.all(
                        color: widget.color.withValues(
                          alpha: 0.15 + 0.35 * fullness,
                        ),
                        width: 1.5,
                      ),
                    ),
                  ),
                  child!,
                ],
              ),
            ),
            const SizedBox(height: 4),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              child: Text(
                inhaling ? 'Breathe in…' : 'Breathe out…',
                key: ValueKey(inhaling),
                style: AppTypography.medium16.copyWith(color: widget.color),
              ),
            ),
          ],
        );
      },
      child: widget.child,
    );
  }
}
