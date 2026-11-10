import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../core/app_dimens.dart';

/// The app's card: a softly lit surface with a hairline border, optionally
/// tinted by an accent (a held message, a heated result).
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? accent;
  final VoidCallback? onTap;

  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.md),
    this.accent,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tint = accent;
    return Material(
      color: AppColors.transparent,
      child: Ink(
        decoration: BoxDecoration(
          borderRadius: AppRadius.lgAll,
          border: Border.all(
            color: tint == null
                ? AppColors.border
                : tint.withValues(alpha: 0.35),
          ),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              tint == null
                  ? AppColors.surfaceRaised
                  : Color.alphaBlend(
                      tint.withValues(alpha: 0.10),
                      AppColors.surface,
                    ),
              AppColors.surface,
            ],
          ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.lgAll,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}
