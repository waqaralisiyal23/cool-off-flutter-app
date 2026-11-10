import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

/// Writes to syncable tables (those with `SyncColumns`), keeping the sync
/// columns right on every change so a future sync (docs/11-data-and-sync.md) needs no
/// schema change.
///
/// This is the only code that sets the sync columns. Values a caller passes
/// for them are ignored:
///
/// * an insert gets a new UUID v4, `created_at` = `updated_at` = now (UTC),
///   `is_dirty`, and this install's `origin_device_id`;
/// * every update and soft delete moves `updated_at` to now and sets
///   `is_dirty`;
/// * nothing is ever hard-deleted.
///
/// Updates and soft deletes only touch rows that are not already deleted;
/// use [restoreSyncable] to bring a deleted row back (an Undo).
mixin SyncableWrites on GeneratedDatabase {
  static const _uuid = Uuid();

  static const _id = 'id';
  static const _createdAt = 'created_at';
  static const _updatedAt = 'updated_at';
  static const _deletedAt = 'deleted_at';
  static const _isDirty = 'is_dirty';
  static const _serverUpdatedAt = 'server_updated_at';
  static const _originDeviceId = 'origin_device_id';

  static const _syncColumns = {
    _id,
    _createdAt,
    _updatedAt,
    _deletedAt,
    _isDirty,
    _serverUpdatedAt,
    _originDeviceId,
  };

  /// This install's stable id, stamped on the rows it creates.
  String get deviceId;

  /// The current time in UTC. Injectable so tests control it.
  DateTime utcNow();

  /// Inserts [row] into [table] and returns its new id.
  Future<String> insertSyncable<T extends Table, D>(
    TableInfo<T, D> table,
    Insertable<D> row,
  ) async {
    final id = _uuid.v4();
    await into(table).insert(_stampedForInsert(table, row, id));
    return id;
  }

  /// Writes the present values of [changes] to the row [id]. False when there
  /// is no such row, or it is deleted.
  Future<bool> updateSyncable<T extends Table, D>(
    TableInfo<T, D> table,
    String id,
    Insertable<D> changes,
  ) => _writeActive(table, id, {
    ..._withoutSyncColumns(changes),
    _updatedAt: Variable<DateTime>(utcNow()),
    _isDirty: const Variable<bool>(true),
  });

  /// Marks the row [id] deleted. False when there is no such row, or it was
  /// already deleted.
  Future<bool> softDeleteSyncable<T extends Table, D>(
    TableInfo<T, D> table,
    String id,
  ) {
    final now = utcNow();
    return _writeActive(table, id, {
      _deletedAt: Variable<DateTime>(now),
      _updatedAt: Variable<DateTime>(now),
      _isDirty: const Variable<bool>(true),
    });
  }

  /// Brings back the soft-deleted row [id]. False when there is no such row,
  /// or it is not deleted.
  Future<bool> restoreSyncable<T extends Table, D>(
    TableInfo<T, D> table,
    String id,
  ) async {
    _checkSyncable(table);
    final count =
        await (update(table)..where(
              (_) =>
                  _column<String>(table, _id).equals(id) &
                  _column<DateTime>(table, _deletedAt).isNotNull(),
            ))
            .write(
              RawValuesInsertable<D>({
                _deletedAt: const Variable<DateTime>(null),
                _updatedAt: Variable<DateTime>(utcNow()),
                _isDirty: const Variable<bool>(true),
              }),
            );
    return count > 0;
  }

  /// True for rows of [table] that are not soft-deleted. Every normal query
  /// filters with this.
  Expression<bool> isActive<T extends Table, D>(TableInfo<T, D> table) {
    _checkSyncable(table);
    return _column<DateTime>(table, _deletedAt).isNull();
  }

  Future<bool> _writeActive<T extends Table, D>(
    TableInfo<T, D> table,
    String id,
    Map<String, Expression<Object>> values,
  ) async {
    _checkSyncable(table);
    final count =
        await (update(table)..where(
              (_) =>
                  _column<String>(table, _id).equals(id) &
                  _column<DateTime>(table, _deletedAt).isNull(),
            ))
            .write(RawValuesInsertable<D>(values));
    return count > 0;
  }

  RawValuesInsertable<D> _stampedForInsert<T extends Table, D>(
    TableInfo<T, D> table,
    Insertable<D> row,
    String id,
  ) {
    _checkSyncable(table);
    final now = utcNow();
    return RawValuesInsertable<D>({
      ..._withoutSyncColumns(row),
      _id: Variable<String>(id),
      _createdAt: Variable<DateTime>(now),
      _updatedAt: Variable<DateTime>(now),
      _isDirty: const Variable<bool>(true),
      _originDeviceId: Variable<String>(deviceId),
    });
  }

  Map<String, Expression<Object>> _withoutSyncColumns<D>(Insertable<D> row) =>
      Map.of(row.toColumns(true))
        ..removeWhere((name, _) => _syncColumns.contains(name));

  GeneratedColumn<C> _column<C extends Object>(
    TableInfo<Table, dynamic> table,
    String name,
  ) => table.columnsByName[name]! as GeneratedColumn<C>;

  void _checkSyncable(TableInfo<Table, dynamic> table) {
    final missing = _syncColumns.difference(table.columnsByName.keys.toSet());
    if (missing.isNotEmpty) {
      throw ArgumentError.value(
        table.actualTableName,
        'table',
        'Not a syncable table: missing $missing',
      );
    }
  }
}
