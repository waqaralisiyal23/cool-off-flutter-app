import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../bloc/baseline_bloc.dart';
import '../../../bloc/draft_bloc.dart';
import '../../../bloc/states/draft_state.dart';
import '../../../core/app_colors.dart';
import '../../../core/app_dimens.dart';
import '../../../core/app_typography.dart';
import '../../../engine/text_heat.dart';
import '../../../extension/context.dart';
import '../../../models/data/baseline_data.dart';
import '../../../models/enums/reflection_answer.dart';
import '../../../utils/app_haptics.dart';
import '../../../widgets/app_card.dart';
import '../../../widgets/fade_slide_in.dart';
import '../../../widgets/heartbeat.dart';
import '../check/check_page.dart';
import 'bloc/write_bloc.dart';
import 'bloc/write_state.dart';

/// Home: write or paste the message, then Check & Send.
class WriteBody extends StatelessWidget {
  const WriteBody({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<WriteBloc, WriteState>(
      listenWhen: (a, b) =>
          b.lastAnswerNote != null && a.lastAnswerNote != b.lastAnswerNote,
      listener: (context, state) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(state.lastAnswerNote!)));
        WriteBloc.of(context).clearNote();
      },
      child: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.page,
            AppSpacing.md,
            AppSpacing.page,
            AppSpacing.xl,
          ),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          children: const [
            _Header(),
            SizedBox(height: AppSpacing.lg),
            _Checkins(),
            _ComposeCard(),
            SizedBox(height: AppSpacing.md),
            _CheckButton(),
            SizedBox(height: AppSpacing.sm),
            _Footnote(),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Cool Off', style: AppTypography.extraBold32),
              SizedBox(height: AppSpacing.xxs),
              Text(
                'Check your pulse before you hit send.',
                style: AppTypography.regular14,
              ),
            ],
          ),
        ),
        BlocSelector<BaselineBloc, BaselineData?, double?>(
          selector: (baseline) => baseline?.pulseBpm,
          builder: (context, usual) => usual == null
              ? const SizedBox.shrink()
              : Semantics(
                  label: 'Your usual pulse: ${usual.round()} beats per minute',
                  excludeSemantics: true,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Heartbeat(bpm: usual, color: AppColors.calm, size: 16),
                        const SizedBox(width: AppSpacing.xxs),
                        Text('${usual.round()}', style: AppTypography.number16),
                        const SizedBox(width: 2),
                        const Text('usual', style: AppTypography.regular12),
                      ],
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}

class _Checkins extends StatelessWidget {
  const _Checkins();

  @override
  Widget build(BuildContext context) {
    return WriteBlocSelector.checkins(
      builder: (checkins) => AnimatedSize(
        duration: AppMotion.medium,
        curve: AppMotion.standard,
        child: Column(
          children: [
            for (final checkin in checkins)
              Padding(
                key: ValueKey(checkin.checkId),
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: FadeSlideIn(child: _CheckinCard(checkin: checkin)),
              ),
          ],
        ),
      ),
    );
  }
}

class _CheckinCard extends StatelessWidget {
  final PendingCheckin checkin;

  const _CheckinCard({required this.checkin});

  @override
  Widget build(BuildContext context) {
    final bloc = WriteBloc.of(context);
    final when = DateFormat('EEE, h:mm a').format(checkin.sentAt);
    final to = checkin.recipient == null ? '' : ' to ${checkin.recipient}';
    return AppCard(
      accent: AppColors.warm,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.wb_twilight_rounded,
                size: 18,
                color: AppColors.warm,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                'MORNING CHECK-IN',
                style: AppTypography.medium12.copyWith(color: AppColors.warm),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '$when you sent a message$to while heated.',
            style: AppTypography.medium14,
          ),
          if (checkin.text != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              '"${checkin.text}"',
              style: AppTypography.regular14.copyWith(
                fontStyle: FontStyle.italic,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          const Text('Glad you sent it?', style: AppTypography.semiBold18),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    AppHaptics.tap();
                    bloc.answer(checkin, ReflectionAnswer.glad);
                  },
                  child: const Text('👍  Glad I did'),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    AppHaptics.tap();
                    bloc.answer(checkin, ReflectionAnswer.regret);
                  },
                  child: const Text('👎  Regret it'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// The message and the optional "to whom". The controllers follow the
/// draft: typing updates it, and a reload (cleared after sending, filled
/// from a held message) updates them.
class _ComposeCard extends StatefulWidget {
  const _ComposeCard();

  @override
  State<_ComposeCard> createState() => _ComposeCardState();
}

class _ComposeCardState extends State<_ComposeCard> {
  late final DraftBloc _draft = DraftBloc.of(context);
  late final TextEditingController _text = TextEditingController(
    text: _draft.state.text,
  );
  late final TextEditingController _recipient = TextEditingController(
    text: _draft.state.recipient,
  );

  @override
  void dispose() {
    _text.dispose();
    _recipient.dispose();
    super.dispose();
  }

  Future<void> _paste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final pasted = data?.text;
    if (pasted == null || pasted.isEmpty) {
      return;
    }
    AppHaptics.tap();
    final selection = _text.selection;
    final current = _text.text;
    final start = selection.isValid ? selection.start : current.length;
    final end = selection.isValid ? selection.end : current.length;
    final next = current.replaceRange(start, end, pasted);
    _text.value = TextEditingValue(
      text: next,
      selection: TextSelection.collapsed(offset: start + pasted.length),
    );
    _draft.setText(next);
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<DraftBloc, DraftState>(
      listenWhen: (a, b) => a.revision != b.revision,
      listener: (context, draft) {
        _text.text = draft.text;
        _recipient.text = draft.recipient;
      },
      child: AppCard(
        padding: const EdgeInsets.all(AppSpacing.xs),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _recipient,
              onChanged: _draft.setRecipient,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              style: AppTypography.medium14,
              decoration: const InputDecoration(
                hintText: 'To (optional): Sam, the team chat…',
                prefixIcon: Icon(Icons.person_outline_rounded, size: 20),
                fillColor: AppColors.transparent,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
              ),
            ),
            const Divider(),
            TextField(
              controller: _text,
              onChanged: _draft.setText,
              minLines: 6,
              maxLines: 12,
              textCapitalization: TextCapitalization.sentences,
              keyboardType: TextInputType.multiline,
              style: AppTypography.regular16,
              decoration: const InputDecoration(
                hintText: 'Write or paste the message you want to send…',
                fillColor: AppColors.transparent,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xs,
                0,
                AppSpacing.xxs,
                AppSpacing.xxs,
              ),
              child: Row(
                children: [
                  const Expanded(child: _TextTemperature()),
                  DraftBlocSelector<bool>(
                    selector: (d) => d.text.isEmpty,
                    builder: (empty) => empty
                        ? TextButton.icon(
                            onPressed: _paste,
                            icon: const Icon(
                              Icons.content_paste_rounded,
                              size: 18,
                            ),
                            label: const Text('Paste'),
                          )
                        : TextButton.icon(
                            onPressed: () {
                              AppHaptics.tap();
                              _draft.load(
                                text: '',
                                recipient: _draft.state.recipient,
                              );
                            },
                            icon: const Icon(
                              Icons.backspace_outlined,
                              size: 18,
                            ),
                            label: const Text('Clear'),
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A tiny live meter: how hot the words themselves read.
class _TextTemperature extends StatelessWidget {
  const _TextTemperature();

  @override
  Widget build(BuildContext context) {
    return DraftBlocSelector<TextHeatResult>(
      selector: (d) => d.textHeat,
      builder: (heat) {
        final color = switch (heat.points) {
          0 => AppColors.calm,
          1 => AppColors.warm,
          _ => AppColors.heated,
        };
        final label = switch (heat.points) {
          0 => 'Words read calm',
          1 => 'Words: ${_signals(heat)}',
          _ => 'Words read hot: ${_signals(heat)}',
        };
        return Row(
          children: [
            for (var i = 0; i < 3; i++)
              AnimatedContainer(
                duration: AppMotion.medium,
                margin: const EdgeInsets.only(right: 3),
                width: 14,
                height: 6,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(3),
                  color: i <= heat.points ? color : AppColors.border,
                ),
              ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: AnimatedSwitcher(
                duration: AppMotion.fast,
                // Keep the label against the bars while it changes.
                layoutBuilder: (current, previous) => Stack(
                  alignment: Alignment.centerLeft,
                  children: [...previous, ?current],
                ),
                child: Text(
                  label,
                  key: ValueKey(label),
                  style: AppTypography.regular12.copyWith(color: color),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  static String _signals(TextHeatResult heat) => [
    for (final signal in TextHeatSignal.values)
      if (heat.signals.contains(signal))
        switch (signal) {
          TextHeatSignal.caps => 'CAPS',
          TextHeatSignal.punctuation => '!!!',
          TextHeatSignal.harshWords => 'harsh words',
          TextHeatSignal.absolutes => 'always/never',
        },
  ].join(', ');
}

class _CheckButton extends StatelessWidget {
  const _CheckButton();

  @override
  Widget build(BuildContext context) {
    return DraftBlocSelector<bool>(
      selector: (d) => d.canCheck,
      builder: (canCheck) => FilledButton.icon(
        onPressed: canCheck
            ? () {
                AppHaptics.light();
                FocusManager.instance.primaryFocus?.unfocus();
                unawaited(context.pushNamed(CheckPage.ROUTE_NAME));
              }
            : null,
        icon: const Icon(Icons.favorite_rounded),
        label: const Text('Check & Send'),
      ),
    );
  }
}

class _Footnote extends StatelessWidget {
  const _Footnote();

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.lock_outline_rounded, size: 14, color: AppColors.textMuted),
        SizedBox(width: AppSpacing.xxs),
        Text(
          '20-second camera check · your message stays on this phone',
          style: AppTypography.regular12,
        ),
      ],
    );
  }
}
