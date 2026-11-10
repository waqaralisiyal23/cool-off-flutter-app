import 'package:drift/drift.dart';

import '../../models/data/message_data.dart';
import '../../models/enums/message_status.dart';
import '../converters/enum_converter.dart';
import '../converters/utc_date_time_converter.dart';
import 'sync_columns.dart';

/// Held and sent messages.
///
/// [body] is written only while a message is held, or when "Keep message
/// text" is on; sending or discarding clears it otherwise
/// (docs/11-data-and-sync.md).
@UseRowClass(MessageData, constructor: 'fromRow')
class Messages extends Table with SyncColumns {
  TextColumn get body => text().nullable()();

  TextColumn get recipientLabel => text().nullable()();

  TextColumn get status =>
      text().map(const EnumConverter<MessageStatus>(MessageStatus.discarded))();

  DateTimeColumn get holdUntil =>
      dateTime().nullable().map(const UtcDateTimeConverter())();

  DateTimeColumn get sentAt =>
      dateTime().nullable().map(const UtcDateTimeConverter())();

  TextColumn get firstCheckId => text().nullable()();
}
