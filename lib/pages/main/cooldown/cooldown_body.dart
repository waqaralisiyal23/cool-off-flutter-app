import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/app_colors.dart';
import '../../../core/app_dimens.dart';
import '../../../core/app_typography.dart';
import '../../../extension/context.dart';
import '../../../models/check_outcome.dart';
import '../../../models/enums/heat_level.dart';
import '../../../utils/app_haptics.dart';
import '../../../widgets/app_card.dart';
import '../../../widgets/breathing_halo.dart';
import '../../../widgets/camera_orb.dart';
import '../../../widgets/fade_slide_in.dart';
import '../../../widgets/heartbeat.dart';
import '../../../widgets/heat_badge.dart';
import '../../../widgets/heat_glow_background.dart';
import '../../../widgets/outcome_actions.dart';
import '../../../widgets/pulse_chart.dart';
import '../result/outcome_navigation.dart';
import '../result/result_body.dart' show ReasonList;
import 'bloc/cooldown_bloc.dart';
import 'bloc/cooldown_state.dart';
import '../../../widgets/fill_scroll_view.dart';

class CooldownBody extends StatelessWidget {
  const CooldownBody({super.key});

  @override
  Widget build(BuildContext context) {
    final bloc = CooldownBloc.of(context);
    return MultiBlocListener(
      listeners: [
        BlocListener<CooldownBloc, CooldownState>(
          listenWhen: (a, b) =>
              a.phase != b.phase && b.phase == CooldownPhase.done,
          listener: (context, state) =>
              AppHaptics.result(state.recheck!.result.level),
        ),
        BlocListener<CooldownBloc, CooldownState>(
          listenWhen: (a, b) => a.choice != b.choice && b.choice != null,
          listener: (context, state) => navigateAfterChoice(
            context,
            choice: state.choice!,
            outcome: state.recheck!,
            heldUntil: state.heldUntil,
          ),
        ),
      ],
      child: CooldownBlocSelector(
        selector: (s) => (s.phase, s.progress),
        builder: (value) {
          final (phase, progress) = value;
          // The room cools: from the original heat to ice over the minute.
          final from = AppColors.heat(bloc.original.result.level);
          final color = phase == CooldownPhase.done
              ? AppColors.heat(
                  CooldownBloc.of(context).state.recheck!.result.level,
                )
              : Color.lerp(from, AppColors.calm, (progress * 1.3).clamp(0, 1))!;
          return HeatGlowBackground(
            color: color,
            intensity: 0.7 - 0.35 * progress,
            child: SafeArea(
              child: Padding(
                padding: AppSpacing.pagePadding,
                child: AnimatedSwitcher(
                  duration: AppMotion.slow,
                  child: switch (phase) {
                    CooldownPhase.done => const _BeforeAfter(),
                    CooldownPhase.failed => const _Failed(),
                    _ => _Cooling(color: color),
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Cooling extends StatelessWidget {
  final Color color;

  const _Cooling({required this.color});

  @override
  Widget build(BuildContext context) {
    final bloc = CooldownBloc.of(context);
    return FillScrollView(
      child: Column(
        key: const ValueKey('cooling'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => context.pop(),
                icon: const Icon(Icons.close_rounded),
                tooltip: 'Stop cooling down',
              ),
              const Spacer(),
              CooldownBlocSelector(
                selector: (s) => (s.phase, s.secondsLeft),
                builder: (value) => Text(
                  switch (value.$1) {
                    CooldownPhase.cooling => '${value.$2}s',
                    CooldownPhase.rechecking => 'Re-checking · ${value.$2}s',
                    _ => '',
                  },
                  style: AppTypography.number16.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
            ],
          ),
          CooldownBlocSelector.phase(
            builder: (phase) => Text(
              switch (phase) {
                CooldownPhase.starting => 'Starting…',
                CooldownPhase.rechecking => 'Re-checking',
                CooldownPhase.analyzing => 'Comparing…',
                CooldownPhase.interrupted => 'Paused',
                _ => 'Cooling down',
              },
              style: AppTypography.bold24,
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: AppSpacing.xxs),
          const Text(
            'Take your eyes off the message. Relax your jaw and shoulders, and '
            'keep your face in the circle.',
            style: AppTypography.regular14,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.md),
          Center(
            child: BreathingHalo(
              size: 210,
              color: color,
              child: CooldownBlocSelector.progress(
                builder: (progress) => CameraOrb(
                  size: 168,
                  progress: progress,
                  color: color,
                  onPreviewReady: bloc.previewReady,
                  onPreviewGone: bloc.previewGone,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CooldownBlocSelector(
                  selector: (s) => (s.livePulse, s.hint),
                  builder: (value) => Row(
                    children: [
                      Heartbeat(bpm: value.$1, color: color, size: 22),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        value.$1 == null
                            ? 'Finding your pulse…'
                            : '${value.$1!.round()} bpm',
                        style: value.$1 == null
                            ? AppTypography.medium14
                            : AppTypography.number24,
                      ),
                      const Spacer(),
                      if (value.$2 != null)
                        Flexible(
                          child: Text(
                            value.$2!,
                            style: AppTypography.medium12.copyWith(
                              color: AppColors.warm,
                            ),
                            textAlign: TextAlign.end,
                          ),
                        )
                      else
                        Text(
                          'was ${bloc.original.pulseBpm?.round() ?? '–'}',
                          style: AppTypography.regular12,
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                CooldownBlocSelector.pulseSeries(
                  builder: (series) => PulseChart(
                    series: series,
                    usual: bloc.baseline?.pulseBpm,
                    height: 130,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }
}

class _BeforeAfter extends StatelessWidget {
  const _BeforeAfter();

  @override
  Widget build(BuildContext context) {
    final bloc = CooldownBloc.of(context);
    final recheck = bloc.state.recheck!;
    final before = bloc.original;
    return Column(
      key: const ValueKey('done'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: IconButton(
            onPressed: bloc.edit,
            icon: const Icon(Icons.arrow_back_rounded),
            tooltip: 'Back to editing',
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FadeSlideIn(
                  child: Text(
                    _headline(before, recheck),
                    style: AppTypography.bold24,
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                FadeSlideIn(
                  delay: const Duration(milliseconds: 200),
                  child: BeforeAfterCard(before: before, after: recheck),
                ),
                const SizedBox(height: AppSpacing.md),
                CooldownBlocSelector.pulseSeries(
                  builder: (series) => FadeSlideIn(
                    delay: const Duration(milliseconds: 400),
                    child: AppCard(
                      child: PulseChart(
                        series: series,
                        usual: bloc.baseline?.pulseBpm,
                        height: 110,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                // Cooler is not always calm: say what still reads hot
                // (usually the words themselves).
                if (recheck.result.level != HeatLevel.calm &&
                    recheck.result.reasons.isNotEmpty) ...[
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 500),
                    child: Text(
                      'STILL READS ${recheck.result.level.label.toUpperCase()} BECAUSE',
                      style: AppTypography.medium12,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  ReasonList(reasons: recheck.result.reasons),
                  const SizedBox(height: AppSpacing.sm),
                ],
                const FadeSlideIn(
                  delay: Duration(milliseconds: 600),
                  child: Text(
                    'Still want to send it?',
                    style: AppTypography.semiBold18,
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
              ],
            ),
          ),
        ),
        CooldownBlocSelector.isBusy(
          builder: (isBusy) => OutcomeActions(
            level: recheck.result.level,
            holdMinutes: bloc.settings.holdMinutes,
            isBusy: isBusy,
            onSend: (origin) => bloc.send(origin: origin),
            onHold: bloc.hold,
            onEdit: bloc.edit,
            onDiscard: bloc.discard,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
      ],
    );
  }

  static String _headline(CheckOutcome before, CheckOutcome after) {
    final cooled = after.result.level.rank < before.result.level.rank;
    final pulseDrop = before.pulseBpm != null && after.pulseBpm != null
        ? (before.pulseBpm! - after.pulseBpm!).round()
        : null;
    if (cooled) {
      return 'You cooled off';
    }
    if (pulseDrop != null && pulseDrop >= 3) {
      return 'Cooling, down $pulseDrop bpm';
    }
    return after.result.level == HeatLevel.calm
        ? 'Calm and steady'
        : 'Still a little warm';
  }
}

/// "98 → 84 bpm · expression heat 71 → 12", with the levels.
class BeforeAfterCard extends StatelessWidget {
  final CheckOutcome before;
  final CheckOutcome after;

  const BeforeAfterCard({super.key, required this.before, required this.after});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      accent: AppColors.heat(after.result.level),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                HeatBadge(level: before.result.level, large: true),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                  child: Icon(
                    Icons.arrow_forward_rounded,
                    color: AppColors.textMuted,
                  ),
                ),
                HeatBadge(level: after.result.level, large: true),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          _Row(
            icon: Icons.favorite_rounded,
            label: 'Pulse',
            before: before.pulseBpm?.round(),
            after: after.pulseBpm?.round(),
            unit: 'bpm',
          ),
          const SizedBox(height: AppSpacing.md),
          _Row(
            icon: Icons.face_rounded,
            label: 'Expression heat',
            before: before.expressionHeat,
            after: after.expressionHeat,
            unit: '/100',
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final IconData icon;
  final String label;
  final int? before;
  final int? after;
  final String unit;

  const _Row({
    required this.icon,
    required this.label,
    required this.before,
    required this.after,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    final before = this.before;
    final after = this.after;
    final down = before != null && after != null && after < before;
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.textSecondary),
        const SizedBox(width: AppSpacing.xs),
        Expanded(child: Text(label, style: AppTypography.medium14)),
        // The numbers shrink before they overflow (large system text).
        Flexible(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerRight,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${before ?? '–'}',
                  style: AppTypography.number24.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xs,
                  ),
                  child: Icon(
                    Icons.east_rounded,
                    size: 18,
                    color: down ? AppColors.calm : AppColors.textMuted,
                  ),
                ),
                TweenAnimationBuilder<double>(
                  tween: Tween(
                    begin: (before ?? after ?? 0).toDouble(),
                    end: (after ?? 0).toDouble(),
                  ),
                  duration: AppMotion.reveal,
                  curve: AppMotion.emphasized,
                  builder: (context, value, _) => Text(
                    after == null ? '–' : '${value.round()}',
                    style: AppTypography.number24.copyWith(
                      color: down ? AppColors.calm : AppColors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.xxs),
                Text(unit, style: AppTypography.regular12),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Failed extends StatelessWidget {
  const _Failed();

  @override
  Widget build(BuildContext context) {
    final bloc = CooldownBloc.of(context);
    return CooldownBlocSelector.failure(
      builder: (failure) => FillScrollView(
        child: Column(
          key: const ValueKey('failed'),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Spacer(),
            const Icon(
              Icons.water_drop_outlined,
              size: 44,
              color: AppColors.warm,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              failure?.title ?? 'The cool-down stopped',
              style: AppTypography.bold20,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              failure?.message ?? 'Please try again.',
              style: AppTypography.regular14,
              textAlign: TextAlign.center,
            ),
            const Spacer(),
            if (failure?.canRetry ?? true) ...[
              FilledButton(
                onPressed: bloc.start,
                child: const Text('Try again'),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
            OutlinedButton(
              onPressed: () => context.pop(),
              child: const Text('Back to my message'),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
  }
}
