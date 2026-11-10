import 'package:drift/drift.dart';

import '../../models/enums/notification_kind.dart';
import '../app_database.dart';
import '../tables/scheduled_notifications.dart';

part 'scheduled_notifications_dao.g.dart';

/// Which local notifications are scheduled, for cancelling them. Local-only.
@DriftAccessor(tables: [ScheduledNotifications])
class ScheduledNotificationsDao extends DatabaseAccessor<AppDatabase>
    with _$ScheduledNotificationsDaoMixin {
  ScheduledNotificationsDao(super.attachedDatabase);

  /// Records a notification and returns the id to schedule it under.
  Future<int> add({
    required NotificationKind kind,
    required String targetId,
    required DateTime fireAt,
  }) => into(scheduledNotifications).insert(
    ScheduledNotificationsCompanion.insert(
      kind: kind,
      targetId: targetId,
      fireAt: fireAt,
    ),
  );

  Future<List<ScheduledNotification>> forTarget(String targetId) => (select(
    scheduledNotifications,
  )..where((t) => t.targetId.equals(targetId))).get();

  Future<int> removeForTarget(String targetId) => (delete(
    scheduledNotifications,
  )..where((t) => t.targetId.equals(targetId))).go();
}
