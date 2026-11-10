import 'package:drift/drift.dart';

import '../../models/data/check_record_data.dart';
import '../../models/enums/check_action.dart';
import '../../models/enums/check_kind.dart';
import '../../models/enums/heat_level.dart';
import '../../models/enums/sensitivity.dart';
import '../converters/enum_converter.dart';
import '../converters/utc_date_time_converter.dart';
import 'sync_columns.dart';

/// One check, re-check or failed baseline attempt: numbers and the result,
/// never message text. Insights are computed from these rows.
///
/// References ([baselineId], [messageId], [previousCheckId]) are plain
/// UUIDs without foreign keys, so a future sync can deliver rows in any
/// order (docs/11-data-and-sync.md).
@UseRowClass(CheckRecordData, constructor: 'fromRow')
class CheckRecords extends Table with SyncColumns {
  DateTimeColumn get checkedAt =>
      dateTime().map(const UtcDateTimeConverter())();

  TextColumn get kind =>
      text().map(const EnumConverter<CheckKind>(CheckKind.check))();

  TextColumn get heatLevel =>
      text().nullable().map(const EnumConverter<HeatLevel>(HeatLevel.calm))();

  IntColumn get score => integer().nullable()();

  RealColumn get pulseBpm => real().nullable()();

  TextColumn get baselineId => text().nullable()();

  RealColumn get pulseDeltaPct => real().nullable()();

  RealColumn get angerLevel => real().nullable()();

  IntColumn get textHeat => integer().nullable()();

  TextColumn get sensitivity =>
      text().map(const EnumConverter<Sensitivity>(Sensitivity.normal))();

  TextColumn get action => text().nullable().map(
    const EnumConverter<CheckAction>(CheckAction.cancelled),
  )();

  TextColumn get messageId => text().nullable()();

  TextColumn get previousCheckId => text().nullable()();
}
