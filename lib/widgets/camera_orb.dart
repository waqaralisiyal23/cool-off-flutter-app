import 'package:flutter/material.dart';
import 'package:smartspectra_flutter/smartspectra_flutter.dart';

import '../core/app_colors.dart';
import 'heat_ring.dart';

/// The live camera in a circle, inside a [HeatRing].
///
/// The preview is always visible while measuring (docs/06: no hidden
/// camera). Measurements wait for [onPreviewReady] before starting, so the
/// camera never runs without it. While the camera is not running yet, a
/// soft face outline shows where to look.
class CameraOrb extends StatefulWidget {
  final double size;
  final double progress;
  final Color color;

  /// The native preview exists and is attached to the SDK.
  final VoidCallback onPreviewReady;

  /// The preview was removed (only after [onPreviewReady]).
  final VoidCallback onPreviewGone;

  const CameraOrb({
    super.key,
    this.size = 240,
    required this.progress,
    this.color = AppColors.calm,
    required this.onPreviewReady,
    required this.onPreviewGone,
  });

  @override
  State<CameraOrb> createState() => _CameraOrbState();
}

class _CameraOrbState extends State<CameraOrb> {
  bool _reported = false;

  void _ready() {
    _reported = true;
    widget.onPreviewReady();
  }

  @override
  void dispose() {
    if (_reported) {
      widget.onPreviewGone();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const ringGap = 14.0;
    final percent = (widget.progress * 100).round();
    return Semantics(
      label: 'Camera preview. Measuring, $percent percent done.',
      image: true,
      child: ExcludeSemantics(
        child: HeatRing(
          size: widget.size,
          progress: widget.progress,
          color: widget.color,
          strokeWidth: 8,
          duration: const Duration(milliseconds: 900),
          child: SizedBox.square(
            dimension: widget.size - ringGap * 2 - 16,
            child: ClipOval(
              child: SmartSpectraPreview(
                placeholder: const _Placeholder(),
                onReady: _ready,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          colors: [AppColors.surfaceRaised, AppColors.backgroundDeep],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.face_retouching_natural_rounded,
          size: 72,
          color: AppColors.textDisabled,
        ),
      ),
    );
  }
}
