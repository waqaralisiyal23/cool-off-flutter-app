import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';

import '../../../../models/check_outcome.dart';
import '../../../../services/measurement_session.dart';
import '../../result/bloc/result_state.dart';

part 'cooldown_state.g.dart';

enum CooldownPhase {
  starting,

  /// The 60-second cool-down, with the live pulse graph.
  cooling,

  /// The last 20 seconds: the automatic re-check, same camera session.
  rechecking,
  analyzing,

  /// The before/after card.
  done,
  failed,
  interrupted,
}

abstract class CooldownState
    implements Built<CooldownState, CooldownStateBuilder> {
  factory CooldownState([void Function(CooldownStateBuilder) updates]) =
      _$CooldownState;

  CooldownState._();

  @BuiltValueHook(initializeBuilder: true)
  static void _initialize(CooldownStateBuilder b) => b
    ..phase = CooldownPhase.starting
    ..progress = 0
    ..secondsLeft = 60
    ..isBusy = false;

  CooldownPhase get phase;

  /// 0–1 over cool-down + re-check.
  double get progress;

  /// Seconds left in the current phase.
  int get secondsLeft;

  double? get livePulse;

  /// One pulse value per second since the first reading, for the graph.
  BuiltList<double> get pulseSeries;

  String? get hint;

  MeasurementFailure? get failure;

  /// The re-check, with the original as `previous`.
  CheckOutcome? get recheck;

  bool get isBusy;

  /// Set when the user acted on the re-check; the page navigates.
  ResultChoice? get choice;

  DateTime? get heldUntil;
}
