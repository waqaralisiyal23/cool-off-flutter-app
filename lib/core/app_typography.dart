import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Cool Off's type scale (docs/12-design-system.md).
///
/// Two bundled families (no runtime font downloads, so nothing leaves the
/// phone): **Manrope** for everything you read, **Space Grotesk** for the
/// big numbers (BPM, countdowns, scores), which use tabular figures so they
/// don't jitter while they change.
///
/// Styles are named `<weight><size>`; compose roles at the call site with
/// `.copyWith()`.
class AppTypography {
  AppTypography._();

  static const String bodyFamily = 'Manrope';
  static const String numberFamily = 'SpaceGrotesk';

  static const List<FontFeature> _tabular = [FontFeature.tabularFigures()];

  // ─── Manrope ───────────────────────────────────────────────────────────
  static const TextStyle regular12 = TextStyle(
    fontFamily: bodyFamily,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textMuted,
  );

  static const TextStyle medium12 = TextStyle(
    fontFamily: bodyFamily,
    fontSize: 12,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.6,
    color: AppColors.textMuted,
  );

  static const TextStyle regular14 = TextStyle(
    fontFamily: bodyFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.45,
    color: AppColors.textSecondary,
  );

  static const TextStyle medium14 = TextStyle(
    fontFamily: bodyFamily,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
  );

  static const TextStyle semiBold14 = TextStyle(
    fontFamily: bodyFamily,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static const TextStyle regular16 = TextStyle(
    fontFamily: bodyFamily,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: AppColors.textPrimary,
  );

  static const TextStyle medium16 = TextStyle(
    fontFamily: bodyFamily,
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
  );

  static const TextStyle semiBold16 = TextStyle(
    fontFamily: bodyFamily,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static const TextStyle semiBold18 = TextStyle(
    fontFamily: bodyFamily,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static const TextStyle bold20 = TextStyle(
    fontFamily: bodyFamily,
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  static const TextStyle bold24 = TextStyle(
    fontFamily: bodyFamily,
    fontSize: 24,
    fontWeight: FontWeight.w700,
    height: 1.25,
    color: AppColors.textPrimary,
  );

  static const TextStyle extraBold32 = TextStyle(
    fontFamily: bodyFamily,
    fontSize: 32,
    fontWeight: FontWeight.w800,
    height: 1.15,
    letterSpacing: -0.5,
    color: AppColors.textPrimary,
  );

  /// The wordmark on the welcome screen.
  static const TextStyle extraBold40 = TextStyle(
    fontFamily: bodyFamily,
    fontSize: 40,
    fontWeight: FontWeight.w800,
    height: 1.1,
    letterSpacing: -1,
    color: AppColors.textPrimary,
  );

  // ─── Space Grotesk (numbers) ───────────────────────────────────────────
  static const TextStyle number16 = TextStyle(
    fontFamily: numberFamily,
    fontSize: 16,
    fontWeight: FontWeight.w500,
    fontFeatures: _tabular,
    color: AppColors.textPrimary,
  );

  static const TextStyle number24 = TextStyle(
    fontFamily: numberFamily,
    fontSize: 24,
    fontWeight: FontWeight.w700,
    fontFeatures: _tabular,
    color: AppColors.textPrimary,
  );

  static const TextStyle number40 = TextStyle(
    fontFamily: numberFamily,
    fontSize: 40,
    fontWeight: FontWeight.w700,
    height: 1,
    fontFeatures: _tabular,
    color: AppColors.textPrimary,
  );

  static const TextStyle number64 = TextStyle(
    fontFamily: numberFamily,
    fontSize: 64,
    fontWeight: FontWeight.w700,
    height: 1,
    letterSpacing: -2,
    fontFeatures: _tabular,
    color: AppColors.textPrimary,
  );
}
