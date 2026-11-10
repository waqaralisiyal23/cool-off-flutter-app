import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

import '../enums/check_action.dart';
import '../enums/check_kind.dart';
import '../enums/heat_level.dart';
import '../enums/sensitivity.dart';
import '../serializers.dart';

part 'check_record_data.g.dart';

/// A `check_records` row: one check, re-check or failed baseline attempt.
///
/// Holds numbers and the result only. Never message text.
///
/// Drift reads rows straight into this (`@UseRowClass`); wire names match
/// the table columns.
abstract class CheckRecordData
    implements Built<CheckRecordData, CheckRecordDataBuilder> {
  CheckRecordData._();

  factory CheckRecordData([void Function(CheckRecordDataBuilder) updates]) =
      _$CheckRecordData;

  /// The constructor drift maps each row through.
  factory CheckRecordData.fromRow({
    required String id,
    required DateTime createdAt,
    required DateTime updatedAt,
    DateTime? deletedAt,
    required bool isDirty,
    DateTime? serverUpdatedAt,
    required String originDeviceId,
    required DateTime checkedAt,
    required CheckKind kind,
    HeatLevel? heatLevel,
    int? score,
    double? pulseBpm,
    String? baselineId,
    double? pulseDeltaPct,
    double? angerLevel,
    int? textHeat,
    required Sensitivity sensitivity,
    CheckAction? action,
    String? messageId,
    String? previousCheckId,
  }) => CheckRecordData(
    (b) => b
      ..id = id
      ..createdAt = createdAt
      ..updatedAt = updatedAt
      ..deletedAt = deletedAt
      ..isDirty = isDirty
      ..serverUpdatedAt = serverUpdatedAt
      ..originDeviceId = originDeviceId
      ..checkedAt = checkedAt
      ..kind = kind
      ..heatLevel = heatLevel
      ..score = score
      ..pulseBpm = pulseBpm
      ..baselineId = baselineId
      ..pulseDeltaPct = pulseDeltaPct
      ..angerLevel = angerLevel
      ..textHeat = textHeat
      ..sensitivity = sensitivity
      ..action = action
      ..messageId = messageId
      ..previousCheckId = previousCheckId,
  );

  static Serializer<CheckRecordData> get serializer =>
      _$checkRecordDataSerializer;

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

  @BuiltValueField(wireName: 'checked_at')
  DateTime get checkedAt;

  CheckKind get kind;

  /// Null when the check did not finish.
  @BuiltValueField(wireName: 'heat_level')
  HeatLevel? get heatLevel;

  int? get score;

  /// Null when the pulse could not be read. Never invented.
  @BuiltValueField(wireName: 'pulse_bpm')
  double? get pulseBpm;

  @BuiltValueField(wireName: 'baseline_id')
  String? get baselineId;

  @BuiltValueField(wireName: 'pulse_delta_pct')
  double? get pulseDeltaPct;

  /// Mean anger level over the check (0–100), before the baseline is subtracted.
  @BuiltValueField(wireName: 'anger_level')
  double? get angerLevel;

  /// 0, 1 or 2.
  @BuiltValueField(wireName: 'text_heat')
  int? get textHeat;

  Sensitivity get sensitivity;

  /// What the user did with the result; null until they chose.
  CheckAction? get action;

  @BuiltValueField(wireName: 'message_id')
  String? get messageId;

  /// For a re-check: the check it follows.
  @BuiltValueField(wireName: 'previous_check_id')
  String? get previousCheckId;

  static CheckRecordData fromDynamic(dynamic json) =>
      serializers.deserializeWith(CheckRecordData.serializer, json)!;

  dynamic toDynamic() => serializers.serializeWith(serializer, this);
}
