import 'package:built_value/built_value.dart';

part 'result_state.g.dart';

/// What the user chose; the page navigates once it is set.
enum ResultChoice { sent, held, coolDown, edited, discarded }

abstract class ResultState implements Built<ResultState, ResultStateBuilder> {
  factory ResultState([void Function(ResultStateBuilder) updates]) =
      _$ResultState;

  ResultState._();

  @BuiltValueHook(initializeBuilder: true)
  static void _initialize(ResultStateBuilder b) => b.isBusy = false;

  bool get isBusy;

  ResultChoice? get choice;

  /// For [ResultChoice.held]: when it is ready.
  DateTime? get heldUntil;

  String? get error;
}
