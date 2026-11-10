import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

import '../serializers.dart';

part 'baseline_data.g.dart';

/// A `baselines` row: the user's usual pulse and resting anger level.
///
/// The latest active row is the current baseline; older ones are history.
///
/// Drift reads rows straight into this (`@UseRowClass`); wire names match
/// the table columns.
abstract class BaselineData
    implements Built<BaselineData, BaselineDataBuilder> {
  BaselineData._();

  factory BaselineData([void Function(BaselineDataBuilder) updates]) =
      _$BaselineData;

  /// The constructor drift maps each row through.
  factory BaselineData.fromRow({
    required String id,
    required DateTime createdAt,
    required DateTime updatedAt,
    DateTime? deletedAt,
    required bool isDirty,
    DateTime? serverUpdatedAt,
    required String originDeviceId,
    required DateTime measuredAt,
    required double pulseBpm,
    required double angerLevel,
    required int sampleCount,
  }) => BaselineData(
    (b) => b
      ..id = id
      ..createdAt = createdAt
      ..updatedAt = updatedAt
      ..deletedAt = deletedAt
      ..isDirty = isDirty
      ..serverUpdatedAt = serverUpdatedAt
      ..originDeviceId = originDeviceId
      ..measuredAt = measuredAt
      ..pulseBpm = pulseBpm
      ..angerLevel = angerLevel
      ..sampleCount = sampleCount,
  );

  static Serializer<BaselineData> get serializer => _$baselineDataSerializer;

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

  @BuiltValueField(wireName: 'measured_at')
  DateTime get measuredAt;

  @BuiltValueField(wireName: 'pulse_bpm')
  double get pulseBpm;

  /// Mean of angry + contempt + disgust at rest (0–100).
  @BuiltValueField(wireName: 'anger_level')
  double get angerLevel;

  /// Pulse samples the baseline is based on.
  @BuiltValueField(wireName: 'sample_count')
  int get sampleCount;

  static BaselineData fromDynamic(dynamic json) =>
      serializers.deserializeWith(BaselineData.serializer, json)!;

  dynamic toDynamic() => serializers.serializeWith(serializer, this);
}
