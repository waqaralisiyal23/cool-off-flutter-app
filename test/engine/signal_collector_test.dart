import 'package:cooloff/engine/baseline_calculator.dart';
import 'package:cooloff/engine/signal_collector.dart';
import 'package:flutter_test/flutter_test.dart';

const _halfSecond = 500000;

PulseSample _pulse(
  double bpm,
  int i, {
  double confidence = 80,
  bool stable = true,
}) => PulseSample(
  bpm: bpm,
  confidence: confidence,
  stable: stable,
  timestampUs: i * _halfSecond,
);

ExpressionSample _face(double angry, int i) => ExpressionSample(
  angry: angry,
  contempt: 0,
  disgust: 0,
  timestampUs: i * _halfSecond,
);

void main() {
  group('SignalCollector', () {
    test('keeps one sample per half second', () {
      final collector = SignalCollector();
      expect(
        collector.addPulse(
          const PulseSample(
            bpm: 70,
            confidence: 90,
            stable: true,
            timestampUs: 0,
          ),
        ),
        isTrue,
      );
      expect(
        collector.addPulse(
          const PulseSample(
            bpm: 71,
            confidence: 90,
            stable: true,
            timestampUs: 100000,
          ),
        ),
        isFalse,
      );
      expect(
        collector.addPulse(
          const PulseSample(
            bpm: 72,
            confidence: 90,
            stable: true,
            timestampUs: 500000,
          ),
        ),
        isTrue,
      );
      expect(collector.pulseValues, [70, 72]);
    });

    test('drops low-confidence unstable and out-of-range pulse', () {
      final collector = SignalCollector()
        ..addPulse(_pulse(70, 0, confidence: 10, stable: false))
        ..addPulse(_pulse(30, 1))
        ..addPulse(_pulse(130, 2))
        ..addPulse(_pulse(75, 3, confidence: 10)); // stable wins
      expect(collector.pulseValues, [75]);
    });

    test('median of the last readings ignores a jump', () {
      final collector = SignalCollector();
      final values = <double>[70, 71, 72, 105, 73];
      for (var i = 0; i < values.length; i++) {
        collector.addPulse(_pulse(values[i], i));
      }
      expect(collector.pulseMedian(), 72);
      expect(collector.pulseMedian(lastN: 2), (105 + 73) / 2);
    });

    test('no pulse gives null, not 0', () {
      expect(SignalCollector().pulseMedian(), isNull);
      expect(SignalCollector().angerMean(), isNull);
    });

    test('anger level sums angry + contempt + disgust, capped at 100', () {
      const sample = ExpressionSample(
        angry: 60,
        contempt: 30,
        disgust: 20,
        timestampUs: 0,
      );
      expect(sample.angerLevel, 100);
      final collector = SignalCollector()
        ..addExpression(_face(10, 0))
        ..addExpression(_face(30, 1));
      expect(collector.angerMean(), 20);
    });
  });

  group('BaselineCalculator', () {
    test('needs enough steady pulse', () {
      final collector = SignalCollector();
      for (var i = 0; i < 20; i++) {
        collector.addExpression(_face(5, i));
      }
      for (var i = 0; i < BaselineCalculator.minPulseSamples - 1; i++) {
        collector.addPulse(_pulse(70, i));
      }
      final outcome = BaselineCalculator.calculate(collector);
      expect(outcome.isSuccess, isFalse);
      expect(outcome.failure, BaselineFailure.notEnoughPulse);
    });

    test('needs enough face', () {
      final collector = SignalCollector();
      for (var i = 0; i < 20; i++) {
        collector.addPulse(_pulse(70, i));
      }
      expect(
        BaselineCalculator.calculate(collector).failure,
        BaselineFailure.notEnoughFace,
      );
    });

    test('baseline is the median pulse and mean resting anger', () {
      final collector = SignalCollector();
      for (var i = 0; i < 20; i++) {
        collector
          ..addPulse(_pulse(i.isEven ? 68.0 : 72.0, i))
          ..addExpression(_face(i.isEven ? 4.0 : 8.0, i));
      }
      final values = BaselineCalculator.calculate(collector).values!;
      expect(values.pulseBpm, 70);
      expect(values.angerLevel, 6);
      expect(values.sampleCount, 20);
    });
  });
}
