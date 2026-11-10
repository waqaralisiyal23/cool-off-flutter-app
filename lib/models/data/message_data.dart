import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

import '../enums/message_status.dart';
import '../serializers.dart';

part 'message_data.g.dart';

/// A `messages` row: a held or sent message.
///
/// [body] is kept only while held, or when "Keep message text" is on
/// (docs/11-data-and-sync.md).
///
/// Drift reads rows straight into this (`@UseRowClass`); wire names match
/// the table columns.
abstract class MessageData implements Built<MessageData, MessageDataBuilder> {
  MessageData._();

  factory MessageData([void Function(MessageDataBuilder) updates]) =
      _$MessageData;

  /// The constructor drift maps each row through.
  factory MessageData.fromRow({
    required String id,
    required DateTime createdAt,
    required DateTime updatedAt,
    DateTime? deletedAt,
    required bool isDirty,
    DateTime? serverUpdatedAt,
    required String originDeviceId,
    String? body,
    String? recipientLabel,
    required MessageStatus status,
    DateTime? holdUntil,
    DateTime? sentAt,
    String? firstCheckId,
  }) => MessageData(
    (b) => b
      ..id = id
      ..createdAt = createdAt
      ..updatedAt = updatedAt
      ..deletedAt = deletedAt
      ..isDirty = isDirty
      ..serverUpdatedAt = serverUpdatedAt
      ..originDeviceId = originDeviceId
      ..body = body
      ..recipientLabel = recipientLabel
      ..status = status
      ..holdUntil = holdUntil
      ..sentAt = sentAt
      ..firstCheckId = firstCheckId,
  );

  static Serializer<MessageData> get serializer => _$messageDataSerializer;

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

  String? get body;

  /// Optional free text: "to whom".
  @BuiltValueField(wireName: 'recipient_label')
  String? get recipientLabel;

  MessageStatus get status;

  @BuiltValueField(wireName: 'hold_until')
  DateTime? get holdUntil;

  @BuiltValueField(wireName: 'sent_at')
  DateTime? get sentAt;

  @BuiltValueField(wireName: 'first_check_id')
  String? get firstCheckId;

  static MessageData fromDynamic(dynamic json) =>
      serializers.deserializeWith(MessageData.serializer, json)!;

  dynamic toDynamic() => serializers.serializeWith(serializer, this);
}
