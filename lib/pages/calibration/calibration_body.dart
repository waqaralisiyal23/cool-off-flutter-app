import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../bloc/app_preferences_bloc.dart';
import '../../core/app_colors.dart';
import '../../core/app_dimens.dart';
import '../../core/app_typography.dart';
import '../../engine/baseline_calculator.dart';
import '../../extension/context.dart';
import '../../utils/app_haptics.dart';
import '../../widgets/camera_orb.dart';
import '../../widgets/heartbeat.dart';
import '../../widgets/heat_glow_background.dart';
import 'bloc/calibration_bloc.dart';
import 'bloc/calibration_state.dart';
import '../../widgets/fill_scroll_view.dart';

class CalibrationBody extends StatelessWidget {
  final bool fromOnboarding;

  const CalibrationBody({super.key, required this.fromOnboarding});

  @override
  Widget build(BuildContext context) {
    return BlocListener<CalibrationBloc, CalibrationState>(
      listenWhen: (a, b) => a.phase != b.phase,
      listener: (context, state) {
        if (state.phase == CalibrationPhase.done) {
          AppHaptics.success();
        }
      },
      child: HeatGlowBackground(
        intensity: 0.35,
        child: SafeArea(
          top: false,
          child: Padding(
            padding: AppSpacing.pagePadding,
            child: CalibrationBlocSelector.phase(
              builder: (phase) => AnimatedSwitcher(
                duration: AppMotion.medium,
                child: switch (phase) {
                  CalibrationPhase.intro => const FillScrollView(
                    key: ValueKey('intro'),
                    child: _Intro(),
                  ),
                  CalibrationPhase.starting ||
                  CalibrationPhase.measuring ||
                  CalibrationPhase.saving => const FillScrollView(
                    key: ValueKey('measuring'),
                    child: _Measuring(),
                  ),
                  CalibrationPhase.done => FillScrollView(
                    key: const ValueKey('done'),
                    child: _Done(fromOnboarding: fromOnboarding),
                  ),
                  CalibrationPhase.failed => const FillScrollView(
                    key: ValueKey('failed'),
                    child: _Failed(),
                  ),
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Intro extends StatelessWidget {
  const _Intro();

  @override
  Widget build(BuildContext context) {
    final bloc = CalibrationBloc.of(context);
    return Column(
      key: const ValueKey('intro'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Find your calm', style: AppTypography.bold24),
        const SizedBox(height: AppSpacing.xs),
        const Text(
          'A 30-second reading while you are relaxed. Every check compares '
          'against it, so Cool Off knows what "usual" looks like for you.',
          style: AppTypography.regular14,
        ),
        CalibrationBlocSelector.wasInterrupted(
          builder: (interrupted) => interrupted
              ? Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.md),
                  child: Text(
                    'The reading stopped when you left the app. '
                    "Let's start it again.",
                    style: AppTypography.medium14.copyWith(
                      color: AppColors.warm,
                    ),
                  ),
                )
              : const SizedBox.shrink(),
        ),
        const SizedBox(height: AppSpacing.lg),
        const _Tip(
          icon: Icons.chair_rounded,
          text: 'Sit comfortably and still',
        ),
        const _Tip(
          icon: Icons.light_mode_rounded,
          text: 'Even light on your face; no screen flicker behind you',
        ),
        const _Tip(
          icon: Icons.face_rounded,
          text: 'Hold the phone at eye level, face inside the circle',
        ),
        const _Tip(
          icon: Icons.do_not_disturb_on_rounded,
          text: 'No talking or chewing for 30 seconds',
        ),
        const Spacer(),
        FilledButton.icon(
          onPressed: () {
            AppHaptics.tap();
            bloc.start();
          },
          icon: const Icon(Icons.play_arrow_rounded),
          label: const Text('Start the 30-second reading'),
        ),
        const SizedBox(height: AppSpacing.md),
      ],
    );
  }
}

class _Tip extends StatelessWidget {
  final IconData icon;
  final String text;

  const _Tip({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(text, style: AppTypography.medium14)),
        ],
      ),
    );
  }
}

class _Measuring extends StatelessWidget {
  const _Measuring();

  @override
  Widget build(BuildContext context) {
    final bloc = CalibrationBloc.of(context);
    return Column(
      key: const ValueKey('measuring'),
      children: [
        const SizedBox(height: AppSpacing.lg),
        CalibrationBlocSelector.progress(
          builder: (progress) => CameraOrb(
            size: 280,
            progress: progress,
            onPreviewReady: bloc.previewReady,
            onPreviewGone: bloc.previewGone,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        CalibrationBlocSelector.livePulse(
          builder: (pulse) => Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Heartbeat(bpm: pulse, color: AppColors.calm),
              const SizedBox(width: AppSpacing.xs),
              Text(
                pulse == null ? 'Finding your pulse…' : '${pulse.round()} bpm',
                style: pulse == null
                    ? AppTypography.medium16.copyWith(
                        color: AppColors.textSecondary,
                      )
                    : AppTypography.number24,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        CalibrationBlocSelector(
          selector: (s) => (s.phase, s.hint),
          builder: (value) => AnimatedSwitcher(
            duration: AppMotion.fast,
            child: Text(
              switch (value.$1) {
                CalibrationPhase.starting => 'Starting the camera…',
                CalibrationPhase.saving => 'Saving…',
                _ => value.$2 ?? 'Breathe normally and relax',
              },
              key: ValueKey(value),
              style: AppTypography.regular14.copyWith(
                color: value.$2 == null
                    ? AppColors.textSecondary
                    : AppColors.warm,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        const Spacer(),
        TextButton(onPressed: bloc.cancel, child: const Text('Cancel')),
        const SizedBox(height: AppSpacing.md),
      ],
    );
  }
}

class _Done extends StatelessWidget {
  final bool fromOnboarding;

  const _Done({required this.fromOnboarding});

  @override
  Widget build(BuildContext context) {
    return CalibrationBlocSelector.result(
      builder: (result) => Column(
        key: const ValueKey('done'),
        children: [
          const Spacer(),
          const Icon(Icons.ac_unit_rounded, size: 40, color: AppColors.calm),
          const SizedBox(height: AppSpacing.md),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: result?.pulseBpm ?? 0),
            duration: AppMotion.reveal,
            curve: AppMotion.emphasized,
            builder: (context, value, _) =>
                Text('${value.round()}', style: AppTypography.number64),
          ),
          const Text('bpm, your usual', style: AppTypography.medium16),
          const SizedBox(height: AppSpacing.md),
          const Text(
            'Checks compare against this. You can redo it any time in '
            'Settings, for example if the light was poor.',
            style: AppTypography.regular14,
            textAlign: TextAlign.center,
          ),
          const Spacer(),
          FilledButton(
            onPressed: () {
              AppHaptics.tap();
              if (fromOnboarding) {
                AppPreferencesBloc.of(context).completeOnboarding();
              } else {
                context.pop();
              }
            },
            child: Text(fromOnboarding ? "Let's go" : 'Done'),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }
}

class _Failed extends StatelessWidget {
  const _Failed();

  @override
  Widget build(BuildContext context) {
    final bloc = CalibrationBloc.of(context);
    return CalibrationBlocSelector(
      selector: (s) => (s.failure, s.baselineFailure),
      builder: (value) {
        final failure = value.$1;
        final title =
            failure?.title ??
            switch (value.$2) {
              BaselineFailure.notEnoughFace => "Couldn't see your face clearly",
              _ => "Couldn't get a steady pulse",
            };
        final message =
            failure?.message ??
            'Try sitting still with more even light on your face, and keep '
                'your face inside the circle.';
        final canRetry = failure?.canRetry ?? true;
        return Column(
          key: const ValueKey('failed'),
          children: [
            const Spacer(),
            const Icon(
              Icons.water_drop_outlined,
              size: 40,
              color: AppColors.warm,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              title,
              style: AppTypography.bold20,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              message,
              style: AppTypography.regular14,
              textAlign: TextAlign.center,
            ),
            const Spacer(),
            if (canRetry)
              FilledButton(
                onPressed: bloc.start,
                child: const Text('Try again'),
              ),
            const SizedBox(height: AppSpacing.md),
          ],
        );
      },
    );
  }
}
