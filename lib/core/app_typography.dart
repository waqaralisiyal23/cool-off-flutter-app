import 'package:flutter/material.dart';

import 'app_colors.dart';

/// The app's type scale. **Replace these with your design's styles.**
///
/// All text in `lib/pages/**` and `lib/widgets/**` goes through here — never a
/// literal `fontSize:`. Styles are named `<weight><size>` rather than by role
/// (`cardTitle`, `navLabel`), so they do not over-fit the first screen that
/// uses them; compose semantic variants at the call site with `.copyWith()`.
///
/// Leave [TextStyle.height] null unless the design fixes a line height: null
/// lets the font's own metrics apply, which is what Figma's "Auto" means.
class AppTypography {
  AppTypography._();

  // The font family is set once, in `AppTheme` (`ThemeData.fontFamily`), and
  // every style inherits it. Bundle the font under `flutter: fonts:` in
  // `pubspec.yaml` and set it there.

  static const TextStyle regular14 = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
  );

  static const TextStyle regular16 = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
  );

  static const TextStyle medium16 = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
  );

  static const TextStyle semiBold18 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static const TextStyle bold24 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );
}
