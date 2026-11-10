import 'package:flutter/material.dart';

import '../models/enums/heat_level.dart';

/// Cool Off's colour tokens (docs/12-design-system.md).
///
/// A dark "cool night" palette: deep ink surfaces with frost-blue text, and
/// heat colours (ice teal → amber → ember) as the only bright accents, so a
/// result's colour always means something.
///
/// Every colour in `lib/pages/**` and `lib/widgets/**` comes from here. Raw
/// ramps are private; widgets use the semantic names.
class AppColors {
  AppColors._();

  // ─── Raw ramps ─────────────────────────────────────────────────────────
  static const Color _ink950 = Color(0xFF060A14);
  static const Color _ink900 = Color(0xFF0A1020);
  static const Color _ink850 = Color(0xFF0F172A);
  static const Color _ink800 = Color(0xFF151F36);
  static const Color _ink700 = Color(0xFF1E2A45);
  static const Color _ink600 = Color(0xFF2A3858);

  static const Color _frost50 = Color(0xFFF1F6FF);
  static const Color _frost200 = Color(0xFFB9C7E2);
  static const Color _frost400 = Color(0xFF7D8DAE);
  static const Color _frost600 = Color(0xFF55627F);

  static const Color _ice300 = Color(0xFF7FE7F2);
  static const Color _ice400 = Color(0xFF3FD5E6);
  static const Color _ice600 = Color(0xFF14A3B8);

  static const Color _amber300 = Color(0xFFFFD27A);
  static const Color _amber400 = Color(0xFFFFB547);

  static const Color _ember300 = Color(0xFFFF8F7A);
  static const Color _ember400 = Color(0xFFFF5E4D);
  static const Color _ember600 = Color(0xFFD9342B);

  // ─── Surfaces ──────────────────────────────────────────────────────────
  /// The page behind everything.
  static const Color background = _ink900;

  /// Deepest layer: behind the camera, under sheets.
  static const Color backgroundDeep = _ink950;

  /// Cards, fields, sheets.
  static const Color surface = _ink850;

  /// A card on a card; pressed states.
  static const Color surfaceRaised = _ink800;

  /// Hairlines and field outlines.
  static const Color border = _ink700;

  /// Focused outlines, dividers that must be seen.
  static const Color borderStrong = _ink600;

  // ─── Text ──────────────────────────────────────────────────────────────
  static const Color textPrimary = _frost50;
  static const Color textSecondary = _frost200;
  static const Color textMuted = _frost400;
  static const Color textDisabled = _frost600;

  /// Text on a bright heat or brand fill.
  static const Color textOnAccent = _ink950;

  // ─── Brand ─────────────────────────────────────────────────────────────
  /// The cool accent: primary buttons, focus, links.
  static const Color primary = _ice400;
  static const Color primarySoft = _ice300;
  static const Color primaryDeep = _ice600;

  // ─── Heat (results, rings, graphs) ─────────────────────────────────────
  static const Color calm = _ice400;
  static const Color calmSoft = _ice300;
  static const Color warm = _amber400;
  static const Color warmSoft = _amber300;
  static const Color heated = _ember400;
  static const Color heatedSoft = _ember300;
  static const Color heatedDeep = _ember600;

  /// Errors use the heated red; Cool Off has no separate error hue.
  static const Color error = _ember400;

  /// Translucent black for scrims over the camera.
  static const Color scrim = Color(0xB3060A14);

  static const Color transparent = Color(0x00000000);

  /// The colour of [level].
  static Color heat(HeatLevel level) =>
      level.when(calm: () => calm, warm: () => warm, heated: () => heated);

  static Color heatSoft(HeatLevel level) => level.when(
    calm: () => calmSoft,
    warm: () => warmSoft,
    heated: () => heatedSoft,
  );

  /// The temperature scale from cool to hot, for gradients and for
  /// [heatAt].
  static const List<Color> heatScale = [calm, warm, heated];

  /// A colour on the cool → hot scale; [t] from 0 (cool) to 1 (hot).
  static Color heatAt(double t) {
    final clamped = t.clamp(0.0, 1.0);
    if (clamped <= 0.5) {
      return Color.lerp(calm, warm, clamped * 2)!;
    }
    return Color.lerp(warm, heated, (clamped - 0.5) * 2)!;
  }
}
