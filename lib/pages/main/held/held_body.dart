import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../bloc/draft_bloc.dart';
import '../../../bloc/notification_access_bloc.dart';
import '../../../bloc/settings_bloc.dart';
import '../../../core/app_colors.dart';
import '../../../core/app_dimens.dart';
import '../../../core/app_typography.dart';
import '../../../extension/context.dart';
import '../../../models/data/message_data.dart';
import '../../../utils/app_haptics.dart';
import '../../../widgets/app_card.dart';
import '../../../widgets/fade_slide_in.dart';
import '../../../widgets/heat_ring.dart';
import '../tabs/bloc/tabs_bloc.dart';
import 'bloc/held_bloc.dart';
import 'bloc/held_state.dart';

class HeldBody extends StatelessWidget {
  const HeldBody({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<HeldBloc, HeldState>(
      listenWhen: (a, b) => b.error != null && a.error != b.error,
      listener: (context, state) =>
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(state.error!))),
      child: SafeArea(
        bottom: false,
        child: HeldBlocSelector.messages(
          builder: (messages) {
            if (messages == null) {
              return const Center(child: CircularProgressIndicator());
            }
            return CustomScrollView(
              slivers: [
                const SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                    AppSpacing.page,
                    AppSpacing.md,
                    AppSpacing.page,
                    AppSpacing.md,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('On hold', style: AppTypography.extraBold32),
                        SizedBox(height: AppSpacing.xxs),
                        Text(
                          'Messages you chose to sleep on, for a few minutes.',
                          style: AppTypography.regular14,
                        ),
                      ],
                    ),
                  ),
                ),
                if (messages.isNotEmpty)
                  const SliverPadding(
                    padding: EdgeInsets.fromLTRB(
                      AppSpacing.page,
                      0,
                      AppSpacing.page,
                      AppSpacing.sm,
                    ),
                    sliver: SliverToBoxAdapter(
                      child: _NotificationsOffBanner(),
                    ),
                  ),
                if (messages.isEmpty)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: _Empty(),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.page,
                      0,
                      AppSpacing.page,
                      AppSpacing.xl,
                    ),
                    sliver: SliverList.separated(
                      itemCount: messages.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: AppSpacing.sm),
                      itemBuilder: (context, i) => FadeSlideIn(
                        key: ValueKey(messages[i].id),
                        delay: Duration(milliseconds: 60 * i),
                        child: _HeldCard(message: messages[i]),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Held messages rely on a notification; say so when they are off.
class _NotificationsOffBanner extends StatelessWidget {
  const _NotificationsOffBanner();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NotificationAccessBloc, bool?>(
      builder: (context, allowed) => allowed != false
          ? const SizedBox.shrink()
          : AppCard(
              accent: AppColors.warm,
              child: Row(
                children: [
                  const Icon(
                    Icons.notifications_off_outlined,
                    color: AppColors.warm,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  const Expanded(
                    child: Text(
                      "Notifications are off, so we can't tell you when these "
                      'are ready.',
                      style: AppTypography.regular14,
                    ),
                  ),
                  TextButton(
                    onPressed: NotificationAccessBloc.of(context).enable,
                    child: const Text('Turn on'),
                  ),
                ],
              ),
            ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: AppSpacing.pagePadding,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withValues(alpha: 0.1),
            ),
            child: const Icon(
              Icons.ac_unit_rounded,
              size: 44,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          const Text('Nothing on hold', style: AppTypography.bold20),
          const SizedBox(height: AppSpacing.xs),
          const Text(
            'When a check reads heated, you can hold the message here. '
            "We'll tell you when it's ready, so you can decide with a cooler head.",
            style: AppTypography.regular14,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }
}

/// One held message, with a live countdown ring that glows when ready.
class _HeldCard extends StatefulWidget {
  final MessageData message;

  const _HeldCard({required this.message});

  @override
  State<_HeldCard> createState() => _HeldCardState();
}

class _HeldCardState extends State<_HeldCard> {
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final message = widget.message;
    final until = message.holdUntil?.toLocal() ?? DateTime.now();
    final start = message.createdAt.toLocal();
    final total = until.difference(start).inMilliseconds;
    final left = until.difference(DateTime.now());
    final ready = left.isNegative || left == Duration.zero;
    if (ready) {
      _tick?.cancel();
    }
    final progress = total <= 0 ? 1.0 : 1 - left.inMilliseconds / total;
    final keepText = SettingsBloc.of(context).state?.keepMessageText ?? false;
    final bloc = HeldBloc.of(context);

    return AppCard(
      accent: ready ? AppColors.calm : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              HeatRing(
                size: 60,
                strokeWidth: 5,
                progress: progress.clamp(0, 1),
                color: ready ? AppColors.calm : AppColors.warm,
                duration: const Duration(milliseconds: 900),
                child: Icon(
                  ready ? Icons.check_rounded : Icons.hourglass_top_rounded,
                  size: 20,
                  color: ready ? AppColors.calm : AppColors.warm,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ready ? 'READY' : '${_format(left)} LEFT',
                      style: AppTypography.medium12.copyWith(
                        color: ready ? AppColors.calm : AppColors.warm,
                      ),
                    ),
                    if (message.recipientLabel != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        'To ${message.recipientLabel}',
                        style: AppTypography.semiBold14,
                      ),
                    ],
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      message.body ?? '',
                      style: AppTypography.regular14,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: Builder(
                  builder: (buttonContext) => FilledButton.icon(
                    style: ready
                        ? null
                        : FilledButton.styleFrom(
                            backgroundColor: AppColors.surfaceRaised,
                            foregroundColor: AppColors.textPrimary,
                          ),
                    onPressed: () async {
                      AppHaptics.tap();
                      final box =
                          buttonContext.findRenderObject() as RenderBox?;
                      final origin = box == null
                          ? null
                          : box.localToGlobal(Offset.zero) & box.size;
                      if (!ready && !await _confirmEarly(context)) {
                        return;
                      }
                      await bloc.send(
                        message,
                        keepText: keepText,
                        origin: origin,
                      );
                    },
                    icon: const Icon(Icons.send_rounded, size: 18),
                    label: Text(ready ? 'Send' : 'Send now'),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              IconButton(
                tooltip: 'Edit',
                onPressed: () {
                  AppHaptics.tap();
                  DraftBloc.of(context).load(
                    text: message.body ?? '',
                    recipient: message.recipientLabel,
                  );
                  TabsBloc.of(context).select(MainTab.write);
                  unawaited(bloc.takeForEditing(message, keepText: keepText));
                },
                icon: const Icon(Icons.edit_outlined),
              ),
              IconButton(
                tooltip: 'Delete',
                onPressed: () async {
                  AppHaptics.tap();
                  if (await _confirmDelete(context)) {
                    await bloc.delete(message, keepText: keepText);
                  }
                },
                icon: const Icon(Icons.delete_outline_rounded),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _format(Duration left) {
    final minutes = left.inMinutes;
    final seconds = left.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  static Future<bool> _confirmEarly(BuildContext context) async =>
      await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Send before the hold ends?'),
          content: const Text(
            'A few more minutes can change how a message reads.',
          ),
          actions: [
            TextButton(
              onPressed: () => context.pop(false),
              child: const Text('Keep holding'),
            ),
            TextButton(
              onPressed: () => context.pop(true),
              child: const Text('Send now'),
            ),
          ],
        ),
      ) ??
      false;

  static Future<bool> _confirmDelete(BuildContext context) async =>
      await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Delete this message?'),
          content: const Text(
            'Sometimes the best message is the one you never send.',
          ),
          actions: [
            TextButton(
              onPressed: () => context.pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => context.pop(true),
              style: TextButton.styleFrom(foregroundColor: AppColors.heated),
              child: const Text('Delete'),
            ),
          ],
        ),
      ) ??
      false;
}
