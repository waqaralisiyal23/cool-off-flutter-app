import 'package:drift/drift.dart';

import '../../models/data/check_record_data.dart';
import '../../models/enums/check_action.dart';
import '../../models/enums/check_kind.dart';
import '../../models/enums/heat_level.dart';
import '../app_database.dart';
import '../tables/check_records.dart';

part 'check_records_dao.g.dart';

@DriftAccessor(tables: [CheckRecords])
class CheckRecordsDao extends DatabaseAccessor<AppDatabase>
    with _$CheckRecordsDaoMixin {
  CheckRecordsDao(super.attachedDatabase);

  /// Saves a check and returns its id. Sync columns in [row] are ignored.
  Future<String> add(CheckRecordsCompanion row) =>
      attachedDatabase.insertSyncable(checkRecords, row);

  Future<CheckRecordData?> getById(String id) =>
      (select(checkRecords)
            ..where((t) => t.id.equals(id) & attachedDatabase.isActive(t)))
          .getSingleOrNull();

  /// Records what the user did with the result.
  Future<bool> setAction(String id, CheckAction action, {String? messageId}) =>
      attachedDatabase.updateSyncable(
        checkRecords,
        id,
        CheckRecordsCompanion(
          action: Value(action),
          messageId: messageId == null
              ? const Value.absent()
              : Value(messageId),
        ),
      );

  /// Back to "no choice yet" (a send whose share sheet was dismissed).
  Future<bool> clearAction(String id) => attachedDatabase.updateSyncable(
    checkRecords,
    id,
    const CheckRecordsCompanion(action: Value(null), messageId: Value(null)),
  );

  /// Every finished check and re-check, newest first (Insights).
  Stream<List<CheckRecordData>> watchFinished() =>
      (select(checkRecords)
            ..where(
              (t) =>
                  attachedDatabase.isActive(t) &
                  t.heatLevel.isNotNull() &
                  t.kind.isIn([CheckKind.check.name, CheckKind.recheck.name]),
            )
            ..orderBy([(t) => OrderingTerm.desc(t.checkedAt)]))
          .watch();

  /// Messages sent while the result was Heated, newest first: the ones the
  /// next-morning check-in asks about.
  Stream<List<CheckRecordData>> watchHeatedSends() =>
      (select(checkRecords)
            ..where(
              (t) =>
                  attachedDatabase.isActive(t) &
                  t.heatLevel.equalsValue(HeatLevel.heated) &
                  t.action.isIn(['sent', 'sent_anyway']),
            )
            ..orderBy([(t) => OrderingTerm.desc(t.checkedAt)]))
          .watch();
}
