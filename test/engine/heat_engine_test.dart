import 'package:cooloff/engine/heat_engine.dart';
import 'package:cooloff/engine/text_heat.dart';
import 'package:cooloff/models/enums/heat_level.dart';
import 'package:cooloff/models/enums/sensitivity.dart';
import 'package:flutter_test/flutter_test.dart';

HeatResult _evaluate({
  double? pulse = 70,
  double? baseline = 70,
  double? anger = 5,
  double baselineAnger = 5,
  TextHeatResult text = TextHeatResult.none,
  Sensitivity sensitivity = Sensitivity.normal,
  int autoTune = 0,
}) => HeatEngine.evaluate(
  HeatInput(
    pulseBpm: pulse,
    baselinePulseBpm: baseline,
    angerLevel: anger,
    baselineAngerLevel: baselineAnger,
    textHeat: text,
    sensitivity: sensitivity,
    autoTuneOffset: autoTune,
  ),
);

const _someText = TextHeatResult(
  points: 1,
  signals: {TextHeatSignal.punctuation},
);
const _lotsOfText = TextHeatResult(
  points: 2,
  signals: {TextHeatSignal.caps, TextHeatSignal.harshWords},
);

void main() {
  group('pulse points', () {
    test('under 5% above usual scores 0', () {
      final r = _evaluate(pulse: 73); // +4.3 %
      expect(r.pulsePoints, 0);
      expect(r.reasons.whereType<PulseAboveUsual>(), isEmpty);
    });

    test('exactly 5% scores 1', () {
      expect(_evaluate(pulse: 84, baseline: 80).pulsePoints, 1);
    });

    test('exactly 15% still scores 1, just above scores 2', () {
      expect(_evaluate(pulse: 92, baseline: 80).pulsePoints, 1);
      expect(_evaluate(pulse: 92.1, baseline: 80).pulsePoints, 2);
    });

    test('a pulse below usual scores 0', () {
      expect(_evaluate(pulse: 60).pulsePoints, 0);
    });

    test('the reason carries the rounded difference in bpm', () {
      final r = _evaluate(pulse: 88.4);
      final reason = r.reasons.whereType<PulseAboveUsual>().single;
      expect(reason.deltaBpm, 18);
      expect(reason.strong, isTrue);
    });
  });

  group('anger points (baseline subtracted)', () {
    test('resting anger is subtracted and floored at 0', () {
      final r = _evaluate(anger: 12, baselineAnger: 20);
      expect(r.relativeAnger, 0);
      expect(r.angerPoints, 0);
    });

    test('10 above rest scores 1, over 25 scores 2', () {
      expect(_evaluate(anger: 25, baselineAnger: 15).angerPoints, 1);
      expect(_evaluate(anger: 40, baselineAnger: 15).angerPoints, 1);
      expect(_evaluate(anger: 40.5, baselineAnger: 15).angerPoints, 2);
    });

    test('a face that reads angry at rest is not heated by itself', () {
      final r = _evaluate(anger: 35, baselineAnger: 30);
      expect(r.angerPoints, 0);
      expect(r.level, HeatLevel.calm);
    });
  });

  group('levels at normal sensitivity', () {
    test('nothing → Calm', () {
      expect(_evaluate().level, HeatLevel.calm);
      expect(_evaluate().score, 0);
    });

    test('1 point → Calm, 2 → Warm, 3 → Warm, 4 → Heated', () {
      expect(_evaluate(text: _someText).level, HeatLevel.calm);
      expect(_evaluate(text: _lotsOfText).level, HeatLevel.warm);
      expect(_evaluate(text: _lotsOfText, pulse: 75).level, HeatLevel.warm);
      expect(_evaluate(text: _lotsOfText, pulse: 90).level, HeatLevel.heated);
    });

    test('everything high → Heated with a full score', () {
      final r = _evaluate(pulse: 95, anger: 60, text: _lotsOfText);
      expect(r.score, 6);
      expect(r.level, HeatLevel.heated);
    });
  });

  group('missing pulse', () {
    test('is reported, never invented', () {
      final r = _evaluate(pulse: null);
      expect(r.pulseMissing, isTrue);
      expect(r.pulseDeltaPct, isNull);
      expect(r.reasons.last, isA<PulseUnavailable>());
    });

    test('no baseline counts as missing pulse', () {
      expect(_evaluate(baseline: null).pulseMissing, isTrue);
    });

    test('face + text scale up so the cutoffs keep their meaning', () {
      // 3 of 4 available points → 4.5 → floor 4 → Heated.
      final r = _evaluate(pulse: null, anger: 50, text: _someText);
      expect(r.score, 4);
      expect(r.level, HeatLevel.heated);
    });

    test('one point of text alone stays Calm', () {
      expect(_evaluate(pulse: null, text: _someText).level, HeatLevel.calm);
    });
  });

  group('sensitivity and auto-tune', () {
    test('cutoffs per sensitivity', () {
      expect(HeatEngine.cutoffs(Sensitivity.normal, 0), (warm: 2, heated: 4));
      expect(HeatEngine.cutoffs(Sensitivity.high, 0), (warm: 1, heated: 3));
      expect(HeatEngine.cutoffs(Sensitivity.low, 0), (warm: 3, heated: 5));
    });

    test('auto-tune moves only the Heated cutoff, clamped to ±1', () {
      expect(HeatEngine.cutoffs(Sensitivity.normal, -1), (warm: 2, heated: 3));
      expect(HeatEngine.cutoffs(Sensitivity.normal, 1), (warm: 2, heated: 5));
      expect(HeatEngine.cutoffs(Sensitivity.normal, -5), (warm: 2, heated: 3));
      expect(HeatEngine.cutoffs(Sensitivity.normal, 5), (warm: 2, heated: 5));
    });

    test('Heated always needs more than Warm', () {
      final limits = HeatEngine.cutoffs(Sensitivity.high, -1);
      expect(limits.warm, 1);
      expect(limits.heated, 2);
    });

    test('high sensitivity turns a Warm 3 into Heated', () {
      final normal = _evaluate(text: _lotsOfText, pulse: 75);
      final high = _evaluate(
        text: _lotsOfText,
        pulse: 75,
        sensitivity: Sensitivity.high,
      );
      expect(normal.level, HeatLevel.warm);
      expect(high.level, HeatLevel.heated);
    });

    test('low sensitivity keeps a score of 4 Warm', () {
      final r = _evaluate(
        text: _lotsOfText,
        pulse: 90,
        sensitivity: Sensitivity.low,
      );
      expect(r.level, HeatLevel.warm);
    });
  });

  test('reasons come strongest first', () {
    final r = _evaluate(pulse: 95, anger: 20, text: _someText);
    expect(r.reasons[0], isA<PulseAboveUsual>());
    expect(r.reasons[1], isA<AngerRead>());
    expect(r.reasons[2], isA<TextRead>());
  });
}
