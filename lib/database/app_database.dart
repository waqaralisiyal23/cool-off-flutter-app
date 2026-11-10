import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:path_provider/path_provider.dart';

import '../models/data/baseline_data.dart';
import '../models/data/check_record_data.dart';
import '../models/data/message_data.dart';
import '../models/data/reflection_data.dart';
import '../models/data/user_settings_data.dart';
import '../models/enums/check_action.dart';
import '../models/enums/check_kind.dart';
import '../models/enums/heat_level.dart';
import '../models/enums/message_status.dart';
import '../models/enums/notification_kind.dart';
import '../models/enums/reflection_answer.dart';
import '../models/enums/sensitivity.dart';
import 'converters/enum_converter.dart';
import 'converters/utc_date_time_converter.dart';
import 'daos/baselines_dao.dart';
import 'daos/check_records_dao.dart';
import 'daos/messages_dao.dart';
import 'daos/reflections_dao.dart';
import 'daos/scheduled_notifications_dao.dart';
import 'daos/user_settings_dao.dart';
import 'syncable_writes.dart';
import 'tables/baselines.dart';
import 'tables/check_records.dart';
import 'tables/messages.dart';
import 'tables/reflections.dart';
import 'tables/scheduled_notifications.dart';
import 'tables/user_settings.dart';

part 'app_database.g.dart';

/// The app's database, opened in `main()` once this install's device id is
/// known. Not final, so a test can swap in an in-memory database.
late AppDatabase appDatabase;

/// The on-device database: the source of truth, offline-first and ready for
/// a future sync (docs/11-data-and-sync.md).
///
/// Syncable tables carry `SyncColumns` and are written only through
/// [SyncableWrites]. `scheduled_notifications` is local-only.
///
/// **Changing the schema:** until the first public release, stay at
/// [schemaVersion] 1: edit the tables in place, `derry gen`, and reinstall on
/// test devices. After release: bump it and write a migration step.
@DriftDatabase(
  tables: [
    Baselines,
    CheckRecords,
    Messages,
    Reflections,
    UserSettings,
    ScheduledNotifications,
  ],
  daos: [
    BaselinesDao,
    CheckRecordsDao,
    MessagesDao,
    ReflectionsDao,
    UserSettingsDao,
    ScheduledNotificationsDao,
  ],
)
class AppDatabase extends _$AppDatabase with SyncableWrites {
  /// This install's id. Replaced after "Delete all my data", which makes
  /// the phone a new device.
  @override
  String deviceId;

  final DateTime Function() _clock;

  AppDatabase(
    super.executor, {
    required this.deviceId,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  /// Opens `cooloff.sqlite` in the app support directory, which is private
  /// to the app and not shown in the Files app.
  ///
  /// Shared across isolates, so a notification action handled in the
  /// background writes to the same database.
  factory AppDatabase.open({required String deviceId}) => AppDatabase(
    driftDatabase(
      name: 'cooloff',
      native: const DriftNativeOptions(
        databaseDirectory: getApplicationSupportDirectory,
        shareAcrossIsolates: true,
      ),
    ),
    deviceId: deviceId,
  );

  @override
  DateTime utcNow() => _clock().toUtc();

  @override
  int get schemaVersion => 1;

  /// "Delete all my data": removes every row from every table, then
  /// rewrites the file so nothing deleted stays on disk. The one exception
  /// to soft delete (docs/11-data-and-sync.md).
  Future<void> wipeEverything() async {
    await transaction(() async {
      for (final table in allTables) {
        await delete(table).go();
      }
    });
    await customStatement('VACUUM');
  }
}
