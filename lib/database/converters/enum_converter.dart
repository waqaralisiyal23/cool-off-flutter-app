import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'package:drift/drift.dart';
import 'package:wc_dart_framework/wc_dart_framework.dart';

import '../../models/serializers.dart';

final _logger = Logger('enum_converter.dart');

/// Stores a built_value [EnumClass] by its wire name (`sent_anyway`), the
/// same value a future sync API would use (docs/11-data-and-sync.md).
///
/// A value this build does not know (written by a newer app version) reads
/// as [fallback] rather than failing the whole query, so one unexpected row
/// can never break a screen.
class EnumConverter<T extends EnumClass> extends TypeConverter<T, String> {
  final T fallback;

  const EnumConverter(this.fallback);

  @override
  T fromSql(String fromDb) {
    try {
      return serializers.deserialize(fromDb, specifiedType: FullType(T)) as T;
    } on DeserializationError catch (e) {
      _logger.warning('Unknown $T "$fromDb": $e');
      return fallback;
    }
  }

  @override
  String toSql(T value) =>
      serializers.serialize(value, specifiedType: FullType(T))! as String;
}
