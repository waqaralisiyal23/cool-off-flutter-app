import 'dart:async';
import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:smartspectra_flutter/smartspectra_flutter.dart';

import '../engine/signal_collector.dart';
import 'measurement_service.dart';

/// A stand-in for the SDK that produces believable readings, in place of the
/// camera. Never used unless [simulateMeasurement] is set.
///
/// * **Calm:** pulse around 70, a relaxed face.
/// * **Heated:** pulse around 96 and a tense face; after 25 s of measuring
///   both settle towards calm, so a cool-down shows a real drop.
///
/// Like the SDK, the pulse first appears ~12 s after the start, the screen
/// shows a short "center your face" hint early on, and the measurement stops
/// when the app leaves the screen.
class SimulatedMeasurementSource implements MeasurementSource {
  SimulatedMeasurementSource() {
    _lifecycle = AppLifecycleListener(
      onHide: () {
        if (_timer != null) unawaited(stop());
      },
    );
  }

  /// Settings → Demo → Simulated reading. Read at each start.
  bool heated = false;

  static const Duration _frame = Duration(milliseconds: 500);
  static const double _pulseAfterSeconds = 12;
  static const double _settleAfterSeconds = 25;
  static const double _settleSeconds = 20;

  final _updates = StreamController<MeasurementUpdate>.broadcast();
  final _status = StreamController<ProcessingStatus>.broadcast();
  final _validation = StreamController<ValidationStatus>.broadcast();
  final _errors = StreamController<SmartSpectraException>.broadcast();
  final _random = Random();
  late final AppLifecycleListener _lifecycle;

  Timer? _timer;
  Timer? _starting;
  final _clock = Stopwatch();
  int _timestampUs = 0;
  bool _sessionHeated = false;

  @override
  bool get hasApiKey => true;

  @override
  Stream<MeasurementUpdate> get updates => _updates.stream;

  @override
  Stream<ProcessingStatus> get status => _status.stream;

  @override
  Stream<ValidationStatus> get validation => _validation.stream;

  @override
  Stream<SmartSpectraException> get errors => _errors.stream;

  @override
  Future<bool> hasCameraPermission() async => true;

  @override
  Future<bool> requestCameraPermission() async => true;

  @override
  Future<void> start() async {
    await stop();
    _sessionHeated = heated;
    _status.add(ProcessingStatus.starting);
    // The SDK takes a moment to check its key and open the camera.
    _starting = Timer(const Duration(milliseconds: 900), () {
      _status.add(ProcessingStatus.running);
      _clock
        ..reset()
        ..start();
      _timer = Timer.periodic(_frame, (_) => _emitFrame());
    });
  }

  @override
  Future<void> stop() async {
    final wasRunning = _timer != null || _starting != null;
    _starting?.cancel();
    _starting = null;
    _timer?.cancel();
    _timer = null;
    _clock.stop();
    if (wasRunning) {
      _status
        ..add(ProcessingStatus.stopping)
        ..add(ProcessingStatus.idle);
    }
  }

  @override
  Future<void> reset() => stop();

  void _emitFrame() {
    final t = _clock.elapsedMilliseconds / 1000;
    _timestampUs += _frame.inMicroseconds;

    // A short imaging hint at the start, as the SDK gives while you settle.
    if (t > 2 && t < 2.6) {
      _validation.add(
        const ValidationStatus(code: ValidationCode.faceNotCentered, hint: ''),
      );
    } else if (t > 4.5 && t < 5.1) {
      _validation.add(
        const ValidationStatus(code: ValidationCode.ok, hint: ''),
      );
    }

    // How heated this moment is: 1 → settles to 0 after [_settleAfterSeconds].
    final heat = !_sessionHeated
        ? 0.0
        : t < _settleAfterSeconds
        ? 1.0
        : exp(-(t - _settleAfterSeconds) / (_settleSeconds / 3));

    final pulse = 70 + 26 * heat + _noise(1.5);
    final angry = (3 + 45 * heat + _noise(3)).clamp(0, 100).toDouble();

    _updates.add(
      MeasurementUpdate(
        pulse: t < _pulseAfterSeconds
            ? null
            : PulseSample(
                bpm: pulse,
                confidence: 85,
                stable: true,
                timestampUs: _timestampUs,
              ),
        expression: ExpressionSample(
          angry: angry,
          contempt: heated ? 4 * heat : 0,
          disgust: 0,
          timestampUs: _timestampUs,
        ),
      ),
    );
  }

  double _noise(double amplitude) => (_random.nextDouble() * 2 - 1) * amplitude;

  void dispose() => _lifecycle.dispose();
}
