import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'package:wc_dart_framework/wc_dart_framework.dart';

part 'message_status.g.dart';
part 'message_status.enum.g.dart';

/// Where a saved message stands.
///
/// Stored by its snake_case wire name (docs/11-data-and-sync.md).
@EnumGen()
class MessageStatus extends EnumClass {
  static Serializer<MessageStatus> get serializer => _$messageStatusSerializer;

  static BuiltSet<MessageStatus> get values => _$values;

  static MessageStatus valueOf(String name) => _$valueOf(name);

  static const MessageStatus held = _$held;
  static const MessageStatus sent = _$sent;
  static const MessageStatus discarded = _$discarded;

  const MessageStatus._(super.name);
}
