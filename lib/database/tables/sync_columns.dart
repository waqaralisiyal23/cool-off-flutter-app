import 'package:drift/drift.dart';

import '../converters/utc_date_time_converter.dart';

/// The columns every syncable table carries, so a future two-way sync
/// (docs/11-data-and-sync.md) needs no schema change.
///
/// Only `SyncableWrites` sets these. Feature code never writes them directly.
mixin SyncColumns on Table {
  /// A UUID v4 generated on the device: the same id locally and on the server.
  TextColumn get id => text()();

  DateTimeColumn get createdAt =>
      dateTime().map(const UtcDateTimeConverter())();

  /// Set on every local change. A future last-write-wins sync compares this.
  DateTimeColumn get updatedAt =>
      dateTime().map(const UtcDateTimeConverter())();

  /// Soft delete: rows are never removed, so a delete can sync. Normal queries
  /// exclude rows where this is set.
  DateTimeColumn get deletedAt =>
      dateTime().nullable().map(const UtcDateTimeConverter())();

  /// True when the row changed locally and has not been pushed yet.
  BoolColumn get isDirty => boolean().withDefault(const Constant(true))();

  /// The server's timestamp for the last version it acknowledged. Unused until sync
  /// exists.
  DateTimeColumn get serverUpdatedAt =>
      dateTime().nullable().map(const UtcDateTimeConverter())();

  /// The install that created the row, for debugging and display.
  TextColumn get originDeviceId => text()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
