import 'package:drift/drift.dart';

import '../../models/enums/notification_kind.dart';
import '../converters/enum_converter.dart';
import '../converters/utc_date_time_converter.dart';

/// Local notifications this device has scheduled, so they can be cancelled
/// when their message is sent or deleted early. Local-only: never synced, so
/// no sync columns.
class ScheduledNotifications extends Table {
  /// The notification id passed to the plugin.
  IntColumn get id => integer().autoIncrement()();

  TextColumn get kind => text().map(
    const EnumConverter<NotificationKind>(NotificationKind.holdEnded),
  )();

  /// The message (hold ended) or check record (check-in) it is about.
  TextColumn get targetId => text()();

  DateTimeColumn get fireAt => dateTime().map(const UtcDateTimeConverter())();
}
