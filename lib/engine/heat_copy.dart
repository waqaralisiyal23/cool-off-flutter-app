import '../models/enums/heat_level.dart';
import 'heat_engine.dart';
import 'text_heat.dart';

/// User-facing words for results and reasons.
///
/// Wording rules (docs/06-privacy-and-data.md): say what was *read* ("seems
/// heated", "higher than your usual"), never what the person *is* ("you are
/// angry"), and nothing medical ("stress level", "blood pressure").
class HeatCopy {
  HeatCopy._();

  static String reason(HeatReason reason) => switch (reason) {
    PulseAboveUsual(:final deltaBpm) => 'Pulse +$deltaBpm above your usual',
    AngerRead(:final strong) =>
      strong ? 'Your expression reads heated' : 'Your expression reads tense',
    TextRead(:final signal) => switch (signal) {
      TextHeatSignal.caps => 'Lots of CAPS',
      TextHeatSignal.punctuation => 'Lots of !!!',
      TextHeatSignal.harshWords => 'Some harsh words',
      TextHeatSignal.absolutes => '"Always" / "never" words',
    },
    PulseUnavailable() =>
      "Couldn't read your pulse, so this is based on "
          'your expression and the text',
  };

  static String headline(HeatLevel level) => level.when(
    calm: () => 'You seem calm',
    warm: () => 'You seem a little warm',
    heated: () => 'You seem heated',
  );

  static String suggestion(HeatLevel level) => level.when(
    calm: () => 'Looks good to send.',
    warm: () => 'Reread it once before sending?',
    heated: () => 'Hold this for a few minutes? You can still send it anyway.',
  );
}
