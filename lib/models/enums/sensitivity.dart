import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'package:wc_dart_framework/wc_dart_framework.dart';

part 'sensitivity.g.dart';
part 'sensitivity.enum.g.dart';

/// How readily a check reads Warm or Heated (Settings).
///
/// Stored by its snake_case wire name (docs/11-data-and-sync.md).
@EnumGen()
class Sensitivity extends EnumClass {
  static Serializer<Sensitivity> get serializer => _$sensitivitySerializer;

  static BuiltSet<Sensitivity> get values => _$values;

  static Sensitivity valueOf(String name) => _$valueOf(name);

  static const Sensitivity low = _$low;
  static const Sensitivity normal = _$normal;
  static const Sensitivity high = _$high;

  const Sensitivity._(super.name);

  String get label =>
      when(low: () => 'Low', normal: () => 'Normal', high: () => 'High');

  /// How far the Warm and Heated cutoffs move: high sensitivity lowers them
  /// (more Heated results), low raises them (docs/03-heat-engine.md).
  int get cutoffShift => when(low: () => 1, normal: () => 0, high: () => -1);
}
