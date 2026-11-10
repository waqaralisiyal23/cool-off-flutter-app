import 'package:drift/drift.dart';

import '../../models/data/user_settings_data.dart';
import '../app_database.dart';
import '../tables/user_settings.dart';

part 'user_settings_dao.g.dart';

/// The one `user_settings` row.
@DriftAccessor(tables: [UserSettings])
class UserSettingsDao extends DatabaseAccessor<AppDatabase>
    with _$UserSettingsDaoMixin {
  UserSettingsDao(super.attachedDatabase);

  SimpleSelectStatement<$UserSettingsTable, UserSettingsData> _current() =>
      select(userSettings)
        ..where((_) => attachedDatabase.isActive(userSettings))
        ..orderBy([(t) => OrderingTerm.asc(t.createdAt)])
        ..limit(1);

  /// The settings, or null before they were first created.
  Stream<UserSettingsData?> watchCurrent() => _current().watchSingleOrNull();

  Future<UserSettingsData?> getCurrent() => _current().getSingleOrNull();

  /// The settings, created with the defaults when there are none yet. Never
  /// creates a second row.
  Future<UserSettingsData> ensureCurrent() {
    return transaction(() async {
      final existing = await getCurrent();
      if (existing != null) {
        return existing;
      }
      await attachedDatabase.insertSyncable(
        userSettings,
        const UserSettingsCompanion(),
      );
      return (await getCurrent())!;
    });
  }

  /// Writes [changes] to the settings, creating them first if needed.
  Future<void> updateCurrent(UserSettingsCompanion changes) {
    return transaction(() async {
      final current = await ensureCurrent();
      await attachedDatabase.updateSyncable(userSettings, current.id, changes);
    });
  }
}
