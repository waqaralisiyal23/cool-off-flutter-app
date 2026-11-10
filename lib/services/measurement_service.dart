import 'package:smartspectra_flutter/smartspectra_flutter.dart';

import '../engine/signal_collector.dart';

/// One SDK update, reduced to what Cool Off uses.
class MeasurementUpdate {
  const MeasurementUpdate({this.pulse, this.expression});

  final PulseSample? pulse;
  final ExpressionSample? expression;
}

/// The measurement source the screens use: the SDK in the app, a fake in
/// tests.
abstract interface class MeasurementSource {
  bool get hasApiKey;
  Stream<MeasurementUpdate> get updates;
  Stream<ProcessingStatus> get status;
  Stream<ValidationStatus> get validation;
  Stream<SmartSpectraException> get errors;
  Future<bool> hasCameraPermission();
  Future<bool> requestCameraPermission();
  Future<void> start();
  Future<void> stop();
  Future<void> reset();
}

/// Wraps the `smartspectra_flutter` plugin for the baseline, check and
/// cool-down screens (docs/04-smartspectra-plugin.md).
///
/// The SDK is a singleton with one camera, so only one screen measures at a
/// time; each screen stops in its bloc's `close()`. The plugin already stops
/// the camera when the app leaves the screen and keeps the screen awake
/// while measuring. Nothing measured leaves the phone, and SDK telemetry
/// stays off (the plugin's default).
class _MeasurementService implements MeasurementSource {
  final SmartSpectra _spectra = SmartSpectra.instance;

  /// Passed at build time: `--dart-define-from-file=secrets.json`
  /// (docs/08-repo-and-secrets.md). Never in source control.
  static const String _apiKey = String.fromEnvironment('SMARTSPECTRA_API_KEY');

  /// Pulse for the check, expressions for the face. No breathing (it fails
  /// handheld) and no blinking.
  static const Set<SmartSpectraMetric> _metrics = {
    SmartSpectraMetric.cardio,
    SmartSpectraMetric.expressions,
  };

  @override
  bool get hasApiKey => _apiKey.isNotEmpty;

  @override
  Stream<MeasurementUpdate> get updates => _spectra.metrics.map(_toUpdate);

  @override
  Stream<ProcessingStatus> get status => _spectra.status;

  @override
  Stream<ValidationStatus> get validation => _spectra.validation;

  @override
  Stream<SmartSpectraException> get errors => _spectra.errors;

  @override
  Future<bool> hasCameraPermission() => _spectra.hasCameraPermission();

  @override
  Future<bool> requestCameraPermission() => _spectra.requestCameraPermission();

  /// Configures and starts a measurement. Throws [SmartSpectraException]:
  /// [SmartSpectraErrorCode.configurationFailed] without an API key, or
  /// whatever the SDK reports (no network, bad key, no credits).
  @override
  Future<void> start() async {
    if (!hasApiKey) {
      throw const SmartSpectraException(
        code: SmartSpectraErrorCode.configurationFailed,
        message: 'SMARTSPECTRA_API_KEY was not passed at build time',
      );
    }
    if (_spectra.isActive) {
      await _spectra.stop();
    }
    await _spectra.configure(
      // dnsFallback: some home routers cannot resolve Presage's servers
      // (docs/04); disclosed on the consent screen.
      const SmartSpectraConfig(
        apiKey: _apiKey,
        metrics: _metrics,
        dnsFallback: true,
      ),
    );
    await _spectra.start();
  }

  /// Stops measuring and releases the camera. Safe to call when stopped.
  @override
  Future<void> stop() async {
    if (_spectra.currentStatus == ProcessingStatus.idle) {
      return;
    }
    await _spectra.stop();
  }

  /// Recovers the SDK after [ProcessingStatus.error].
  @override
  Future<void> reset() => _spectra.reset();

  static MeasurementUpdate _toUpdate(SmartSpectraMetrics metrics) {
    final pulse = metrics.pulseRate;
    final expression = metrics.expression;
    return MeasurementUpdate(
      pulse: pulse == null
          ? null
          : PulseSample(
              bpm: pulse.value,
              confidence: pulse.confidence,
              stable: pulse.stable,
              timestampUs: pulse.timestampUs,
            ),
      expression: expression == null || expression.scores.isEmpty
          ? null
          : ExpressionSample(
              angry: expression[Expression.angry],
              contempt: expression[Expression.contempt],
              disgust: expression[Expression.disgust],
              timestampUs: expression.timestampUs,
            ),
    );
  }
}

/// Not final, so a test can swap in a fake (as with `appDatabase`).
MeasurementSource measurementService = _MeasurementService();
