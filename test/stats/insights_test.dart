import 'package:cooloff/models/data/check_record_data.dart';
import 'package:cooloff/models/data/reflection_data.dart';
import 'package:cooloff/models/enums/check_action.dart';
import 'package:cooloff/models/enums/check_kind.dart';
import 'package:cooloff/models/enums/heat_level.dart';
import 'package:cooloff/models/enums/reflection_answer.dart';
import 'package:cooloff/models/enums/sensitivity.dart';
import 'package:cooloff/stats/insights.dart';
import 'package:flutter_test/flutter_test.dart';

final _now = DateTime(2026, 11, 9, 12);
var _seq = 0;

CheckRecordData _check({
  HeatLevel? level = HeatLevel.heated,
  CheckAction? action,
  CheckKind kind = CheckKind.check,
  double? pulse,
  String? previous,
  DateTime? at,
  String? id,
}) {
  final when = (at ?? _now).toUtc();
  return CheckRecordData(
    (b) => b
      ..id = id ?? 'c${_seq++}'
      ..createdAt = when
      ..updatedAt = when
      ..isDirty = true
      ..originDeviceId = 'd'
      ..checkedAt = when
      ..kind = kind
      ..heatLevel = level
      ..pulseBpm = pulse
      ..sensitivity = Sensitivity.normal
      ..action = action
      ..previousCheckId = previous,
  );
}

ReflectionData _reflection(String checkId, ReflectionAnswer answer) =>
    ReflectionData(
      (b) => b
        ..id = 'r${_seq++}'
        ..createdAt = _now.toUtc()
        ..updatedAt = _now.toUtc()
        ..isDirty = true
        ..originDeviceId = 'd'
        ..checkRecordId = checkId
        ..answer = answer
        ..answeredAt = _now.toUtc(),
    );

void main() {
  test('empty history', () {
    final insights = Insights.compute(
      checks: [],
      reflections: [],
      nowLocal: _now,
    );
    expect(insights.isEmpty, isTrue);
    expect(insights.averagePulseDrop, isNull);
    expect(insights.week, hasLength(7));
  });

  test('counts levels on first checks only', () {
    final insights = Insights.compute(
      checks: [
        _check(level: HeatLevel.calm, action: CheckAction.sent),
        _check(level: HeatLevel.warm, action: CheckAction.edited),
        _check(action: CheckAction.cooledDown),
        _check(kind: CheckKind.recheck, level: HeatLevel.calm),
        _check(level: null, action: CheckAction.cancelled),
      ],
      reflections: [],
      nowLocal: _now,
    );
    expect(insights.totalChecks, 3);
    expect((insights.calm, insights.warm, insights.heated), (1, 1, 1));
  });

  test('cooled off = warm or heated messages not sent as they were', () {
    final insights = Insights.compute(
      checks: [
        _check(action: CheckAction.held),
        _check(level: HeatLevel.warm, action: CheckAction.discarded),
        _check(action: CheckAction.sentAnyway),
        _check(level: HeatLevel.calm, action: CheckAction.edited),
      ],
      reflections: [],
      nowLocal: _now,
    );
    expect(insights.cooledOff, 2);
  });

  test('regret stats count only answers to heated sends', () {
    final sent = _check(action: CheckAction.sentAnyway, id: 'sent');
    final sent2 = _check(action: CheckAction.sentAnyway, id: 'sent2');
    final insights = Insights.compute(
      checks: [
        sent,
        sent2,
        _check(action: CheckAction.held, id: 'held'),
      ],
      reflections: [
        _reflection('sent', ReflectionAnswer.regret),
        _reflection('sent2', ReflectionAnswer.glad),
        _reflection('held', ReflectionAnswer.regret),
      ],
      nowLocal: _now,
    );
    expect(insights.heatedSends, 2);
    expect(insights.checkinsAnswered, 2);
    expect(insights.regretted, 1);
  });

  test('average pulse drop pairs each re-check with its check', () {
    final insights = Insights.compute(
      checks: [
        _check(action: CheckAction.cooledDown, pulse: 98, id: 'a'),
        _check(
          kind: CheckKind.recheck,
          level: HeatLevel.calm,
          pulse: 84,
          previous: 'a',
        ),
        _check(action: CheckAction.cooledDown, pulse: 90, id: 'b'),
        _check(
          kind: CheckKind.recheck,
          level: HeatLevel.warm,
          pulse: 80,
          previous: 'b',
        ),
        _check(
          kind: CheckKind.recheck,
          level: HeatLevel.calm,
          previous: 'missing',
        ),
      ],
      reflections: [],
      nowLocal: _now,
    );
    expect(insights.cooldowns, 3);
    expect(insights.averagePulseDrop, 12);
  });

  test('the week puts checks on their local day', () {
    final insights = Insights.compute(
      checks: [
        _check(level: HeatLevel.calm, at: DateTime(2026, 11, 9, 8)),
        _check(at: DateTime(2026, 11, 3, 23, 30)),
        _check(at: DateTime(2026, 11, 2, 12)), // 8 days ago: outside
      ],
      reflections: [],
      nowLocal: _now,
    );
    expect(insights.week.first.day, DateTime(2026, 11, 3));
    expect(insights.week.first.heated, 1);
    expect(insights.week.last.calm, 1);
    expect(insights.week.fold<int>(0, (sum, d) => sum + d.total), 2);
  });
}
