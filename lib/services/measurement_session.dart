import 'dart:async';

import 'package:flutter/widgets.dart';

import 'package:smartspectra_flutter/smartspectra_flutter.dart';
import 'package:wc_dart_framework/wc_dart_framework.dart';

import '../engine/signal_collector.dart';
import 'error_reporting_service.dart';
import 'measurement_service.dart';

final _logger = Logger('measurement_session.dart');

/// Why a measurement could not run, in words the user can act on.
class MeasurementFailure {
  const MeasurementFailure({
    required this.title,
    required this.message,
    required this.canRetry,
  });

  final String title;
  final String message;
  final bool canRetry;

  static MeasurementFailure fromException(SmartSpectraException e) =>
      switch (e.code) {
        SmartSpectraErrorCode.networkError ||
        SmartSpectraErrorCode.serverError => const MeasurementFailure(
          title: "Can't reach the measurement service",
          message:
              'Check your internet connection and try again. The first check '
              'needs the internet to load the measurement models.',
          canRetry: true,
        ),
        SmartSpectraErrorCode.inputUnavailable => const MeasurementFailure(
          title: 'Camera unavailable',
          message:
              'Cool Off needs the front camera for the check. Allow camera '
              "access in your phone's Settings, or close other camera apps.",
          canRetry: true,
        ),
        SmartSpectraErrorCode.authenticationFailed ||
        SmartSpectraErrorCode.configurationFailed => const MeasurementFailure(
          title: "Measurement isn't set up",
          message:
              'The measurement key was missing or not accepted. This build '
              'needs a valid SmartSpectra API key.',
          canRetry: false,
        ),
        SmartSpectraErrorCode.creditExhausted => const MeasurementFailure(
          title: 'Measurement limit reached',
          message:
              "This build's measurement trial has run out. You can still send "
              'your message without a check.',
          canRetry: false,
        ),
        _ => const MeasurementFailure(
          title: 'The check stopped',
          message: 'Something went wrong while measuring. Please try again.',
          canRetry: true,
        ),
      };
}

/// Short, friendly guidance for the SDK's imaging hints, or null when
/// there is nothing to say.
String? hintFor(ValidationStatus status) => switch (status.code) {
  ValidationCode.ok => null,
  ValidationCode.noFaceFound => "Can't see your face",
  ValidationCode.multipleFacesFound => 'Just one face, please',
  ValidationCode.faceNotCentered ||
  ValidationCode.faceTooHigh ||
  ValidationCode.faceTooLow => 'Center your face in the circle',
  ValidationCode.faceTooClose => 'Move back a little',
  ValidationCode.faceTooFar => 'Move a little closer',
  ValidationCode.faceSizeOutOfRange => 'Adjust your distance',
  ValidationCode.tooDark => 'Find a bit more light',
  ValidationCode.tooBright => 'Too bright: avoid direct light',
  ValidationCode.excessiveMotion => 'Hold still',
  ValidationCode.faceNotForward => 'Look straight at the screen',
  ValidationCode.cameraTuning => 'Adjusting the camera…',
  ValidationCode.frameRateTooLow => 'Hold on…',
  ValidationCode.chestNotVisible => null,
  ValidationCode.unknown => status.hint.isEmpty ? null : status.hint,
};

/// One running measurement (calibration, check or cool-down): starts the
/// SDK, collects samples into [collector], and reports back through
/// callbacks. The bloc that creates it owns it and must [stop] it in
/// `close()`.
///
/// [onInterrupted] fires when the SDK stops on its own while measuring:
/// the plugin stops the camera whenever the app leaves the screen. The
/// measurement is then restarted from zero, never resumed
/// (docs/04-smartspectra-plugin.md).
class MeasurementSession {
  MeasurementSession({
    required this.operation,
    required this.onRunning,
    required this.onSample,
    required this.onHint,
    required this.onFailure,
    required this.onInterrupted,
  });

  /// `calibration`, `check` or `cooldown`, for error reports.
  final String operation;

  final void Function() onRunning;

  /// After each update that added a sample.
  final void Function(SignalCollector collector) onSample;
  final void Function(String? hint) onHint;
  final void Function(MeasurementFailure failure) onFailure;
  final void Function() onInterrupted;

  final SignalCollector collector = SignalCollector();
  final List<StreamSubscription<Object?>> _subscriptions = [];

  bool _running = false;
  bool _stopping = false;

  /// Live native previews (`SmartSpectraPreview.onReady` minus disposals).
  int _previews = 0;
  Completer<void>? _previewWaiter;

  /// If a preview never reports ready, start anyway after this long rather
  /// than hang. Logged, as it means the preview may be missing.
  static const Duration previewTimeout = Duration(seconds: 3);

  bool get isRunning => _running;

  /// The screen's `SmartSpectraPreview` exists and is attached to the SDK.
  void previewReady() {
    _previews++;
    final waiter = _previewWaiter;
    if (waiter != null && !waiter.isCompleted) {
      waiter.complete();
    }
  }

  /// The screen's preview was removed.
  void previewGone() {
    if (_previews > 0) {
      _previews--;
    }
  }

  Future<void> start() async {
    await _cancelSubscriptions();
    collector.clear();
    _running = false;
    _stopping = false;
    _subscriptions
      ..add(measurementService.updates.listen(_onUpdate))
      ..add(measurementService.status.listen(_onStatus))
      ..add(measurementService.validation.listen((v) => onHint(hintFor(v))))
      ..add(
        measurementService.errors.listen((e) => _fail(e, StackTrace.current)),
      );
    // The preview must exist before the SDK starts, or the camera runs with
    // no visible preview (docs/04): wait for the plugin's onReady.
    await _waitForPreview();
    if (_stopping) {
      return;
    }
    try {
      await measurementService.start();
    } on SmartSpectraException catch (e, stackTrace) {
      await _fail(e, stackTrace);
    }
  }

  Future<void> _waitForPreview() async {
    if (_previews > 0) {
      return;
    }
    final waiter = _previewWaiter = Completer<void>();
    try {
      await waiter.future.timeout(previewTimeout);
    } on TimeoutException {
      _logger.warning('No preview after $previewTimeout; starting anyway');
    } finally {
      _previewWaiter = null;
    }
  }

  Future<void> stop() async {
    _stopping = true;
    _running = false;
    await _cancelSubscriptions();
    try {
      await measurementService.stop();
    } on SmartSpectraException catch (e) {
      _logger.warning('Stopping the measurement failed: $e');
    }
  }

  void _onUpdate(MeasurementUpdate update) {
    if (!_running) {
      return;
    }
    var added = false;
    final pulse = update.pulse;
    if (pulse != null) {
      added = collector.addPulse(pulse) || added;
    }
    final expression = update.expression;
    if (expression != null) {
      added = collector.addExpression(expression) || added;
    }
    if (added) {
      onSample(collector);
    }
  }

  void _onStatus(ProcessingStatus status) {
    switch (status) {
      case ProcessingStatus.running:
        if (!_running && !_stopping) {
          _running = true;
          onRunning();
        }
      case ProcessingStatus.idle || ProcessingStatus.stopping:
        // Only leaving the app interrupts a measurement. The SDK sometimes
        // restarts the camera once right after starting (docs/04); while the
        // app is in front that is a hiccup, not an interruption.
        final lifecycle = WidgetsBinding.instance.lifecycleState;
        final inFront =
            lifecycle == null || lifecycle == AppLifecycleState.resumed;
        if (_running && !_stopping && !inFront) {
          _running = false;
          onInterrupted();
        }
      case ProcessingStatus.starting || ProcessingStatus.error:
        break;
    }
  }

  Future<void> _fail(SmartSpectraException e, StackTrace stackTrace) async {
    if (_stopping) {
      return;
    }
    _logger.warning('Measurement $operation failed: $e');
    await stop();
    onFailure(MeasurementFailure.fromException(e));
    await errorReportingService.recordMeasurementFailure(
      e,
      stackTrace,
      operation: operation,
      code: e.code.name,
      retryable: e.retryable,
    );
    try {
      await measurementService.reset();
    } on SmartSpectraException catch (resetError) {
      _logger.warning('Reset after failure failed: $resetError');
    }
  }

  Future<void> _cancelSubscriptions() async {
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    _subscriptions.clear();
  }
}
