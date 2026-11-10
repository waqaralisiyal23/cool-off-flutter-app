import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'package:wc_dart_framework/wc_dart_framework.dart';

part 'reflection_answer.g.dart';
part 'reflection_answer.enum.g.dart';

/// The answer to the next-morning check-in, "Glad you sent it?".
///
/// Stored by its snake_case wire name (docs/11-data-and-sync.md).
@EnumGen()
class ReflectionAnswer extends EnumClass {
  static Serializer<ReflectionAnswer> get serializer =>
      _$reflectionAnswerSerializer;

  static BuiltSet<ReflectionAnswer> get values => _$values;

  static ReflectionAnswer valueOf(String name) => _$valueOf(name);

  static const ReflectionAnswer glad = _$glad;
  static const ReflectionAnswer regret = _$regret;

  const ReflectionAnswer._(super.name);
}
