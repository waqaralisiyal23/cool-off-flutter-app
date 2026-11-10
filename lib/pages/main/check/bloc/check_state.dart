import 'package:built_value/built_value.dart';

import '../../../../models/check_outcome.dart';
import '../../../../services/measurement_session.dart';

part 'check_state.g.dart';

enum CheckPhase {
  /// Checking the key and opening the camera.
  starting,
  measuring,

  /// Measurement done; scoring and saving.
  analyzing,
  done,
  failed,

  /// The app left the screen; the check restarts on return.
  interrupted,
}

abstract class CheckState implements Built<CheckState, CheckStateBuilder> {
  factory CheckState([void Function(CheckStateBuilder) updates]) = _$CheckState;

  CheckState._();

  @BuiltValueHook(initializeBuilder: true)
  static void _initialize(CheckStateBuilder b) => b
    ..phase = CheckPhase.starting
    ..progress = 0
    ..secondsLeft = 20
    ..couldNotSeeFace = false;

  CheckPhase get phase;

  /// 0–1 over the check.
  double get progress;

  int get secondsLeft;

  double? get livePulse;

  String? get hint;

  MeasurementFailure? get failure;

  /// Finished without enough face frames to judge.
  bool get couldNotSeeFace;

  CheckOutcome? get outcome;
}
