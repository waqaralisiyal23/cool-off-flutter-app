import 'package:drift/drift.dart';

import '../database/app_database.dart';
import '../models/data/user_settings_data.dart';
import '../models/enums/sensitivity.dart';
import 'error_reporting_service.dart';

/// The user's settings row (docs/11-data-and-sync.md).
class _SettingsService {
  Stream<UserSettingsData?> watch() =>
      appDatabase.userSettingsDao.watchCurrent();

  Future<UserSettingsData> ensure() =>
      appDatabase.userSettingsDao.ensureCurrent();

  Future<void> update({
    Sensitivity? sensitivity,
    int? autoTuneOffset,
    int? holdMinutes,
    int? checkinMinutes,
    bool? checkinEnabled,
    bool? keepMessageText,
    bool? hapticsEnabled,
  }) async {
    Value<T> v<T>(T? value) =>
        value == null ? const Value.absent() : Value(value);
    try {
      await appDatabase.userSettingsDao.updateCurrent(
        UserSettingsCompanion(
          sensitivity: v(sensitivity),
          autoTuneOffset: v(autoTuneOffset),
          holdMinutes: v(holdMinutes),
          checkinMinutes: v(checkinMinutes),
          checkinEnabled: v(checkinEnabled),
          keepMessageText: v(keepMessageText),
          hapticsEnabled: v(hapticsEnabled),
        ),
      );
    } on Object catch (e, stackTrace) {
      await errorReportingService.recordError(
        e,
        stackTrace,
        reason: 'Saving settings failed',
      );
      rethrow;
    }
  }
}

final settingsService = _SettingsService();
