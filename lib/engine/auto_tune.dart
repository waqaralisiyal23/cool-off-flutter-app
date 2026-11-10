import '../models/enums/reflection_answer.dart';

/// Learns from the next-morning check-ins (docs/03-heat-engine.md, Extra 2).
///
/// Mostly "regretted it" after heated sends → the Heated cutoff drops a step
/// (more cautious). Mostly "glad I did" → it rises a step. Nothing changes
/// until [minAnswers] answers exist, and the offset is clamped to ±1.
class AutoTune {
  AutoTune._();

  static const int minAnswers = 3;

  /// Only the most recent answers count, so the app follows the user's
  /// current habits.
  static const int window = 10;

  /// Share of one answer needed to move the cutoff.
  static const double majority = 0.6;

  /// The offset for [answers], newest first.
  static int offsetFor(List<ReflectionAnswer> answers) {
    final recent = answers.take(window).toList();
    if (recent.length < minAnswers) {
      return 0;
    }
    final regrets = recent.where((a) => a == ReflectionAnswer.regret).length;
    final share = regrets / recent.length;
    if (share >= majority) {
      return -1;
    }
    if (1 - share >= majority) {
      return 1;
    }
    return 0;
  }
}
