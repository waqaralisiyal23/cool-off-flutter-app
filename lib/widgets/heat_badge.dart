import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../core/app_dimens.dart';
import '../core/app_typography.dart';
import '../models/enums/heat_level.dart';

/// The icon of each heat level. Shapes differ, so the result never relies on
/// colour alone.
IconData heatIcon(HeatLevel level) => level.when(
  calm: () => Icons.ac_unit_rounded,
  warm: () => Icons.wb_sunny_rounded,
  heated: () => Icons.local_fire_department_rounded,
);

/// A small pill: icon + "Calm" / "Warm" / "Heated".
class HeatBadge extends StatelessWidget {
  final HeatLevel level;
  final bool large;

  const HeatBadge({super.key, required this.level, this.large = false});

  @override
  Widget build(BuildContext context) {
    final color = AppColors.heat(level);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: large ? AppSpacing.md : AppSpacing.sm,
        vertical: large ? AppSpacing.xs : AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(heatIcon(level), size: large ? 18 : 14, color: color),
          const SizedBox(width: AppSpacing.xxs),
          Text(
            level.label,
            style: (large ? AppTypography.semiBold14 : AppTypography.medium12)
                .copyWith(color: color, letterSpacing: 0.2),
          ),
        ],
      ),
    );
  }
}
