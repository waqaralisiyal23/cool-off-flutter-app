import 'dart:async';

import 'package:cooloff/database/app_database.dart';
import 'package:cooloff/engine/signal_collector.dart';
import 'package:cooloff/models/data/baseline_data.dart';
import 'package:cooloff/models/data/user_settings_data.dart';
import 'package:cooloff/models/enums/sensitivity.dart';
import 'package:cooloff/services/measurement_service.dart';
import 'package:drift/native.dart';
import 'package:smartspectra_flutter/smartspectra_flutter.dart';

/// Stands in for the SDK. Tests drive status, samples and errors by hand.
///
/// Each listen gets its own single-subscription controller whose cancel
/// future is created in the caller's zone: a broadcast controller's cancel
/// returns a root-zone future, which `fake_async` never completes.
class FakeMeasurementSource implements MeasurementSource {
  final _updates = _Feed<MeasurementUpdate>();
  final _status = _Feed<ProcessingStatus>();
  final _validation = _Feed<ValidationStatus>();
  final _errors = _Feed<SmartSpectraException>();

  int startCalls = 0;
  int stopCalls = 0;

  /// Thrown by the next [start], like the SDK refusing to start.
  SmartSpectraException? failNextStart;

  int _timestampUs = 0;

  @override
  bool get hasApiKey => true;

  @override
  Stream<MeasurementUpdate> get updates => _updates.listenable();

  @override
  Stream<ProcessingStatus> get status => _status.listenable();

  @override
  Stream<ValidationStatus> get validation => _validation.listenable();

  @override
  Stream<SmartSpectraException> get errors => _errors.listenable();

  @override
  Future<bool> hasCameraPermission() async => true;

  @override
  Future<bool> requestCameraPermission() async => true;

  @override
  Future<void> start() async {
    startCalls++;
    final failure = failNextStart;
    if (failure != null) {
      failNextStart = null;
      throw failure;
    }
  }

  @override
  Future<void> stop() async => stopCalls++;

  @override
  Future<void> reset() async {}

  void emitStatus(ProcessingStatus status) => _status.add(status);

  void emitError(SmartSpectraException error) => _errors.add(error);

  void emitHint(ValidationCode code) =>
      _validation.add(ValidationStatus(code: code, hint: ''));

  /// One frame, half a second after the previous one.
  void emitFrame({double? pulse, double angry = 0}) {
    _timestampUs += 500000;
    _updates.add(
      MeasurementUpdate(
        pulse: pulse == null
            ? null
            : PulseSample(
                bpm: pulse,
                confidence: 90,
                stable: true,
                timestampUs: _timestampUs,
              ),
        expression: ExpressionSample(
          angry: angry,
          contempt: 0,
          disgust: 0,
          timestampUs: _timestampUs,
        ),
      ),
    );
  }
}

/// Fans events out to every live subscription.
class _Feed<T> {
  final List<StreamController<T>> _controllers = [];

  Stream<T> listenable() {
    late final StreamController<T> controller;
    controller = StreamController<T>(
      onCancel: () {
        _controllers.remove(controller);
        return Future<void>.value();
      },
    );
    _controllers.add(controller);
    return controller.stream;
  }

  void add(T event) {
    for (final controller in [..._controllers]) {
      controller.add(event);
    }
  }
}

AppDatabase openTestDatabase() =>
    appDatabase = AppDatabase(NativeDatabase.memory(), deviceId: 'test-device');

UserSettingsData testSettings({
  Sensitivity sensitivity = Sensitivity.normal,
  int autoTuneOffset = 0,
  bool checkinEnabled = true,
  bool keepMessageText = false,
}) {
  final now = DateTime.utc(2026, 11, 9);
  return UserSettingsData(
    (b) => b
      ..id = 'settings'
      ..createdAt = now
      ..updatedAt = now
      ..isDirty = true
      ..originDeviceId = 'test-device'
      ..sensitivity = sensitivity
      ..autoTuneOffset = autoTuneOffset
      ..holdMinutes = 10
      ..checkinMinutes = 540
      ..checkinEnabled = checkinEnabled
      ..keepMessageText = keepMessageText
      ..hapticsEnabled = false,
  );
}

BaselineData testBaseline({double pulse = 70, double anger = 5}) {
  final now = DateTime.utc(2026, 11, 9);
  return BaselineData(
    (b) => b
      ..id = 'baseline'
      ..createdAt = now
      ..updatedAt = now
      ..isDirty = true
      ..originDeviceId = 'test-device'
      ..measuredAt = now
      ..pulseBpm = pulse
      ..angerLevel = anger
      ..sampleCount = 30,
  );
}
