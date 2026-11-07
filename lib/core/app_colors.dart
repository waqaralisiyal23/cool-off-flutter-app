import 'package:flutter/material.dart';

/// The app's colour tokens. **Replace these with your design's palette.**
///
/// Every colour used in `lib/pages/**` and `lib/widgets/**` comes from here —
/// never a `Color(0x…)` or a Material `Colors.*` — so a palette change lands
/// in one place.
///
/// A mature version has two tiers: raw ramps (`red700`, `grey100`) and
/// semantic aliases naming the *intent* (`textPrimary`, `border`). Widgets
/// reference only the semantic names.
class AppColors {
  AppColors._();

  /// Primary brand colour.
  static const Color primary = Color(0xFF2563EB);

  /// Body text.
  static const Color textPrimary = Color(0xFF111827);
}
