/// Collects the live readings of one measurement (baseline, check or
/// re-check) and summarises them (docs/03-heat-engine.md).
///
/// Pure Dart: the measurement service turns the plugin's metrics into these
/// plain samples, so everything here is unit-tested without a camera.
library;

/// One pulse-rate reading from the SDK (a 12-second rolling average).
class PulseSample {
  const PulseSample({
    required this.bpm,
    required this.confidence,
    required this.stable,
    required this.timestampUs,
  });

  final double bpm;

  /// 0–100, as the SDK reports it.
  final double confidence;

  final bool stable;

  /// Capture time, microseconds since the epoch.
  final int timestampUs;
}

/// The anger-related expression scores of one frame, each 0–100.
class ExpressionSample {
  const ExpressionSample({
    required this.angry,
    required this.contempt,
    required this.disgust,
    required this.timestampUs,
  });

  final double angry;
  final double contempt;
  final double disgust;

  final int timestampUs;

  /// The "anger level" Cool Off uses: angry + contempt + disgust, capped at
  /// 100 (docs/03-heat-engine.md).
  double get angerLevel {
    final sum = angry + contempt + disgust;
    return sum > 100 ? 100 : sum;
  }
}

/// Gathers samples for one measurement.
///
/// The SDK sends up to ~30 updates a second and repeats the same pulse value
/// between its own updates, so samples are thinned to one per
/// [sampleIntervalUs]. Otherwise a few seconds of video would outweigh the
/// rest of the check.
class SignalCollector {
  SignalCollector({this.sampleIntervalUs = defaultSampleIntervalUs});

  /// One kept sample every half second.
  static const int defaultSampleIntervalUs = 500000;

  /// Pulse readings below this confidence (and not marked stable) are
  /// ignored. A starting value; tune on device.
  static const double minPulseConfidence = 40;

  /// The SDK's valid pulse range.
  static const double minPulseBpm = 40;
  static const double maxPulseBpm = 110;

  final int sampleIntervalUs;

  final List<double> _pulse = [];
  final List<double> _anger = [];
  int? _lastPulseUs;
  int? _lastExpressionUs;

  /// Usable pulse values, oldest first.
  List<double> get pulseValues => List.unmodifiable(_pulse);

  /// Anger levels, oldest first.
  List<double> get angerValues => List.unmodifiable(_anger);

  int get pulseCount => _pulse.length;

  int get expressionCount => _anger.length;

  /// The latest usable pulse value, for live display.
  double? get latestPulse => _pulse.isEmpty ? null : _pulse.last;

  /// Adds a pulse reading. Returns true when it was kept.
  bool addPulse(PulseSample sample) {
    if (!isUsablePulse(sample)) {
      return false;
    }
    final last = _lastPulseUs;
    if (last != null && sample.timestampUs - last < sampleIntervalUs) {
      return false;
    }
    _lastPulseUs = sample.timestampUs;
    _pulse.add(sample.bpm);
    return true;
  }

  /// Adds an expression frame. Returns true when it was kept.
  bool addExpression(ExpressionSample sample) {
    final last = _lastExpressionUs;
    if (last != null && sample.timestampUs - last < sampleIntervalUs) {
      return false;
    }
    _lastExpressionUs = sample.timestampUs;
    _anger.add(sample.angerLevel);
    return true;
  }

  /// Median of the last [lastN] pulse values (all when null), or null when
  /// there are none. A median ignores the odd jump better than a mean.
  double? pulseMedian({int? lastN}) {
    if (_pulse.isEmpty) {
      return null;
    }
    final values = lastN == null || lastN >= _pulse.length
        ? _pulse
        : _pulse.sublist(_pulse.length - lastN);
    return median(values);
  }

  /// Mean anger level over the whole measurement, or null without frames.
  double? angerMean() {
    if (_anger.isEmpty) {
      return null;
    }
    return _anger.reduce((a, b) => a + b) / _anger.length;
  }

  void clear() {
    _pulse.clear();
    _anger.clear();
    _lastPulseUs = null;
    _lastExpressionUs = null;
  }

  static bool isUsablePulse(PulseSample sample) =>
      sample.bpm >= minPulseBpm &&
      sample.bpm <= maxPulseBpm &&
      (sample.stable || sample.confidence >= minPulseConfidence);

  static double median(List<double> values) {
    assert(values.isNotEmpty, 'median of nothing');
    final sorted = [...values]..sort();
    final mid = sorted.length ~/ 2;
    return sorted.length.isOdd
        ? sorted[mid]
        : (sorted[mid - 1] + sorted[mid]) / 2;
  }
}
