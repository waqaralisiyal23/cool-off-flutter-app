import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'package:wc_dart_framework/wc_dart_framework.dart';

part 'notification_kind.g.dart';
part 'notification_kind.enum.g.dart';

/// What a scheduled local notification is for.
///
/// Stored by its snake_case wire name (docs/11-data-and-sync.md).
@EnumGen()
class NotificationKind extends EnumClass {
  static Serializer<NotificationKind> get serializer =>
      _$notificationKindSerializer;

  static BuiltSet<NotificationKind> get values => _$values;

  static NotificationKind valueOf(String name) => _$valueOf(name);

  @BuiltValueEnumConst(wireName: 'hold_ended')
  static const NotificationKind holdEnded = _$holdEnded;
  static const NotificationKind checkin = _$checkin;

  const NotificationKind._(super.name);
}
