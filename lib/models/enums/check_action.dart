import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'package:wc_dart_framework/wc_dart_framework.dart';

part 'check_action.g.dart';
part 'check_action.enum.g.dart';

/// What the user did with a check's result.
///
/// Stored by its snake_case wire name (docs/11-data-and-sync.md).
@EnumGen()
class CheckAction extends EnumClass {
  static Serializer<CheckAction> get serializer => _$checkActionSerializer;

  static BuiltSet<CheckAction> get values => _$values;

  static CheckAction valueOf(String name) => _$valueOf(name);

  static const CheckAction sent = _$sent;
  @BuiltValueEnumConst(wireName: 'sent_anyway')
  static const CheckAction sentAnyway = _$sentAnyway;
  static const CheckAction held = _$held;
  @BuiltValueEnumConst(wireName: 'cooled_down')
  static const CheckAction cooledDown = _$cooledDown;
  static const CheckAction edited = _$edited;
  static const CheckAction discarded = _$discarded;
  static const CheckAction cancelled = _$cancelled;
  static const CheckAction interrupted = _$interrupted;

  const CheckAction._(super.name);

  /// The message went out (through the share sheet).
  bool get isSend => this == sent || this == sentAnyway;

  /// The user did not send the message as it was: held, cooled down, edited
  /// or discarded it. Insights counts these as "cooled off".
  bool get isCooledOff =>
      this == held || this == cooledDown || this == edited || this == discarded;
}
