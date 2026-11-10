import 'package:drift/drift.dart';

import '../database/app_database.dart';
import '../models/data/baseline_data.dart';
import '../models/data/check_record_data.dart';
import '../models/data/message_data.dart';
import '../models/data/reflection_data.dart';
import '../models/enums/check_action.dart';
import '../models/enums/check_kind.dart';
import '../models/enums/heat_level.dart';
import '../models/enums/reflection_answer.dart';
import '../models/enums/sensitivity.dart';
import 'error_reporting_service.dart';

/// Baselines, checks, messages and check-in answers: the user's data, in the
/// on-device database (docs/11-data-and-sync.md). Blocs never query Drift
/// directly.
///
/// Failed writes are reported to Crashlytics (what failed, never the
/// content) and rethrown for the bloc to show.
class _RecordsService {
  // ─── Baselines ─────────────────────────────────────────────────────────
  Stream<BaselineData?> watchBaseline() =>
      appDatabase.baselinesDao.watchCurrent();

  Future<BaselineData?> getBaseline() => appDatabase.baselinesDao.getCurrent();

  Future<String> saveBaseline({
    required double pulseBpm,
    required double angerLevel,
    required int sampleCount,
  }) => _guard(
    'Saving a baseline failed',
    () => appDatabase.baselinesDao.add(
      measuredAt: DateTime.now().toUtc(),
      pulseBpm: pulseBpm,
      angerLevel: angerLevel,
      sampleCount: sampleCount,
    ),
  );

  // ─── Checks ────────────────────────────────────────────────────────────
  Future<String> saveCheck({
    required CheckKind kind,
    required HeatLevel? heatLevel,
    required int? score,
    required double? pulseBpm,
    required String? baselineId,
    required double? pulseDeltaPct,
    required double? angerLevel,
    required int? textHeat,
    required Sensitivity sensitivity,
    CheckAction? action,
    String? messageId,
    String? previousCheckId,
  }) => _guard(
    'Saving a check failed',
    () => appDatabase.checkRecordsDao.add(
      CheckRecordsCompanion(
        checkedAt: Value(DateTime.now().toUtc()),
        kind: Value(kind),
        heatLevel: Value(heatLevel),
        score: Value(score),
        pulseBpm: Value(pulseBpm),
        baselineId: Value(baselineId),
        pulseDeltaPct: Value(pulseDeltaPct),
        angerLevel: Value(angerLevel),
        textHeat: Value(textHeat),
        sensitivity: Value(sensitivity),
        action: Value(action),
        messageId: Value(messageId),
        previousCheckId: Value(previousCheckId),
      ),
    ),
  );

  Future<void> setCheckAction(
    String checkId,
    CheckAction action, {
    String? messageId,
  }) => _guard(
    'Saving a check action failed',
    () => appDatabase.checkRecordsDao.setAction(
      checkId,
      action,
      messageId: messageId,
    ),
  );

  Future<CheckRecordData?> getCheck(String id) =>
      appDatabase.checkRecordsDao.getById(id);

  Stream<List<CheckRecordData>> watchFinishedChecks() =>
      appDatabase.checkRecordsDao.watchFinished();

  Stream<List<CheckRecordData>> watchHeatedSends() =>
      appDatabase.checkRecordsDao.watchHeatedSends();

  // ─── Messages ──────────────────────────────────────────────────────────
  Stream<List<MessageData>> watchHeld() => appDatabase.messagesDao.watchHeld();

  Future<MessageData?> getMessage(String id) =>
      appDatabase.messagesDao.getById(id);

  Future<String> holdMessage({
    required String body,
    required String? recipientLabel,
    required DateTime holdUntil,
    required String? checkId,
  }) => _guard(
    'Holding a message failed',
    () => appDatabase.messagesDao.addHeld(
      body: body,
      recipientLabel: recipientLabel,
      holdUntil: holdUntil.toUtc(),
      firstCheckId: checkId,
    ),
  );

  /// Records a message sent straight from a result. Its text is kept only
  /// when [keepText].
  Future<String> recordSent({
    required String body,
    required String? recipientLabel,
    required String? checkId,
    required bool keepText,
  }) => _guard(
    'Saving a sent message failed',
    () => appDatabase.messagesDao.addSent(
      body: keepText ? body : null,
      recipientLabel: recipientLabel,
      sentAt: DateTime.now().toUtc(),
      firstCheckId: checkId,
    ),
  );

  /// The share sheet was dismissed after [recordSent]: the message row is
  /// deleted and the check goes back to having no action.
  Future<void> undoSent({required String checkId, required String messageId}) =>
      _guard('Undoing a send failed', () async {
        await appDatabase.softDeleteSyncable(appDatabase.messages, messageId);
        await appDatabase.checkRecordsDao.clearAction(checkId);
      });

  Future<void> markHeldSent(String messageId, {required bool keepText}) =>
      _guard(
        'Sending a held message failed',
        () => appDatabase.messagesDao.markSent(
          messageId,
          sentAt: DateTime.now().toUtc(),
          keepText: keepText,
        ),
      );

  Future<void> discardHeld(String messageId, {required bool keepText}) =>
      _guard(
        'Deleting a held message failed',
        () => appDatabase.messagesDao.markDiscarded(
          messageId,
          keepText: keepText,
        ),
      );

  Future<void> clearFinishedMessageText() => _guard(
    'Clearing message text failed',
    appDatabase.messagesDao.clearFinishedBodies,
  );

  // ─── Check-ins ─────────────────────────────────────────────────────────
  Stream<List<ReflectionData>> watchReflections() =>
      appDatabase.reflectionsDao.watchAll();

  Future<List<ReflectionData>> getReflections() =>
      appDatabase.reflectionsDao.getAll();

  Future<void> saveReflection({
    required String checkRecordId,
    required ReflectionAnswer answer,
  }) => _guard(
    'Saving a check-in answer failed',
    () => appDatabase.reflectionsDao.add(
      checkRecordId: checkRecordId,
      answer: answer,
      answeredAt: DateTime.now().toUtc(),
    ),
  );

  // ─── Everything ────────────────────────────────────────────────────────
  /// "Delete all my data".
  Future<void> wipeEverything() =>
      _guard('Deleting all data failed', appDatabase.wipeEverything);

  Future<T> _guard<T>(String reason, Future<T> Function() write) async {
    try {
      return await write();
    } on Object catch (e, stackTrace) {
      await errorReportingService.recordError(e, stackTrace, reason: reason);
      rethrow;
    }
  }
}

final recordsService = _RecordsService();
