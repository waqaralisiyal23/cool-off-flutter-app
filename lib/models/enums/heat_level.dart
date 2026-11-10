import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'package:wc_dart_framework/wc_dart_framework.dart';

part 'heat_level.g.dart';
part 'heat_level.enum.g.dart';

/// How heated a check read: the result shown to the user.
///
/// Stored by its snake_case wire name (docs/11-data-and-sync.md).
@EnumGen()
class HeatLevel extends EnumClass {
  static Serializer<HeatLevel> get serializer => _$heatLevelSerializer;

  static BuiltSet<HeatLevel> get values => _$values;

  static HeatLevel valueOf(String name) => _$valueOf(name);

  static const HeatLevel calm = _$calm;
  static const HeatLevel warm = _$warm;
  static const HeatLevel heated = _$heated;

  const HeatLevel._(super.name);

  /// The word shown on the result.
  String get label =>
      when(calm: () => 'Calm', warm: () => 'Warm', heated: () => 'Heated');

  /// Higher is hotter. For comparisons and charts.
  int get rank => when(calm: () => 0, warm: () => 1, heated: () => 2);
}
