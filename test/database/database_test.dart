import 'package:cooloff/database/app_database.dart';
import 'package:cooloff/models/enums/check_action.dart';
import 'package:cooloff/models/enums/check_kind.dart';
import 'package:cooloff/models/enums/heat_level.dart';
import 'package:cooloff/models/enums/message_status.dart';
import 'package:cooloff/models/enums/notification_kind.dart';
import 'package:cooloff/models/enums/reflection_answer.dart';
import 'package:cooloff/models/enums/sensitivity.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  var now = DateTime.utc(2026, 11, 9, 12);

  setUp(() {
    now = DateTime.utc(2026, 11, 9, 12);
    db = AppDatabase(
      NativeDatabase.memory(),
      deviceId: 'device-1',
      clock: () => now,
    );
  });

  tearDown(() => db.close());

  CheckRecordsCompanion check({
    HeatLevel? level = HeatLevel.heated,
    CheckKind kind = CheckKind.check,
    CheckAction? action,
  }) => CheckRecordsCompanion(
    checkedAt: Value(now),
    kind: Value(kind),
    heatLevel: Value(level),
    score: const Value(4),
    pulseBpm: const Value(88),
    sensitivity: const Value(Sensitivity.normal),
    action: Value(action),
  );

  group('SyncableWrites', () {
    test('insert stamps id, UTC times, dirty flag and device', () async {
      final id = await db.checkRecordsDao.add(check());
      final row = (await db.checkRecordsDao.getById(id))!;
      expect(row.id, hasLength(36));
      expect(row.createdAt, now);
      expect(row.updatedAt, now);
      expect(row.createdAt.isUtc, isTrue);
      expect(row.isDirty, isTrue);
      expect(row.originDeviceId, 'device-1');
      expect(row.deletedAt, isNull);
    });

    test('update moves updated_at and keeps created_at', () async {
      final id = await db.checkRecordsDao.add(check());
      now = now.add(const Duration(minutes: 5));
      await db.checkRecordsDao.setAction(id, CheckAction.sentAnyway);
      final row = (await db.checkRecordsDao.getById(id))!;
      expect(row.action, CheckAction.sentAnyway);
      expect(row.updatedAt, now);
      expect(row.createdAt, isNot(now));
    });

    test('soft delete hides a row, restore brings it back', () async {
      final id = await db.checkRecordsDao.add(check());
      expect(await db.softDeleteSyncable(db.checkRecords, id), isTrue);
      expect(await db.checkRecordsDao.getById(id), isNull);
      expect(await db.restoreSyncable(db.checkRecords, id), isTrue);
      expect(await db.checkRecordsDao.getById(id), isNotNull);
    });
  });

  test('enums are stored by snake_case wire name', () async {
    final id = await db.checkRecordsDao.add(
      check(action: CheckAction.sentAnyway),
    );
    final raw = await db
        .customSelect(
          'SELECT action FROM check_records WHERE id = ?',
          variables: [Variable(id)],
        )
        .getSingle();
    expect(raw.read<String>('action'), 'sent_anyway');
  });

  test('an unknown enum value reads as the fallback', () async {
    final id = await db.checkRecordsDao.add(check());
    await db.customStatement(
      "UPDATE check_records SET heat_level = 'scorching' WHERE id = ?",
      [id],
    );
    final row = (await db.checkRecordsDao.getById(id))!;
    expect(row.heatLevel, HeatLevel.calm);
  });

  test('baseline: the latest one is current', () async {
    await db.baselinesDao.add(
      measuredAt: now,
      pulseBpm: 70,
      angerLevel: 5,
      sampleCount: 20,
    );
    await db.baselinesDao.add(
      measuredAt: now.add(const Duration(days: 1)),
      pulseBpm: 66,
      angerLevel: 4,
      sampleCount: 22,
    );
    expect((await db.baselinesDao.getCurrent())!.pulseBpm, 66);
  });

  test(
    'watchFinished leaves out cancelled checks and baseline attempts',
    () async {
      await db.checkRecordsDao.add(check());
      await db.checkRecordsDao.add(
        check(level: null, action: CheckAction.cancelled),
      );
      await db.checkRecordsDao.add(check(kind: CheckKind.baselineAttempt));
      await db.checkRecordsDao.add(
        check(kind: CheckKind.recheck, level: HeatLevel.calm),
      );
      final finished = await db.checkRecordsDao.watchFinished().first;
      expect(finished, hasLength(2));
    },
  );

  test('watchHeatedSends returns only heated checks that were sent', () async {
    await db.checkRecordsDao.add(check(action: CheckAction.sentAnyway));
    await db.checkRecordsDao.add(check(action: CheckAction.held));
    await db.checkRecordsDao.add(
      check(level: HeatLevel.calm, action: CheckAction.sent),
    );
    expect(await db.checkRecordsDao.watchHeatedSends().first, hasLength(1));
  });

  group('messages', () {
    test('sending a held message clears its text unless kept', () async {
      final id = await db.messagesDao.addHeld(
        body: 'You never listen',
        recipientLabel: 'Sam',
        holdUntil: now.add(const Duration(minutes: 10)),
        firstCheckId: null,
      );
      expect(await db.messagesDao.watchHeld().first, hasLength(1));
      await db.messagesDao.markSent(id, sentAt: now, keepText: false);
      final row = (await db.messagesDao.getById(id))!;
      expect(row.status, MessageStatus.sent);
      expect(row.body, isNull);
      expect(await db.messagesDao.watchHeld().first, isEmpty);
    });

    test('keeping text keeps it', () async {
      final id = await db.messagesDao.addHeld(
        body: 'Hello',
        recipientLabel: null,
        holdUntil: now,
        firstCheckId: null,
      );
      await db.messagesDao.markDiscarded(id, keepText: true);
      expect((await db.messagesDao.getById(id))!.body, 'Hello');
    });

    test('clearFinishedBodies keeps held text only', () async {
      final held = await db.messagesDao.addHeld(
        body: 'held',
        recipientLabel: null,
        holdUntil: now,
        firstCheckId: null,
      );
      final sent = await db.messagesDao.addSent(
        body: 'sent',
        recipientLabel: null,
        sentAt: now,
        firstCheckId: null,
      );
      await db.messagesDao.clearFinishedBodies();
      expect((await db.messagesDao.getById(held))!.body, 'held');
      expect((await db.messagesDao.getById(sent))!.body, isNull);
    });
  });

  test('undoing a dismissed send removes the message and the action', () async {
    final checkId = await db.checkRecordsDao.add(check());
    final messageId = await db.messagesDao.addSent(
      body: null,
      recipientLabel: 'Sam',
      sentAt: now,
      firstCheckId: checkId,
    );
    await db.checkRecordsDao.setAction(
      checkId,
      CheckAction.sentAnyway,
      messageId: messageId,
    );
    expect(await db.checkRecordsDao.watchHeatedSends().first, hasLength(1));

    await db.softDeleteSyncable(db.messages, messageId);
    await db.checkRecordsDao.clearAction(checkId);

    final record = (await db.checkRecordsDao.getById(checkId))!;
    expect(record.action, isNull);
    expect(record.messageId, isNull);
    expect(await db.messagesDao.getById(messageId), isNull);
    expect(await db.checkRecordsDao.watchHeatedSends().first, isEmpty);
  });

  test('user settings: one row with the defaults', () async {
    final first = await db.userSettingsDao.ensureCurrent();
    final second = await db.userSettingsDao.ensureCurrent();
    expect(second.id, first.id);
    expect(first.sensitivity, Sensitivity.normal);
    expect(first.holdMinutes, 10);
    expect(first.checkinMinutes, 540);
    expect(first.checkinEnabled, isTrue);
    expect(first.keepMessageText, isFalse);
    await db.userSettingsDao.updateCurrent(
      const UserSettingsCompanion(sensitivity: Value(Sensitivity.high)),
    );
    expect(
      (await db.userSettingsDao.getCurrent())!.sensitivity,
      Sensitivity.high,
    );
  });

  test('reflections come newest first', () async {
    await db.reflectionsDao.add(
      checkRecordId: 'a',
      answer: ReflectionAnswer.glad,
      answeredAt: now,
    );
    await db.reflectionsDao.add(
      checkRecordId: 'b',
      answer: ReflectionAnswer.regret,
      answeredAt: now.add(const Duration(hours: 1)),
    );
    final all = await db.reflectionsDao.getAll();
    expect(all.map((r) => r.answer), [
      ReflectionAnswer.regret,
      ReflectionAnswer.glad,
    ]);
  });

  test('scheduled notifications are found and removed by target', () async {
    final id = await db.scheduledNotificationsDao.add(
      kind: NotificationKind.holdEnded,
      targetId: 'm1',
      fireAt: now,
    );
    expect(id, greaterThan(0));
    expect(await db.scheduledNotificationsDao.forTarget('m1'), hasLength(1));
    await db.scheduledNotificationsDao.removeForTarget('m1');
    expect(await db.scheduledNotificationsDao.forTarget('m1'), isEmpty);
  });

  test('wipeEverything empties every table', () async {
    await db.checkRecordsDao.add(check());
    await db.userSettingsDao.ensureCurrent();
    await db.wipeEverything();
    expect(await db.checkRecordsDao.watchFinished().first, isEmpty);
    expect(await db.userSettingsDao.getCurrent(), isNull);
  });
}
