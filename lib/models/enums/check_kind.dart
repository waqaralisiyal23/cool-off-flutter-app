import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'package:wc_dart_framework/wc_dart_framework.dart';

part 'check_kind.g.dart';
part 'check_kind.enum.g.dart';

/// What a `check_records` row was.
///
/// Stored by its snake_case wire name (docs/11-data-and-sync.md).
@EnumGen()
class CheckKind extends EnumClass {
  static Serializer<CheckKind> get serializer => _$checkKindSerializer;

  static BuiltSet<CheckKind> get values => _$values;

  static CheckKind valueOf(String name) => _$valueOf(name);

  static const CheckKind check = _$check;
  static const CheckKind recheck = _$recheck;
  @BuiltValueEnumConst(wireName: 'baseline_attempt')
  static const CheckKind baselineAttempt = _$baselineAttempt;

  const CheckKind._(super.name);
}
