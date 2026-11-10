import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

import '../enums/reflection_answer.dart';
import '../serializers.dart';

part 'reflection_data.g.dart';

/// A `reflections` row: the next-morning answer for a heated send.
///
/// Drift reads rows straight into this (`@UseRowClass`); wire names match
/// the table columns.
abstract class ReflectionData
    implements Built<ReflectionData, ReflectionDataBuilder> {
  ReflectionData._();

  factory ReflectionData([void Function(ReflectionDataBuilder) updates]) =
      _$ReflectionData;

  /// The constructor drift maps each row through.
  factory ReflectionData.fromRow({
    required String id,
    required DateTime createdAt,
    required DateTime updatedAt,
    DateTime? deletedAt,
    required bool isDirty,
    DateTime? serverUpdatedAt,
    required String originDeviceId,
    required String checkRecordId,
    required ReflectionAnswer answer,
    required DateTime answeredAt,
  }) => ReflectionData(
    (b) => b
      ..id = id
      ..createdAt = createdAt
      ..updatedAt = updatedAt
      ..deletedAt = deletedAt
      ..isDirty = isDirty
      ..serverUpdatedAt = serverUpdatedAt
      ..originDeviceId = originDeviceId
      ..checkRecordId = checkRecordId
      ..answer = answer
      ..answeredAt = answeredAt,
  );

  static Serializer<ReflectionData> get serializer =>
      _$reflectionDataSerializer;

  String get id;

  @BuiltValueField(wireName: 'created_at')
  DateTime get createdAt;

  @BuiltValueField(wireName: 'updated_at')
  DateTime get updatedAt;

  @BuiltValueField(wireName: 'deleted_at')
  DateTime? get deletedAt;

  @BuiltValueField(wireName: 'is_dirty')
  bool get isDirty;

  @BuiltValueField(wireName: 'server_updated_at')
  DateTime? get serverUpdatedAt;

  @BuiltValueField(wireName: 'origin_device_id')
  String get originDeviceId;

  @BuiltValueField(wireName: 'check_record_id')
  String get checkRecordId;

  ReflectionAnswer get answer;

  @BuiltValueField(wireName: 'answered_at')
  DateTime get answeredAt;

  static ReflectionData fromDynamic(dynamic json) =>
      serializers.deserializeWith(ReflectionData.serializer, json)!;

  dynamic toDynamic() => serializers.serializeWith(serializer, this);
}
