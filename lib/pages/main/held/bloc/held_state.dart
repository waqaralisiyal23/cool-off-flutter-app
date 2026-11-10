import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';

import '../../../../models/data/message_data.dart';

part 'held_state.g.dart';

abstract class HeldState implements Built<HeldState, HeldStateBuilder> {
  factory HeldState([void Function(HeldStateBuilder) updates]) = _$HeldState;

  HeldState._();

  /// Null while loading. Ready first.
  BuiltList<MessageData>? get messages;

  String? get error;
}
