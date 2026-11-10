import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

import '../enums/sensitivity.dart';
import '../serializers.dart';

part 'user_settings_data.g.dart';

/// The one `user_settings` row.
///
/// Drift reads rows straight into this (`@UseRowClass`); wire names match
/// the table columns.
abstract class UserSettingsData
    implements Built<UserSettingsData, UserSettingsDataBuilder> {
  UserSettingsData._();

  factory UserSettingsData([void Function(UserSettingsDataBuilder) updates]) =
      _$UserSettingsData;

  /// The constructor drift maps each row through.
  factory UserSettingsData.fromRow({
    required String id,
    required DateTime createdAt,
    required DateTime updatedAt,
    DateTime? deletedAt,
    required bool isDirty,
    DateTime? serverUpdatedAt,
    required String originDeviceId,
    required Sensitivity sensitivity,
    required int autoTuneOffset,
    required int holdMinutes,
    required int checkinMinutes,
    required bool checkinEnabled,
    required bool keepMessageText,
    required bool hapticsEnabled,
  }) => UserSettingsData(
    (b) => b
      ..id = id
      ..createdAt = createdAt
      ..updatedAt = updatedAt
      ..deletedAt = deletedAt
      ..isDirty = isDirty
      ..serverUpdatedAt = serverUpdatedAt
      ..originDeviceId = originDeviceId
      ..sensitivity = sensitivity
      ..autoTuneOffset = autoTuneOffset
      ..holdMinutes = holdMinutes
      ..checkinMinutes = checkinMinutes
      ..checkinEnabled = checkinEnabled
      ..keepMessageText = keepMessageText
      ..hapticsEnabled = hapticsEnabled,
  );

  static Serializer<UserSettingsData> get serializer =>
      _$userSettingsDataSerializer;

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

  Sensitivity get sensitivity;

  /// Learned from check-ins: −1, 0 or +1 (docs/03-heat-engine.md).
  @BuiltValueField(wireName: 'auto_tune_offset')
  int get autoTuneOffset;

  @BuiltValueField(wireName: 'hold_minutes')
  int get holdMinutes;

  /// Next-morning check-in time, in minutes after local midnight.
  @BuiltValueField(wireName: 'checkin_minutes')
  int get checkinMinutes;

  @BuiltValueField(wireName: 'checkin_enabled')
  bool get checkinEnabled;

  @BuiltValueField(wireName: 'keep_message_text')
  bool get keepMessageText;

  @BuiltValueField(wireName: 'haptics_enabled')
  bool get hapticsEnabled;

  static UserSettingsData fromDynamic(dynamic json) =>
      serializers.deserializeWith(UserSettingsData.serializer, json)!;

  dynamic toDynamic() => serializers.serializeWith(serializer, this);
}
