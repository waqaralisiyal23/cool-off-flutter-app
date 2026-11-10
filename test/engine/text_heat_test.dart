import 'package:cooloff/engine/text_heat.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TextHeat', () {
    test('a plain, polite message has no heat', () {
      final result = TextHeat.analyze(
        'Hi Sam, could we move the review to Thursday? Thanks.',
      );
      expect(result.points, 0);
      expect(result.signals, isEmpty);
    });

    test('empty and whitespace-only text has no heat', () {
      expect(TextHeat.analyze('').points, 0);
      expect(TextHeat.analyze('   \n ').points, 0);
    });

    test('short and emoji-only messages ignore the CAPS rule', () {
      expect(TextHeat.analyze('OK').points, 0);
      expect(
        TextHeat.analyze('NO WAY').signals,
        isNot(contains(TextHeatSignal.caps)),
      );
      expect(TextHeat.analyze('😡😡').points, 0);
      expect(TextHeat.analyze('👍').points, 0);
    });

    test('a mostly-capitals message is a lot of CAPS', () {
      final result = TextHeat.analyze('WHY DID YOU NOT SEND THE REPORT TODAY');
      expect(result.signals, contains(TextHeatSignal.caps));
      expect(result.points, 1);
    });

    test('acronyms are not shouting', () {
      final result = TextHeat.analyze(
        'Please send the PDF to the CEO ASAP, FYI the ETA moved.',
      );
      expect(result.signals, isNot(contains(TextHeatSignal.caps)));
    });

    test('two shouted words in a normal message are some CAPS', () {
      final result = TextHeat.analyze(
        'I told you this was due on Monday, NOT Friday, and you KNOW it',
      );
      expect(result.signals, contains(TextHeatSignal.caps));
    });

    test('a single "!!" is some punctuation heat', () {
      final result = TextHeat.analyze('Are you serious!!');
      expect(result.signals, contains(TextHeatSignal.punctuation));
      expect(result.points, 1);
    });

    test('"?!?!" counts as punctuation', () {
      expect(
        TextHeat.analyze('What were you thinking?!?!').signals,
        contains(TextHeatSignal.punctuation),
      );
    });

    test('one "!" or "?" is not heat', () {
      expect(TextHeat.analyze('Great job today!').points, 0);
      expect(TextHeat.analyze('Can you call me?').points, 0);
    });

    test('a harsh word is heat, and is matched as a whole word', () {
      expect(
        TextHeat.analyze('That was a stupid plan').signals,
        contains(TextHeatSignal.harshWords),
      );
      // "class" contains "ass"; "Scunthorpe"-style false matches must not count.
      expect(TextHeat.analyze('See you in class tomorrow').points, 0);
    });

    test('harsh phrases count', () {
      expect(
        TextHeat.analyze('Just shut up about it').signals,
        contains(TextHeatSignal.harshWords),
      );
      expect(
        TextHeat.analyze('what the f**k').signals,
        contains(TextHeatSignal.harshWords),
      );
    });

    test('two harsh words are a lot of heat', () {
      expect(TextHeat.analyze('You are a useless idiot').points, 2);
    });

    test('absolute words alone are some heat', () {
      final result = TextHeat.analyze('You always do this to me');
      expect(result.signals, {TextHeatSignal.absolutes});
      expect(result.points, 1);
    });

    test('several signals together are a lot of heat', () {
      final result = TextHeat.analyze(
        'YOU NEVER LISTEN TO ANYTHING I SAY!!! UNBELIEVABLE',
      );
      expect(result.points, 2);
      expect(
        result.signals,
        containsAll([
          TextHeatSignal.caps,
          TextHeatSignal.punctuation,
          TextHeatSignal.harshWords,
          TextHeatSignal.absolutes,
        ]),
      );
    });
  });
}
