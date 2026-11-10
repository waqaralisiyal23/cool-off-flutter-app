import 'package:flutter/material.dart';

import '../core/app_colors.dart';

/// A heart that beats at [bpm]: the user's own pulse, made visible.
///
/// Each beat is a "lub-dub" double bump. Without a reading yet (null) it
/// breathes slowly and faintly, so the screen shows it is listening.
class Heartbeat extends StatefulWidget {
  final double? bpm;
  final Color color;
  final double size;

  const Heartbeat({
    super.key,
    required this.bpm,
    this.color = AppColors.heated,
    this.size = 28,
  });

  @override
  State<Heartbeat> createState() => _HeartbeatState();
}

class _HeartbeatState extends State<Heartbeat>
    with SingleTickerProviderStateMixin {
  late final AnimationController _beat = AnimationController(
    vsync: this,
    duration: _periodFor(widget.bpm),
  );

  static const _idle = Duration(milliseconds: 2400);

  static Duration _periodFor(double? bpm) => bpm == null || bpm <= 0
      ? _idle
      : Duration(milliseconds: (60000 / bpm).round());

  // lub (big), dub (smaller), then rest.
  static final Animatable<double> _scale = TweenSequence<double>([
    TweenSequenceItem(tween: Tween(begin: 1, end: 1.22), weight: 12),
    TweenSequenceItem(tween: Tween(begin: 1.22, end: 1), weight: 12),
    TweenSequenceItem(tween: Tween(begin: 1, end: 1.12), weight: 10),
    TweenSequenceItem(tween: Tween(begin: 1.12, end: 1), weight: 14),
    TweenSequenceItem(tween: ConstantTween(1), weight: 52),
  ]);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(Heartbeat old) {
    super.didUpdateWidget(old);
    final period = _periodFor(widget.bpm);
    if (period != _beat.duration) {
      _beat.duration = period;
      _sync(restart: true);
    }
  }

  void _sync({bool restart = false}) {
    if (MediaQuery.disableAnimationsOf(context)) {
      _beat.stop();
      return;
    }
    if (restart || !_beat.isAnimating) {
      _beat.repeat();
    }
  }

  @override
  void dispose() {
    _beat.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final listening = widget.bpm == null;
    // Decorative: the pulse is always written next to it.
    return ExcludeSemantics(
      child: ScaleTransition(
        scale: listening
            ? Tween<double>(begin: 0.92, end: 1.05).animate(
                CurvedAnimation(parent: _beat, curve: Curves.easeInOutSine),
              )
            : _scale.animate(_beat),
        child: Icon(
          Icons.favorite_rounded,
          size: widget.size,
          color: listening
              ? widget.color.withValues(alpha: 0.45)
              : widget.color,
        ),
      ),
    );
  }
}
