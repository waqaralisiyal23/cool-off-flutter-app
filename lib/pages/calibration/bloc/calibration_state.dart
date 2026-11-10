import 'package:built_value/built_value.dart';

import '../../../engine/baseline_calculator.dart';
import '../../../services/measurement_session.dart';

part 'calibration_state.g.dart';

enum CalibrationPhase {
  /// Tips, and a Start button.
  intro,

  /// The SDK is checking its key and opening the camera.
  starting,
  measuring,
  saving,
  done,

  /// The SDK failed ([CalibrationState.failure]) or the reading was too
  /// poor ([CalibrationState.baselineFailure]).
  failed,
}

abstract class CalibrationState
    implements Built<CalibrationState, CalibrationStateBuilder> {
  factory CalibrationState([void Function(CalibrationStateBuilder) updates]) =
      _$CalibrationState;

  CalibrationState._();

  @BuiltValueHook(initializeBuilder: true)
  static void _initialize(CalibrationStateBuilder b) => b
    ..phase = CalibrationPhase.intro
    ..progress = 0
    ..wasInterrupted = false;

  CalibrationPhase get phase;

  /// 0–1 over the 30 seconds.
  double get progress;

  /// The latest steady pulse, for the beating heart.
  double? get livePulse;

  String? get hint;

  /// The app went to the background mid-reading; it starts over.
  bool get wasInterrupted;

  MeasurementFailure? get failure;

  BaselineFailure? get baselineFailure;

  BaselineValues? get result;
}
