import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../bloc/draft_bloc.dart';
import '../../../core/app_colors.dart';
import '../../../core/app_dimens.dart';
import '../../../core/app_typography.dart';
import '../../../extension/context.dart';
import '../../../utils/app_haptics.dart';
import '../../../widgets/app_card.dart';
import '../../../widgets/camera_orb.dart';
import '../../../widgets/heartbeat.dart';
import '../../../widgets/heat_glow_background.dart';
import '../result/result_page.dart';
import 'bloc/check_bloc.dart';
import 'bloc/check_state.dart';
import '../../../widgets/fill_scroll_view.dart';

class CheckBody extends StatelessWidget {
  const CheckBody({super.key});

  @override
  Widget build(BuildContext context) {
    final bloc = CheckBloc.of(context);
    return BlocListener<CheckBloc, CheckState>(
      listenWhen: (a, b) => a.phase != b.phase,
      listener: (context, state) {
        final outcome = state.outcome;
        if (state.phase == CheckPhase.done && outcome != null) {
          AppHaptics.result(outcome.result.level);
          context.pushReplacementNamed(
            ResultPage.ROUTE_NAME,
            arguments: outcome,
          );
        }
      },
      child: PopScope(
        onPopInvokedWithResult: (didPop, _) {
          if (didPop) {
            unawaited(bloc.cancel());
          }
        },
        child: HeatGlowBackground(
          intensity: 0.3,
          child: SafeArea(
            child: CheckBlocSelector.phase(
              builder: (phase) => phase == CheckPhase.failed
                  ? const _Failed()
                  : const _Measuring(),
            ),
          ),
        ),
      ),
    );
  }
}

class _Measuring extends StatelessWidget {
  const _Measuring();

  @override
  Widget build(BuildContext context) {
    final bloc = CheckBloc.of(context);
    final text = bloc.text;
    final recipient = bloc.recipient;
    return Padding(
      padding: AppSpacing.pagePadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => context.maybePop(),
                icon: const Icon(Icons.close_rounded),
                tooltip: 'Cancel check',
              ),
              const Spacer(),
              CheckBlocSelector(
                selector: (s) => (s.phase, s.secondsLeft),
                builder: (value) => Text(
                  value.$1 == CheckPhase.measuring ? '${value.$2}s' : '',
                  style: AppTypography.number16.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Center(
            child: CheckBlocSelector.progress(
              builder: (progress) => CameraOrb(
                size: (MediaQuery.sizeOf(context).height * 0.3).clamp(160, 236),
                progress: progress,
                onPreviewReady: bloc.previewReady,
                onPreviewGone: bloc.previewGone,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          CheckBlocSelector(
            selector: (s) => (s.phase, s.livePulse),
            builder: (value) => Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Heartbeat(bpm: value.$2, color: AppColors.heatedSoft),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  switch (value.$1) {
                    CheckPhase.starting => 'Starting the camera…',
                    CheckPhase.analyzing ||
                    CheckPhase.done => 'Reading the signals…',
                    CheckPhase.interrupted =>
                      'Paused. It restarts when '
                          "you're back.",
                    _ =>
                      value.$2 == null
                          ? 'Finding your pulse…'
                          : '${value.$2!.round()} bpm',
                  },
                  style: value.$2 != null && value.$1 == CheckPhase.measuring
                      ? AppTypography.number24
                      : AppTypography.medium16.copyWith(
                          color: AppColors.textSecondary,
                        ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xxs),
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 22),
            child: CheckBlocSelector.hint(
              builder: (hint) => AnimatedSwitcher(
                duration: AppMotion.fast,
                child: Text(
                  hint ?? '',
                  key: ValueKey(hint),
                  style: AppTypography.medium14.copyWith(color: AppColors.warm),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          const Text(
            'REREAD YOUR MESSAGE WHILE WE CHECK',
            style: AppTypography.medium12,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xs),
          Expanded(
            child: AppCard(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (recipient != null) ...[
                      Text('To $recipient', style: AppTypography.medium12),
                      const SizedBox(height: AppSpacing.xs),
                    ],
                    Text(text, style: AppTypography.regular16),
                  ],
                ),
              ),
            ),
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
    final bloc = CheckBloc.of(context);
    return CheckBlocSelector(
      selector: (s) => (s.failure, s.couldNotSeeFace),
      builder: (value) {
        final failure = value.$1;
        final title = failure?.title ?? "Couldn't see your face clearly";
        final message =
            failure?.message ??
            'Keep your face inside the circle, with even light, and try '
                'again.';
        final canRetry = failure?.canRetry ?? true;
        return Padding(
          padding: AppSpacing.pagePadding,
          child: FillScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    onPressed: () => context.maybePop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ),
                const Spacer(),
                const Icon(
                  Icons.water_drop_outlined,
                  size: 44,
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
                if (canRetry) ...[
                  FilledButton(
                    onPressed: bloc.start,
                    child: const Text('Try again'),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                ],
                OutlinedButton(
                  onPressed: () async {
                    final navigator = context.navigator;
                    final draft = DraftBloc.of(context);
                    final sent = await bloc.sendUnchecked();
                    if (sent) {
                      draft.clear();
                      navigator.pop();
                    }
                  },
                  child: const Text('Send without a check'),
                ),
                const SizedBox(height: AppSpacing.md),
              ],
            ),
          ),
        );
      },
    );
  }
}
