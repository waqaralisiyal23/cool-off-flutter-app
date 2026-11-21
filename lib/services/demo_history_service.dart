import 'dart:math';

import 'package:drift/drift.dart';

import '../database/app_database.dart';
import '../engine/auto_tune.dart';
import '../models/enums/check_action.dart';
import '../models/enums/check_kind.dart';
import '../models/enums/heat_level.dart';
import '../models/enums/reflection_answer.dart';
import 'settings_service.dart';

/// QA builds only (Settings → Demo): fills the database with two weeks of
/// believable history, so Insights, the week chart and the auto-tune card have
/// something to show in the demo video. Today is left empty for live checks.
///
/// Everything it writes is ordinary local data: "Delete all my data" removes
/// it. No message text is stored (as with "Keep message text" off).
class _DemoHistoryService {
  /// One past check: how many days ago, the hour, the level, what the user
  /// did, and for heated sends the next-morning answer.
  ///
  /// Patchy like real use: busy days, quiet days, a day with none.
  static const List<_Past> _plan = [
    _Past(13, 10, HeatLevel.calm, CheckAction.sent),
    _Past(13, 19, HeatLevel.warm, CheckAction.edited),
    _Past(12, 9, HeatLevel.calm, CheckAction.sent),
    _Past(
      12,
      22,
      HeatLevel.heated,
      CheckAction.sentAnyway,
      answer: ReflectionAnswer.regret,
    ),
    _Past(11, 14, HeatLevel.calm, CheckAction.sent),
    _Past(10, 11, HeatLevel.heated, CheckAction.cooledDown),
    _Past(10, 18, HeatLevel.calm, CheckAction.sent),
    _Past(10, 20, HeatLevel.calm, CheckAction.sent),
    _Past(
      9,
      21,
      HeatLevel.heated,
      CheckAction.sentAnyway,
      answer: ReflectionAnswer.regret,
    ),
    _Past(7, 10, HeatLevel.calm, CheckAction.sent),
    _Past(7, 13, HeatLevel.warm, CheckAction.sent),
    _Past(6, 9, HeatLevel.calm, CheckAction.sent),
    _Past(
      6,
      20,
      HeatLevel.heated,
      CheckAction.cooledDown,
      recheck: HeatLevel.warm,
    ),
    _Past(6, 22, HeatLevel.warm, CheckAction.sent),
    _Past(5, 15, HeatLevel.warm, CheckAction.discarded),
    _Past(
      5,
      23,
      HeatLevel.heated,
      CheckAction.sentAnyway,
      answer: ReflectionAnswer.glad,
    ),
    _Past(3, 10, HeatLevel.calm, CheckAction.sent),
    _Past(3, 12, HeatLevel.calm, CheckAction.sent),
    _Past(3, 19, HeatLevel.heated, CheckAction.cooledDown),
    _Past(3, 20, HeatLevel.calm, CheckAction.sent),
    _Past(2, 16, HeatLevel.warm, CheckAction.sent),
    _Past(
      2,
      22,
      HeatLevel.heated,
      CheckAction.sentAnyway,
      answer: ReflectionAnswer.regret,
    ),
    _Past(1, 11, HeatLevel.calm, CheckAction.sent),
  ];

  static const List<String?> _recipients = [
    'Sam',
    'Team chat',
    'Landlord',
    null,
    'Client',
    'Mom',
    null,
  ];

  /// Adds the history. Needs a baseline (finish onboarding first); returns
  /// false without one.
  Future<bool> seed({DateTime? now}) async {
    final baseline = await appDatabase.baselinesDao.getCurrent();
    if (baseline == null) {
      return false;
    }
    final settings = await settingsService.ensure();
    final usual = baseline.pulseBpm;
    final random = Random(7);
    final today = now ?? DateTime.now();
    double jitter(double spread) => (random.nextDouble() * 2 - 1) * spread;

    final answers = <ReflectionAnswer>[];
    await appDatabase.transaction(() async {
      for (final (index, past) in _plan.indexed) {
        final local = DateTime(
          today.year,
          today.month,
          today.day - past.daysAgo,
          past.hour,
          random.nextInt(50) + 5,
        );
        final (deltaPct, anger, textHeat, score) = past.level.when(
          calm: () => (2 + jitter(2), 8 + jitter(5), 0, random.nextInt(2)),
          warm: () =>
              (10 + jitter(3), 32 + jitter(8), 1, 2 + random.nextInt(2)),
          heated: () =>
              (23 + jitter(8), 62 + jitter(12), 2, 4 + random.nextInt(3)),
        );
        final pulse = usual * (1 + deltaPct / 100);
        final recipient = _recipients[index % _recipients.length];

        String? messageId;
        if (past.action.isSend) {
          messageId = await appDatabase.messagesDao.addSent(
            body: null,
            recipientLabel: recipient,
            sentAt: local.toUtc(),
            firstCheckId: null,
          );
        }
        final checkId = await appDatabase.checkRecordsDao.add(
          CheckRecordsCompanion(
            checkedAt: Value(local.toUtc()),
            kind: const Value(CheckKind.check),
            heatLevel: Value(past.level),
            score: Value(score),
            pulseBpm: Value(pulse),
            baselineId: Value(baseline.id),
            pulseDeltaPct: Value(deltaPct),
            angerLevel: Value(anger),
            textHeat: Value(textHeat),
            sensitivity: Value(settings.sensitivity),
            action: Value(past.action),
            messageId: Value(messageId),
          ),
        );

        // A cool-down: a minute later the pulse is down about 8-14 bpm (not
        // all the way to usual) and the face has relaxed.
        if (past.action == CheckAction.cooledDown) {
          final stillWarm = past.recheck == HeatLevel.warm;
          final afterDelta = stillWarm ? 12 + jitter(1.5) : 9 + jitter(2);
          await appDatabase.checkRecordsDao.add(
            CheckRecordsCompanion(
              checkedAt: Value(local.add(const Duration(minutes: 2)).toUtc()),
              kind: const Value(CheckKind.recheck),
              heatLevel: Value(past.recheck),
              score: Value(stillWarm ? 2 : 1),
              pulseBpm: Value(usual * (1 + afterDelta / 100)),
              baselineId: Value(baseline.id),
              pulseDeltaPct: Value(afterDelta),
              angerLevel: Value(stillWarm ? 30 + jitter(5) : 14 + jitter(5)),
              textHeat: Value(textHeat),
              sensitivity: Value(settings.sensitivity),
              action: Value(
                stillWarm ? CheckAction.discarded : CheckAction.edited,
              ),
              previousCheckId: Value(checkId),
            ),
          );
        }

        final answer = past.answer;
        if (answer != null) {
          final nextMorning = DateTime(
            local.year,
            local.month,
            local.day + 1,
            9,
            12,
          );
          await appDatabase.reflectionsDao.add(
            checkRecordId: checkId,
            answer: answer,
            answeredAt: nextMorning.toUtc(),
          );
          answers.insert(0, answer);
        }
      }
    });

    // As if the check-ins had been answered in the app.
    final offset = AutoTune.offsetFor(answers);
    if (settings.autoTuneOffset != offset) {
      await settingsService.update(autoTuneOffset: offset);
    }
    return true;
  }
}

class _Past {
  const _Past(
    this.daysAgo,
    this.hour,
    this.level,
    this.action, {
    this.answer,
    this.recheck = HeatLevel.calm,
  });

  final int daysAgo;
  final int hour;
  final HeatLevel level;
  final CheckAction action;

  /// The next-morning answer, for heated sends.
  final ReflectionAnswer? answer;

  /// How the re-check after a cool-down read.
  final HeatLevel recheck;
}

final demoHistoryService = _DemoHistoryService();
