import 'package:drift/drift.dart';

/// Stores every timestamp in UTC and reads it back in UTC.
///
/// Timestamps are stored as ISO-8601 text (`store_date_time_values_as_text`
/// in `build.yaml`), and SQLite compares that text as text. A local time
/// would be written with its UTC offset and sort out of order against UTC
/// values, so this converter makes UTC the only form that reaches the
/// database. Convert to local time only for display.
///
/// When filtering on a timestamp column, pass `.toUtc()` values: drift's
/// comparison operators take the SQL value as given.
class UtcDateTimeConverter extends TypeConverter<DateTime, DateTime> {
  const UtcDateTimeConverter();

  @override
  DateTime fromSql(DateTime fromDb) => fromDb.toUtc();

  @override
  DateTime toSql(DateTime value) => value.toUtc();
}
