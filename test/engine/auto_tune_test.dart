import 'package:cooloff/engine/auto_tune.dart';
import 'package:cooloff/models/enums/reflection_answer.dart';
import 'package:flutter_test/flutter_test.dart';

const _glad = ReflectionAnswer.glad;
const _regret = ReflectionAnswer.regret;

void main() {
  test('does nothing below the minimum number of answers', () {
    expect(AutoTune.offsetFor([]), 0);
    expect(AutoTune.offsetFor([_regret, _regret]), 0);
  });

  test('mostly regret → more cautious (−1)', () {
    expect(AutoTune.offsetFor([_regret, _regret, _glad]), -1);
  });

  test('mostly glad → less cautious (+1)', () {
    expect(AutoTune.offsetFor([_glad, _glad, _glad, _regret]), 1);
  });

  test('a split stays at 0', () {
    expect(AutoTune.offsetFor([_glad, _regret, _glad, _regret]), 0);
  });

  test('only the most recent answers count', () {
    final answers = [
      ...List.filled(AutoTune.window, _glad),
      ...List.filled(20, _regret),
    ];
    expect(AutoTune.offsetFor(answers), 1);
  });
}
