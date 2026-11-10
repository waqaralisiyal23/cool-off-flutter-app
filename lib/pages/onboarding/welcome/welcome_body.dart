import 'package:flutter/material.dart';

import '../../../core/app_colors.dart';
import '../../../core/app_dimens.dart';
import '../../../core/app_typography.dart';
import '../../../extension/context.dart';
import '../../../utils/app_haptics.dart';
import '../../../widgets/heartbeat.dart';
import '../../../widgets/heat_glow_background.dart';
import '../../../widgets/heat_ring.dart';
import '../consent/consent_page.dart';
import '../../../widgets/fill_scroll_view.dart';

class WelcomeBody extends StatelessWidget {
  const WelcomeBody({super.key});

  @override
  Widget build(BuildContext context) {
    return HeatGlowBackground(
      child: SafeArea(
        child: Padding(
          padding: AppSpacing.pagePadding,
          child: FillScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Spacer(),
                Center(
                  child: Semantics(
                    label: 'A pulse of 98 cooling down to 72 beats per minute.',
                    excludeSemantics: true,
                    child: const _CoolingHero(),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                const Text(
                  'Cool Off',
                  style: AppTypography.extraBold40,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Check your pulse before you hit send.',
                  style: AppTypography.regular16.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const Spacer(),
                const _Step(
                  icon: Icons.edit_note_rounded,
                  text: "Write the message you're tempted to send.",
                ),
                const _Step(
                  icon: Icons.favorite_rounded,
                  text:
                      'A 20-second camera check reads your pulse and '
                      'expression.',
                ),
                const _Step(
                  icon: Icons.ac_unit_rounded,
                  text:
                      'Send it, hold it, or cool down first. Always your call.',
                ),
                const SizedBox(height: AppSpacing.lg),
                FilledButton(
                  onPressed: () {
                    AppHaptics.tap();
                    context.pushNamed(ConsentPage.ROUTE_NAME);
                  },
                  child: const Text('Get started'),
                ),
                const SizedBox(height: AppSpacing.md),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Step extends StatelessWidget {
  final IconData icon;
  final String text;

  const _Step({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: AppRadius.smAll,
            ),
            child: Icon(icon, size: 20, color: AppColors.primary),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(text, style: AppTypography.regular14)),
        ],
      ),
    );
  }
}

/// The promise, animated: a ring cooling from ember at 98 bpm to ice at
/// 72 bpm, with a heart beating at the shown pulse. Loops every 7 seconds.
class _CoolingHero extends StatefulWidget {
  const _CoolingHero();

  @override
  State<_CoolingHero> createState() => _CoolingHeroState();
}

class _CoolingHeroState extends State<_CoolingHero>
    with SingleTickerProviderStateMixin {
  late final AnimationController _loop = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 7),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _loop.value = 1;
    } else if (!_loop.isAnimating) {
      _loop.repeat();
    }
  }

  @override
  void dispose() {
    _loop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _loop,
      builder: (context, _) {
        // Hold hot, cool down, hold cool.
        final t = Curves.easeInOutCubic.transform(
          ((_loop.value - 0.15) / 0.6).clamp(0.0, 1.0),
        );
        final heat = 1 - t;
        final bpm = (98 - 26 * t).round();
        final color = AppColors.heatAt(heat);
        return HeatRing(
          size: 220,
          progress: 0.25 + 0.75 * heat,
          color: color,
          duration: Duration.zero,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Heartbeat(bpm: bpm.toDouble(), color: color, size: 30),
                const SizedBox(height: AppSpacing.xs),
                Text('$bpm', style: AppTypography.number64),
                Text(
                  'bpm',
                  style: AppTypography.medium12.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Icon(
                  heat > 0.5
                      ? Icons.local_fire_department_rounded
                      : Icons.ac_unit_rounded,
                  size: 18,
                  color: color,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
