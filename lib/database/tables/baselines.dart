import 'package:drift/drift.dart';

import '../../models/data/baseline_data.dart';
import '../converters/utc_date_time_converter.dart';
import 'sync_columns.dart';

/// The user's usual pulse and resting anger level. The latest active row is
/// the current baseline; redoing it adds a row, so history is kept.
@UseRowClass(BaselineData, constructor: 'fromRow')
class Baselines extends Table with SyncColumns {
  DateTimeColumn get measuredAt =>
      dateTime().map(const UtcDateTimeConverter())();

  RealColumn get pulseBpm => real()();

  RealColumn get angerLevel => real()();

  IntColumn get sampleCount => integer()();
}
