import 'signal_collector.dart';

/// Why a baseline could not be taken.
enum BaselineFailure {
  /// Too few steady pulse readings: movement, poor light, face out of frame.
  notEnoughPulse,

  /// The face was hardly seen.
  notEnoughFace,
}

/// The user's usual pulse and resting anger level (docs/03-heat-engine.md).
class BaselineValues {
  const BaselineValues({
    required this.pulseBpm,
    required this.angerLevel,
    required this.sampleCount,
  });

  final double pulseBpm;

  /// Mean anger level at rest (0–100). Some faces read a little "angry" when
  /// relaxed; checks subtract this.
  final double angerLevel;

  /// Pulse samples the baseline is based on.
  final int sampleCount;
}

/// The outcome of a baseline measurement: [values], or a [failure].
class BaselineOutcome {
  const BaselineOutcome.success(BaselineValues this.values) : failure = null;

  const BaselineOutcome.failed(BaselineFailure this.failure) : values = null;

  final BaselineValues? values;
  final BaselineFailure? failure;

  bool get isSuccess => values != null;
}

/// Turns a 30-second calm measurement into [BaselineValues].
class BaselineCalculator {
  BaselineCalculator._();

  /// How long the baseline measurement runs.
  static const Duration duration = Duration(seconds: 30);

  /// Pulse samples (one per half second) needed: 5 seconds of steady signal.
  static const int minPulseSamples = 10;

  /// Expression samples needed: 5 seconds of face.
  static const int minExpressionSamples = 10;

  static BaselineOutcome calculate(SignalCollector collector) {
    if (collector.pulseCount < minPulseSamples) {
      return const BaselineOutcome.failed(BaselineFailure.notEnoughPulse);
    }
    if (collector.expressionCount < minExpressionSamples) {
      return const BaselineOutcome.failed(BaselineFailure.notEnoughFace);
    }
    return BaselineOutcome.success(
      BaselineValues(
        pulseBpm: collector.pulseMedian()!,
        angerLevel: collector.angerMean()!,
        sampleCount: collector.pulseCount,
      ),
    );
  }
}
