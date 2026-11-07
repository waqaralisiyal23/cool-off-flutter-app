import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Hoist shape, padding and text styles into the theme, so a shared widget
/// only adds what is unique to it and a bare Material widget anywhere in the
/// app already looks right.
class AppTheme {
  AppTheme._();

  static ThemeData getLightTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
      primaryColor: AppColors.primary,
    );
  }
}
