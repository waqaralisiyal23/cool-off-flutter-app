import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../core/app_dimens.dart';
import '../models/enums/heat_level.dart';
import '../utils/app_haptics.dart';

/// What to do with a checked message, by how it read (docs/02-features.md):
///
/// * Calm → **Send**, or Edit.
/// * Warm → **Send** after a reread, or Edit; Hold is offered too.
/// * Heated → **Hold**, or Cool down now; Send anyway.
///
/// Send (or Send anyway) is always there: Cool Off only suggests.
class OutcomeActions extends StatelessWidget {
  final HeatLevel level;
  final int holdMinutes;
  final bool isBusy;

  /// Receives the button's rect, for the iPad share popover.
  final void Function(Rect? origin) onSend;
  final VoidCallback onHold;
  final VoidCallback? onCoolDown;
  final VoidCallback onEdit;
  final VoidCallback onDiscard;

  const OutcomeActions({
    super.key,
    required this.level,
    required this.holdMinutes,
    required this.isBusy,
    required this.onSend,
    required this.onHold,
    required this.onEdit,
    required this.onDiscard,
    this.onCoolDown,
  });

  @override
  Widget build(BuildContext context) {
    final heated = level == HeatLevel.heated;
    final children = <Widget>[
      if (heated) ...[
        _HoldButton(minutes: holdMinutes, onPressed: _guard(onHold)),
        if (onCoolDown != null) ...[
          const SizedBox(height: AppSpacing.sm),
          OutlinedButton.icon(
            onPressed: _guard(onCoolDown!),
            icon: const Icon(Icons.air_rounded),
            label: const Text('Cool down now · 60 s'),
          ),
        ],
        const SizedBox(height: AppSpacing.xs),
        Row(
          children: [
            Expanded(
              child: _SendButton(
                label: 'Send anyway',
                quiet: true,
                isBusy: isBusy,
                onSend: onSend,
              ),
            ),
            Expanded(
              child: TextButton(
                onPressed: _guard(onEdit),
                child: const Text('Edit'),
              ),
            ),
          ],
        ),
      ] else ...[
        _SendButton(label: 'Send', isBusy: isBusy, onSend: onSend),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _guard(onEdit),
                child: const Text('Edit'),
              ),
            ),
            if (level == HeatLevel.warm) ...[
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: OutlinedButton(
                  onPressed: _guard(onHold),
                  child: Text('Hold $holdMinutes min'),
                ),
              ),
            ],
          ],
        ),
      ],
      TextButton(
        onPressed: _guard(onDiscard),
        child: const Text('Delete message'),
      ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: children,
    );
  }

  VoidCallback? _guard(VoidCallback action) => isBusy
      ? null
      : () {
          AppHaptics.tap();
          action();
        };
}

class _HoldButton extends StatelessWidget {
  final int minutes;
  final VoidCallback? onPressed;

  const _HoldButton({required this.minutes, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.pause_circle_rounded),
      label: Text('Hold for $minutes min'),
    );
  }
}

class _SendButton extends StatelessWidget {
  final String label;
  final bool quiet;
  final bool isBusy;
  final void Function(Rect? origin) onSend;

  const _SendButton({
    required this.label,
    required this.isBusy,
    required this.onSend,
    this.quiet = false,
  });

  @override
  Widget build(BuildContext context) {
    void send() {
      AppHaptics.tap();
      final box = context.findRenderObject() as RenderBox?;
      onSend(box == null ? null : box.localToGlobal(Offset.zero) & box.size);
    }

    if (quiet) {
      return TextButton.icon(
        onPressed: isBusy ? null : send,
        icon: const Icon(Icons.send_rounded, size: 18),
        label: Text(label),
        style: TextButton.styleFrom(foregroundColor: AppColors.heatedSoft),
      );
    }
    return FilledButton.icon(
      onPressed: isBusy ? null : send,
      icon: const Icon(Icons.send_rounded),
      label: Text(label),
    );
  }
}
