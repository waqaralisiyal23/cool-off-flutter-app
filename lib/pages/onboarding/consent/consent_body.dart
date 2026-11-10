import 'package:flutter/material.dart';

import '../../../bloc/app_preferences_bloc.dart';
import '../../../core/app_colors.dart';
import '../../../core/app_dimens.dart';
import '../../../core/app_typography.dart';
import '../../../extension/context.dart';
import '../../../utils/app_haptics.dart';
import '../../../widgets/app_card.dart';
import '../permissions/permissions_page.dart';

class ConsentBody extends StatelessWidget {
  const ConsentBody({super.key});

  @override
  Widget build(BuildContext context) {
    final preferences = AppPreferencesBloc.of(context);
    return SafeArea(
      top: false,
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: AppSpacing.pagePadding,
              children: [
                const Text(
                  'Before we use the camera',
                  style: AppTypography.bold24,
                ),
                const SizedBox(height: AppSpacing.xs),
                const Text(
                  'Cool Off is built so your messages and your face stay '
                  "yours. Here's exactly what happens.",
                  style: AppTypography.regular14,
                ),
                const SizedBox(height: AppSpacing.lg),
                const _Point(
                  icon: Icons.videocam_rounded,
                  title: 'Camera only during a check',
                  text:
                      'The front camera reads your pulse and facial expression '
                      'for about 20 seconds, only while a check runs. You '
                      'always see the preview. Video is processed on this '
                      'phone and is never recorded or uploaded.',
                ),
                const _Point(
                  icon: Icons.lock_rounded,
                  title: 'Your messages stay on this phone',
                  text:
                      'Message text never leaves your phone. Cool Off never '
                      'sends anything: you send through the share sheet, to the '
                      'app you choose. Text is saved only while a message is '
                      'held, unless you choose to keep it.',
                ),
                const _Point(
                  icon: Icons.storage_rounded,
                  title: 'What is saved',
                  text:
                      'Your usual pulse, check results (calm, warm or heated, '
                      'with their numbers) and your settings, in this app\'s '
                      'private storage. Settings → Delete all my data erases '
                      'everything.',
                ),
                const _Point(
                  icon: Icons.cloud_outlined,
                  title: 'The measurement service',
                  text:
                      'SmartSpectra by Presage checks the app\'s key and '
                      'downloads its models over the internet. No video, '
                      'measurements or messages are sent. If your network '
                      "can't find Presage's server, its address is looked up "
                      "through Cloudflare's or Google's public DNS instead.",
                ),
                const SizedBox(height: AppSpacing.xs),
                AppCard(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                  child: Column(
                    children: [
                      AppPreferencesBlocSelector.analyticsEnabled(
                        builder: (enabled) => SwitchListTile(
                          value: enabled,
                          onChanged: preferences.setAnalyticsEnabled,
                          title: const Text(
                            'Anonymous usage statistics',
                            style: AppTypography.semiBold14,
                          ),
                          subtitle: const Text(
                            'Which screens are used. Never messages, '
                            'measurements or results.',
                            style: AppTypography.regular12,
                          ),
                        ),
                      ),
                      AppPreferencesBlocSelector.crashReportsEnabled(
                        builder: (enabled) => SwitchListTile(
                          value: enabled,
                          onChanged: preferences.setCrashReportsEnabled,
                          title: const Text(
                            'Crash reports',
                            style: AppTypography.semiBold14,
                          ),
                          subtitle: const Text(
                            'What went wrong in the app, with device details. '
                            'No personal content.',
                            style: AppTypography.regular12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                const Text(
                  'You can change these any time in Settings.\n'
                  'For wellness and informational use only. '
                  'Not a medical device.',
                  style: AppTypography.regular12,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.md),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.page,
              AppSpacing.xs,
              AppSpacing.page,
              AppSpacing.md,
            ),
            child: FilledButton(
              onPressed: () {
                AppHaptics.tap();
                preferences.acceptConsent();
                context.pushNamed(PermissionsPage.ROUTE_NAME);
              },
              child: const Text('I understand, continue'),
            ),
          ),
        ],
      ),
    );
  }
}

class _Point extends StatelessWidget {
  final IconData icon;
  final String title;
  final String text;

  const _Point({required this.icon, required this.title, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: AppRadius.smAll,
            ),
            child: Icon(icon, size: 22, color: AppColors.primary),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.semiBold16),
                const SizedBox(height: AppSpacing.xxs),
                Text(text, style: AppTypography.regular14),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
