import '../models/enums/heat_level.dart';
import '../models/enums/sensitivity.dart';
import 'text_heat.dart';

/// What went into a check (docs/03-heat-engine.md).
class HeatInput {
  const HeatInput({
    required this.pulseBpm,
    required this.baselinePulseBpm,
    required this.angerLevel,
    required this.baselineAngerLevel,
    required this.textHeat,
    this.sensitivity = Sensitivity.normal,
    this.autoTuneOffset = 0,
  });

  /// The check's pulse (median of its last readings); null when the SDK
  /// never gave a usable value. Never invented.
  final double? pulseBpm;

  /// The user's usual pulse; null before a baseline exists.
  final double? baselinePulseBpm;

  /// Mean anger level over the check (0–100); null when the face was never
  /// read.
  final double? angerLevel;

  final double baselineAngerLevel;

  final TextHeatResult textHeat;

  final Sensitivity sensitivity;

  /// From the next-morning check-ins (auto-tune), −1, 0 or +1. Moves the
  /// Heated cutoff only.
  final int autoTuneOffset;
}

/// One reason a check scored, for the result screen's plain-language line.
sealed class HeatReason {
  const HeatReason();
}

/// The pulse is above the user's usual.
class PulseAboveUsual extends HeatReason {
  const PulseAboveUsual({required this.deltaBpm, required this.strong});

  final int deltaBpm;
  final bool strong;
}

/// Anger, contempt or disgust read higher than at rest.
class AngerRead extends HeatReason {
  const AngerRead({required this.strong});

  final bool strong;
}

/// Something in the text itself.
class TextRead extends HeatReason {
  const TextRead(this.signal);

  final TextHeatSignal signal;
}

/// The pulse could not be read; the result rests on face and text.
class PulseUnavailable extends HeatReason {
  const PulseUnavailable();
}

class HeatResult {
  const HeatResult({
    required this.level,
    required this.score,
    required this.pulsePoints,
    required this.angerPoints,
    required this.textPoints,
    required this.pulseDeltaPct,
    required this.relativeAnger,
    required this.reasons,
  });

  final HeatLevel level;

  /// 0–6, scaled up when the pulse was missing so the cutoffs keep their
  /// meaning.
  final int score;

  final int pulsePoints;
  final int angerPoints;
  final int textPoints;

  /// Pulse vs usual, in percent; null without a pulse or baseline.
  final double? pulseDeltaPct;

  /// Anger level above the resting level, floored at 0; null without face.
  final double? relativeAnger;

  /// Most telling first.
  final List<HeatReason> reasons;

  bool get pulseMissing => pulseDeltaPct == null;
}

/// Turns one check's signals into Calm / Warm / Heated, with reasons.
class HeatEngine {
  HeatEngine._();

  // Pulse vs usual: under 5 % → 0 points, 5–15 % → 1, over 15 % → 2.
  static const double pulseSomePct = 5;
  static const double pulseStrongPct = 15;

  // Anger above resting, on the SDK's 0–100 scale. Starting values; tune on
  // device (docs/03-heat-engine.md).
  static const double angerSome = 10;
  static const double angerStrong = 25;

  // Score cutoffs at normal sensitivity: Calm 0–1, Warm 2–3, Heated 4+.
  static const int warmCutoff = 2;
  static const int heatedCutoff = 4;

  static const int maxScore = 6;

  /// The cutoffs after [sensitivity] and [autoTuneOffset], kept sane:
  /// Warm needs at least 1 point, Heated at least one more than Warm.
  static ({int warm, int heated}) cutoffs(
    Sensitivity sensitivity,
    int autoTuneOffset,
  ) {
    final shift = sensitivity.cutoffShift;
    final warm = (warmCutoff + shift).clamp(1, maxScore - 1);
    final heated = (heatedCutoff + shift + autoTuneOffset.clamp(-1, 1)).clamp(
      warm + 1,
      maxScore,
    );
    return (warm: warm, heated: heated);
  }

  static HeatResult evaluate(HeatInput input) {
    final reasons = <HeatReason>[];

    // ─── Pulse ───────────────────────────────────────────────────────────
    double? deltaPct;
    var pulsePoints = 0;
    final pulse = input.pulseBpm;
    final baseline = input.baselinePulseBpm;
    if (pulse != null && baseline != null && baseline > 0) {
      deltaPct = (pulse - baseline) / baseline * 100;
      if (deltaPct > pulseStrongPct) {
        pulsePoints = 2;
      } else if (deltaPct >= pulseSomePct) {
        pulsePoints = 1;
      }
      if (pulsePoints > 0) {
        reasons.add(
          PulseAboveUsual(
            deltaBpm: (pulse - baseline).round(),
            strong: pulsePoints == 2,
          ),
        );
      }
    }

    // ─── Face ────────────────────────────────────────────────────────────
    double? relativeAnger;
    var angerPoints = 0;
    final anger = input.angerLevel;
    if (anger != null) {
      final relative = anger - input.baselineAngerLevel;
      relativeAnger = relative < 0 ? 0 : relative;
      if (relativeAnger > angerStrong) {
        angerPoints = 2;
      } else if (relativeAnger >= angerSome) {
        angerPoints = 1;
      }
      if (angerPoints > 0) {
        reasons.add(AngerRead(strong: angerPoints == 2));
      }
    }

    // ─── Text ────────────────────────────────────────────────────────────
    final textPoints = input.textHeat.points;
    if (textPoints > 0) {
      for (final signal in TextHeatSignal.values) {
        if (input.textHeat.signals.contains(signal)) {
          reasons.add(TextRead(signal));
        }
      }
    }

    // Strongest first: points 2 before points 1, body before text.
    reasons.sort((a, b) => _weight(b).compareTo(_weight(a)));

    // ─── Score ───────────────────────────────────────────────────────────
    final available = (deltaPct != null ? 2 : 0) + (anger != null ? 2 : 0) + 2;
    final raw = pulsePoints + angerPoints + textPoints;
    // Scaled down signals keep their meaning: with the pulse missing, 3 of
    // the 4 available points still reads as Heated. Floor, so one point of
    // text alone never jumps to Warm.
    final score = available == maxScore ? raw : raw * maxScore ~/ available;

    if (deltaPct == null) {
      reasons.add(const PulseUnavailable());
    }

    final limits = cutoffs(input.sensitivity, input.autoTuneOffset);
    final level = score >= limits.heated
        ? HeatLevel.heated
        : score >= limits.warm
        ? HeatLevel.warm
        : HeatLevel.calm;

    return HeatResult(
      level: level,
      score: score,
      pulsePoints: pulsePoints,
      angerPoints: angerPoints,
      textPoints: textPoints,
      pulseDeltaPct: deltaPct,
      relativeAnger: relativeAnger,
      reasons: List.unmodifiable(reasons),
    );
  }

  static int _weight(HeatReason reason) => switch (reason) {
    PulseAboveUsual(:final strong) => strong ? 5 : 3,
    AngerRead(:final strong) => strong ? 4 : 2,
    TextRead() => 1,
    PulseUnavailable() => 0,
  };
}
