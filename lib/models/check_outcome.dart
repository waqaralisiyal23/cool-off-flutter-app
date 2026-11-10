import '../engine/heat_engine.dart';

/// A finished check, handed from the check screen to the result and
/// cool-down screens. In memory only; the saved form is the check record.
class CheckOutcome {
  const CheckOutcome({
    required this.checkId,
    required this.result,
    required this.text,
    required this.recipient,
    required this.pulseBpm,
    required this.baselinePulseBpm,
    required this.angerLevel,
    this.previous,
  });

  final String checkId;
  final HeatResult result;

  /// The message. Never logged, never sent anywhere by the app.
  final String text;
  final String? recipient;

  final double? pulseBpm;
  final double? baselinePulseBpm;

  /// Mean anger level (0–100) before the baseline is subtracted.
  final double? angerLevel;

  /// For a re-check after a cool-down: the check it follows.
  final CheckOutcome? previous;

  /// Expression heat shown to the user: anger above rest, 0–100.
  int? get expressionHeat => result.relativeAnger?.round();
}
