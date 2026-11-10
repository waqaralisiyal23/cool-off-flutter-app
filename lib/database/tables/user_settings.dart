import 'package:drift/drift.dart';

import '../../models/data/user_settings_data.dart';
import '../../models/enums/sensitivity.dart';
import '../converters/enum_converter.dart';
import 'sync_columns.dart';

/// The user's settings: one row, created with these defaults on first use.
@UseRowClass(UserSettingsData, constructor: 'fromRow')
class UserSettings extends Table with SyncColumns {
  TextColumn get sensitivity => text()
      .map(const EnumConverter<Sensitivity>(Sensitivity.normal))
      .withDefault(const Constant('normal'))();

  IntColumn get autoTuneOffset => integer().withDefault(const Constant(0))();

  IntColumn get holdMinutes => integer().withDefault(const Constant(10))();

  /// 9:00 local.
  IntColumn get checkinMinutes => integer().withDefault(const Constant(540))();

  BoolColumn get checkinEnabled =>
      boolean().withDefault(const Constant(true))();

  BoolColumn get keepMessageText =>
      boolean().withDefault(const Constant(false))();

  BoolColumn get hapticsEnabled =>
      boolean().withDefault(const Constant(true))();
}
