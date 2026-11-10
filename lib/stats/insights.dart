import '../models/data/check_record_data.dart';
import '../models/data/reflection_data.dart';
import '../models/enums/check_kind.dart';
import '../models/enums/heat_level.dart';
import '../models/enums/reflection_answer.dart';

/// One day of the week chart: how many checks read each level.
class DayHeat {
  const DayHeat({
    required this.day,
    required this.calm,
    required this.warm,
    required this.heated,
  });

  /// Local midnight.
  final DateTime day;
  final int calm;
  final int warm;
  final int heated;

  int get total => calm + warm + heated;
}

/// The Insights numbers, all from local history (docs/02-features.md §9).
class Insights {
  const Insights({
    required this.totalChecks,
    required this.calm,
    required this.warm,
    required this.heated,
    required this.cooledOff,
    required this.heatedSends,
    required this.checkinsAnswered,
    required this.regretted,
    required this.cooldowns,
    required this.averagePulseDrop,
    required this.week,
  });

  /// First checks only (re-checks after a cool-down are not counted twice).
  final int totalChecks;
  final int calm;
  final int warm;
  final int heated;

  /// Warm or Heated messages the user held, cooled down, edited or deleted
  /// instead of sending as they were.
  final int cooledOff;

  /// Messages sent while the result was Heated.
  final int heatedSends;
  final int checkinsAnswered;

  /// Check-ins answered "I regret it".
  final int regretted;

  /// Finished cool-downs (re-checks).
  final int cooldowns;

  /// Mean pulse drop from a check to its re-check, in bpm; null without a
  /// pair that has both pulses.
  final double? averagePulseDrop;

  /// The last 7 days, oldest first.
  final List<DayHeat> week;

  bool get isEmpty => totalChecks == 0;

  static Insights compute({
    required List<CheckRecordData> checks,
    required List<ReflectionData> reflections,
    required DateTime nowLocal,
  }) {
    final firsts = checks
        .where((c) => c.kind == CheckKind.check && c.heatLevel != null)
        .toList();
    int count(HeatLevel level) =>
        firsts.where((c) => c.heatLevel == level).length;

    final cooledOff = firsts
        .where(
          (c) =>
              c.heatLevel != HeatLevel.calm && (c.action?.isCooledOff ?? false),
        )
        .length;

    final heatedSendIds = {
      for (final c in checks)
        if (c.heatLevel == HeatLevel.heated && (c.action?.isSend ?? false))
          c.id,
    };
    final answered = reflections
        .where((r) => heatedSendIds.contains(r.checkRecordId))
        .toList();

    final byId = {for (final c in checks) c.id: c};
    final drops = <double>[];
    var cooldowns = 0;
    for (final recheck in checks.where((c) => c.kind == CheckKind.recheck)) {
      cooldowns++;
      final before = byId[recheck.previousCheckId]?.pulseBpm;
      final after = recheck.pulseBpm;
      if (before != null && after != null) {
        drops.add(before - after);
      }
    }

    final today = DateTime(nowLocal.year, nowLocal.month, nowLocal.day);
    final week = <DayHeat>[
      for (var i = 6; i >= 0; i--)
        _day(DateTime(today.year, today.month, today.day - i), firsts),
    ];

    return Insights(
      totalChecks: firsts.length,
      calm: count(HeatLevel.calm),
      warm: count(HeatLevel.warm),
      heated: count(HeatLevel.heated),
      cooledOff: cooledOff,
      heatedSends: heatedSendIds.length,
      checkinsAnswered: answered.length,
      regretted: answered
          .where((r) => r.answer == ReflectionAnswer.regret)
          .length,
      cooldowns: cooldowns,
      averagePulseDrop: drops.isEmpty
          ? null
          : drops.reduce((a, b) => a + b) / drops.length,
      week: week,
    );
  }

  static DayHeat _day(DateTime day, List<CheckRecordData> checks) {
    final next = DateTime(day.year, day.month, day.day + 1);
    final onDay = checks.where((c) {
      final local = c.checkedAt.toLocal();
      return !local.isBefore(day) && local.isBefore(next);
    });
    int count(HeatLevel level) =>
        onDay.where((c) => c.heatLevel == level).length;
    return DayHeat(
      day: day,
      calm: count(HeatLevel.calm),
      warm: count(HeatLevel.warm),
      heated: count(HeatLevel.heated),
    );
  }
}
