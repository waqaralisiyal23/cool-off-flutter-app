import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/app_colors.dart';
import '../../../core/app_dimens.dart';
import '../../../core/app_typography.dart';
import '../../../extension/context.dart';
import '../../../utils/app_haptics.dart';
import '../../../widgets/app_card.dart';
import '../../calibration/calibration_page.dart';
import 'bloc/permissions_bloc.dart';
import '../../../widgets/fill_scroll_view.dart';

class PermissionsBody extends StatelessWidget {
  const PermissionsBody({super.key});

  @override
  Widget build(BuildContext context) {
    final bloc = PermissionsBloc.of(context);
    return SafeArea(
      top: false,
      child: Padding(
        padding: AppSpacing.pagePadding,
        child: FillScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Two quick permissions', style: AppTypography.bold24),
              const SizedBox(height: AppSpacing.xs),
              const Text(
                'The camera is needed for checks. Notifications are optional.',
                style: AppTypography.regular14,
              ),
              const SizedBox(height: AppSpacing.lg),
              PermissionsBlocSelector(
                selector: (s) => (s.cameraGranted, s.cameraDenied),
                builder: (camera) => _PermissionCard(
                  icon: Icons.videocam_rounded,
                  title: 'Camera',
                  text: camera.$2
                      ? "Camera access was refused. Turn it on for Cool Off in "
                            "your phone's Settings, then come back."
                      : 'For the 20-second pulse and expression check. Only '
                            'while a check runs; video never leaves the phone.',
                  granted: camera.$1,
                  actionLabel: camera.$2 ? 'Open Settings' : 'Allow camera',
                  onAction: camera.$2 ? bloc.openSettings : bloc.requestCamera,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              PermissionsBlocSelector(
                selector: (s) => (s.notificationsGranted, s.notificationsAsked),
                builder: (notifications) => _PermissionCard(
                  icon: Icons.notifications_rounded,
                  title: 'Notifications',
                  text: notifications.$2 && !notifications.$1
                      ? 'No problem. You can turn them on later in Settings.'
                      : 'To tell you when a held message is ready, and for an '
                            'optional morning check-in.',
                  granted: notifications.$1,
                  optional: true,
                  actionLabel: 'Allow notifications',
                  onAction: bloc.requestNotifications,
                ),
              ),
              const Spacer(),
              PermissionsBlocSelector.cameraGranted(
                builder: (granted) => FilledButton(
                  onPressed: granted
                      ? () {
                          AppHaptics.tap();
                          context.pushNamed(CalibrationPage.ROUTE_NAME);
                        }
                      : null,
                  child: const Text('Continue'),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        ),
      ),
    );
  }
}

class _PermissionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String text;
  final bool granted;
  final bool optional;
  final String actionLabel;
  final Future<void> Function() onAction;

  const _PermissionCard({
    required this.icon,
    required this.title,
    required this.text,
    required this.granted,
    required this.actionLabel,
    required this.onAction,
    this.optional = false,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      accent: granted ? AppColors.calm : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary),
              const SizedBox(width: AppSpacing.xs),
              Text(title, style: AppTypography.semiBold16),
              if (optional) ...[
                const SizedBox(width: AppSpacing.xs),
                const Text('Optional', style: AppTypography.regular12),
              ],
              const Spacer(),
              AnimatedSwitcher(
                duration: AppMotion.medium,
                transitionBuilder: (child, animation) =>
                    ScaleTransition(scale: animation, child: child),
                child: granted
                    ? const Icon(
                        Icons.check_circle_rounded,
                        key: ValueKey('granted'),
                        color: AppColors.calm,
                      )
                    : const SizedBox.shrink(key: ValueKey('pending')),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(text, style: AppTypography.regular14),
          if (!granted) ...[
            const SizedBox(height: AppSpacing.sm),
            OutlinedButton(
              onPressed: () {
                AppHaptics.tap();
                unawaited(onAction());
              },
              child: Text(actionLabel),
            ),
          ],
        ],
      ),
    );
  }
}
