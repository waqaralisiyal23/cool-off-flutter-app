import 'dart:async';

import 'package:flutter/services.dart';

import '../models/enums/heat_level.dart';

/// Haptic feedback, off when the user turned haptics off in Settings.
///
/// [enabled] is set by `SettingsBloc` whenever the settings change, so call
/// sites stay one line.
class AppHaptics {
  AppHaptics._();

  static bool enabled = true;

  static void tap() => _run(HapticFeedback.selectionClick);

  static void light() => _run(HapticFeedback.lightImpact);

  /// A result appears: the heavier the heat, the heavier the tap.
  static void result(HeatLevel level) => _run(
    level.when(
      calm: () => HapticFeedback.lightImpact,
      warm: () => HapticFeedback.mediumImpact,
      heated: () => HapticFeedback.heavyImpact,
    ),
  );

  static void success() => _run(HapticFeedback.mediumImpact);

  static void _run(Future<void> Function() feedback) {
    if (enabled) {
      unawaited(feedback());
    }
  }
}
