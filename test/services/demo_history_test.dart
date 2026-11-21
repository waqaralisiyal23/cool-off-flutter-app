import 'package:cooloff/database/app_database.dart';
import 'package:cooloff/services/demo_history_service.dart';
import 'package:cooloff/stats/insights.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(() {
    appDatabase = AppDatabase(NativeDatabase.memory(), deviceId: 'device-1');
  });

  tearDown(() => appDatabase.close());

  test('needs a baseline first', () async {
    expect(await demoHistoryService.seed(), isFalse);
  });

  test(
    'two weeks of history fill every Insights card, today stays empty',
    () async {
      await appDatabase.baselinesDao.add(
        measuredAt: DateTime.now().toUtc(),
        pulseBpm: 72,
        angerLevel: 5,
        sampleCount: 40,
      );
      final now = DateTime.now();
      expect(await demoHistoryService.seed(now: now), isTrue);

      final checks = await appDatabase.checkRecordsDao.watchFinished().first;
      final reflections = await appDatabase.reflectionsDao.getAll();
      final insights = Insights.compute(
        checks: checks,
        reflections: reflections,
        nowLocal: now,
      );

      expect(insights.totalChecks, 23);
      expect(insights.heated, 7);
      expect(insights.heatedSends, 4);
      expect(insights.checkinsAnswered, 4);
      expect(insights.regretted, 3);
      expect(insights.cooldowns, 3);
      // A believable one-minute drop with a usual pulse of 72: about 6-10 bpm.
      expect(insights.averagePulseDrop, inInclusiveRange(5, 11));
      expect(insights.cooledOff, greaterThan(0));
      expect(insights.week.last.total, 0);
      // Patchy: one empty day in the last week besides today.
      expect(insights.week.where((d) => d.total > 0).length, 5);

      // 3 of 4 answers were regrets: Heated now comes a step sooner.
      final settings = await appDatabase.userSettingsDao.ensureCurrent();
      expect(settings.autoTuneOffset, -1);
    },
  );
}
