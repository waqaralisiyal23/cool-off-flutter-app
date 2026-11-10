import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/app_colors.dart';
import '../../../core/app_dimens.dart';
import '../../../core/app_typography.dart';
import '../../../engine/heat_copy.dart';
import '../../../engine/heat_engine.dart';
import '../../../engine/text_heat.dart';
import '../../../extension/context.dart';
import '../../../models/check_outcome.dart';
import '../../../models/enums/heat_level.dart';
import '../../../widgets/app_card.dart';
import '../../../widgets/fade_slide_in.dart';
import '../../../widgets/heat_badge.dart';
import '../../../widgets/heat_glow_background.dart';
import '../../../widgets/heat_ring.dart';
import '../../../widgets/outcome_actions.dart';
import 'bloc/result_bloc.dart';
import 'bloc/result_state.dart';
import 'outcome_navigation.dart';

class ResultBody extends StatelessWidget {
  const ResultBody({super.key});

  @override
  Widget build(BuildContext context) {
    final bloc = ResultBloc.of(context);
    final outcome = bloc.outcome;
    final level = outcome.result.level;
    return MultiBlocListener(
      listeners: [
        BlocListener<ResultBloc, ResultState>(
          listenWhen: (a, b) => a.choice != b.choice && b.choice != null,
          listener: (context, state) => navigateAfterChoice(
            context,
            choice: state.choice!,
            outcome: outcome,
            heldUntil: state.heldUntil,
          ),
        ),
        BlocListener<ResultBloc, ResultState>(
          listenWhen: (a, b) => a.error != b.error && b.error != null,
          listener: (context, state) =>
              ScaffoldMessenger.of(context)
                  .showSnackBar(SnackBar(content: Text(state.error!))),
        ),
      ],
      child: PopScope(
        canPop: false,
        // Back = Edit: the draft is still there.
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) {
            bloc.edit();
          }
        },
        child: HeatGlowBackground(
          color: AppColors.heat(level),
          intensity: level.when(
            calm: () => 0.4,
            warm: () => 0.6,
            heated: () => 0.9,
          ),
          child: SafeArea(
            child: Padding(
              padding: AppSpacing.pagePadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      onPressed: () => context.maybePop(),
                      icon: const Icon(Icons.arrow_back_rounded),
                      tooltip: 'Back to editing',
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Center(child: HeatGauge(result: outcome.result)),
                          const SizedBox(height: AppSpacing.lg),
                          FadeSlideIn(
                            delay: const Duration(milliseconds: 500),
                            child: Column(
                              children: [
                                Text(
                                  HeatCopy.headline(level),
                                  style: AppTypography.bold24,
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: AppSpacing.xxs),
                                Text(
                                  HeatCopy.suggestion(level),
                                  style: AppTypography.regular14,
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          FadeSlideIn(
                            delay: const Duration(milliseconds: 700),
                            child: SignalTiles(outcome: outcome),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          ReasonList(reasons: outcome.result.reasons),
                          const SizedBox(height: AppSpacing.md),
                        ],
                      ),
                    ),
                  ),
                  ResultBlocSelector.isBusy(
                    builder: (isBusy) => OutcomeActions(
                      level: level,
                      holdMinutes: bloc.settings.holdMinutes,
                      isBusy: isBusy,
                      onSend: (origin) => bloc.send(origin: origin),
                      onHold: bloc.hold,
                      onCoolDown: bloc.coolDown,
                      onEdit: bloc.edit,
                      onDiscard: bloc.discard,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The heat gauge: the ring fills to the score while the level appears.
class HeatGauge extends StatelessWidget {
  final HeatResult result;
  final double size;

  const HeatGauge({super.key, required this.result, this.size = 210});

  @override
  Widget build(BuildContext context) {
    final color = AppColors.heat(result.level);
    final fill = (result.score / HeatEngine.maxScore).clamp(0.1, 1.0);
    return Semantics(
      label: 'Result: ${result.level.label}',
      header: true,
      child: ExcludeSemantics(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: AppMotion.reveal,
          curve: AppMotion.emphasized,
          builder: (context, t, _) => HeatRing(
            size: size,
            progress: fill * t,
            color: color,
            strokeWidth: 14,
            duration: Duration.zero,
            child: Opacity(
              opacity: t,
              child: Transform.scale(
                scale: 0.8 + 0.2 * t,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(heatIcon(result.level), size: 40, color: color),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        result.level.label,
                        style: AppTypography.extraBold32.copyWith(color: color),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Pulse vs usual, and expression heat, as two tiles.
class SignalTiles extends StatelessWidget {
  final CheckOutcome outcome;

  const SignalTiles({super.key, required this.outcome});

  @override
  Widget build(BuildContext context) {
    final pulse = outcome.pulseBpm;
    final usual = outcome.baselinePulseBpm;
    final delta = pulse != null && usual != null
        ? (pulse - usual).round()
        : null;
    final expression = outcome.expressionHeat;
    return Row(
      children: [
        Expanded(
          child: _Tile(
            icon: Icons.favorite_rounded,
            label: 'Pulse',
            value: pulse == null ? '–' : '${pulse.round()}',
            unit: pulse == null ? null : 'bpm',
            detail: delta == null
                ? (pulse == null ? 'Not read' : 'No baseline yet')
                : '${delta >= 0 ? '+' : ''}$delta vs your usual',
            color: AppColors.heat(_levelFor(outcome.result.pulsePoints)),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _Tile(
            icon: Icons.face_rounded,
            label: 'Expression heat',
            value: expression == null ? '–' : '$expression',
            unit: expression == null ? null : '/100',
            detail: 'above your resting face',
            color: AppColors.heat(_levelFor(outcome.result.angerPoints)),
          ),
        ),
      ],
    );
  }

  static HeatLevel _levelFor(int points) => switch (points) {
    0 => HeatLevel.calm,
    1 => HeatLevel.warm,
    _ => HeatLevel.heated,
  };
}

class _Tile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String? unit;
  final String detail;
  final Color color;

  const _Tile({
    required this.icon,
    required this.label,
    required this.value,
    required this.unit,
    required this.detail,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: AppSpacing.xxs),
              Flexible(
                child: Text(
                  label.toUpperCase(),
                  style: AppTypography.medium12,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(value, style: AppTypography.number40),
                if (unit != null) ...[
                  const SizedBox(width: AppSpacing.xxs),
                  Text(unit!, style: AppTypography.regular12),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(detail, style: AppTypography.regular12),
        ],
      ),
    );
  }
}

/// The reasons, strongest first, appearing one after another.
class ReasonList extends StatelessWidget {
  final List<HeatReason> reasons;

  const ReasonList({super.key, required this.reasons});

  @override
  Widget build(BuildContext context) {
    if (reasons.isEmpty) {
      return const FadeSlideIn(
        delay: Duration(milliseconds: 900),
        child: Text(
          'Nothing stood out: pulse near your usual, a relaxed face, calm words.',
          style: AppTypography.regular14,
          textAlign: TextAlign.center,
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < reasons.length; i++)
          FadeSlideIn(
            delay: Duration(milliseconds: 900 + 120 * i),
            child: Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: Row(
                children: [
                  Icon(
                    _icon(reasons[i]),
                    size: 18,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      HeatCopy.reason(reasons[i]),
                      style: AppTypography.medium14,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  static IconData _icon(HeatReason reason) => switch (reason) {
    PulseAboveUsual() => Icons.favorite_border_rounded,
    AngerRead() => Icons.face_retouching_off_rounded,
    TextRead(:final signal) => switch (signal) {
      TextHeatSignal.caps => Icons.text_increase_rounded,
      TextHeatSignal.punctuation => Icons.priority_high_rounded,
      TextHeatSignal.harshWords => Icons.report_gmailerrorred_rounded,
      TextHeatSignal.absolutes => Icons.all_inclusive_rounded,
    },
    PulseUnavailable() => Icons.info_outline_rounded,
  };
}
