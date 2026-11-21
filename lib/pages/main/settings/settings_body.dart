import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../bloc/app_preferences_bloc.dart';
import '../../../bloc/baseline_bloc.dart';
import '../../../bloc/notification_access_bloc.dart';
import '../../../bloc/settings_bloc.dart';
import '../../../core/app_colors.dart';
import '../../../core/app_dimens.dart';
import '../../../core/app_typography.dart';
import '../../../core/config.dart';
import '../../../extension/context.dart';
import '../../../models/data/baseline_data.dart';
import '../../../models/data/user_settings_data.dart';
import '../../../models/enums/environment.dart';
import '../../../models/enums/sensitivity.dart';
import '../../../utils/app_haptics.dart';
import '../../../widgets/app_card.dart';
import '../../calibration/calibration_page.dart';
import 'bloc/settings_page_bloc.dart';
import 'bloc/settings_page_state.dart';

class SettingsBody extends StatelessWidget {
  const SettingsBody({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<SettingsPageBloc, SettingsPageState>(
      listenWhen: (a, b) => b.error != null && a.error != b.error,
      listener: (context, state) =>
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(state.error!))),
      child: SafeArea(
        bottom: false,
        child: BlocBuilder<SettingsBloc, UserSettingsData?>(
          builder: (context, settings) {
            if (settings == null) {
              return const Center(child: CircularProgressIndicator());
            }
            return ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.page,
                AppSpacing.md,
                AppSpacing.page,
                AppSpacing.xl,
              ),
              children: [
                const Text('Settings', style: AppTypography.extraBold32),
                const SizedBox(height: AppSpacing.lg),
                _ChecksSection(settings: settings),
                _HoldSection(settings: settings),
                _PrivacySection(settings: settings),
                if (config.environment == Environment.qa) const _DemoSection(),
                const _AboutSection(),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _Section({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(
              left: AppSpacing.xxs,
              bottom: AppSpacing.xs,
            ),
            child: Text(title.toUpperCase(), style: AppTypography.medium12),
          ),
          AppCard(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }
}

class _ChecksSection extends StatelessWidget {
  final UserSettingsData settings;

  const _ChecksSection({required this.settings});

  @override
  Widget build(BuildContext context) {
    final bloc = SettingsPageBloc.of(context);
    return _Section(
      title: 'Checks',
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.xs,
            AppSpacing.md,
            AppSpacing.sm,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Sensitivity', style: AppTypography.semiBold16),
              const SizedBox(height: AppSpacing.xxs),
              const Text(
                'High calls Warm and Heated sooner. Morning check-ins fine-tune it '
                'on their own.',
                style: AppTypography.regular12,
              ),
              const SizedBox(height: AppSpacing.sm),
              SegmentedButton<Sensitivity>(
                showSelectedIcon: false,
                segments: [
                  for (final s in [
                    Sensitivity.low,
                    Sensitivity.normal,
                    Sensitivity.high,
                  ])
                    ButtonSegment(value: s, label: Text(s.label)),
                ],
                selected: {settings.sensitivity},
                onSelectionChanged: (selection) {
                  AppHaptics.tap();
                  bloc.setSensitivity(selection.first);
                },
              ),
            ],
          ),
        ),
        const Divider(),
        BlocSelector<BaselineBloc, BaselineData?, double?>(
          selector: (baseline) => baseline?.pulseBpm,
          builder: (context, usual) => ListTile(
            leading: const Icon(Icons.tune_rounded),
            title: const Text(
              'Redo calibration',
              style: AppTypography.medium16,
            ),
            subtitle: Text(
              usual == null
                  ? 'Not calibrated yet'
                  : 'Your usual pulse: ${usual.round()} bpm',
              style: AppTypography.regular12,
            ),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => context.pushNamed(CalibrationPage.ROUTE_NAME),
          ),
        ),
        SwitchListTile(
          secondary: const Icon(Icons.vibration_rounded),
          title: const Text('Haptics', style: AppTypography.medium16),
          value: settings.hapticsEnabled,
          onChanged: bloc.setHaptics,
        ),
      ],
    );
  }
}

class _HoldSection extends StatelessWidget {
  final UserSettingsData settings;

  const _HoldSection({required this.settings});

  static const _holdOptions = [5, 10, 15, 30, 60];

  @override
  Widget build(BuildContext context) {
    final bloc = SettingsPageBloc.of(context);
    final options = [
      if (config.environment == Environment.qa) 1,
      ..._holdOptions,
    ];
    final time = TimeOfDay(
      hour: settings.checkinMinutes ~/ 60,
      minute: settings.checkinMinutes % 60,
    );
    return _Section(
      title: 'Holding & check-ins',
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.xs,
            AppSpacing.md,
            AppSpacing.sm,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Hold messages for', style: AppTypography.semiBold16),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: [
                  for (final minutes in options)
                    ChoiceChip(
                      label: Text('$minutes min'),
                      selected: settings.holdMinutes == minutes,
                      onSelected: (_) {
                        AppHaptics.tap();
                        bloc.setHoldMinutes(minutes);
                      },
                    ),
                ],
              ),
            ],
          ),
        ),
        const Divider(),
        BlocBuilder<NotificationAccessBloc, bool?>(
          builder: (context, allowed) => ListTile(
            leading: Icon(
              allowed == false
                  ? Icons.notifications_off_outlined
                  : Icons.notifications_active_outlined,
              color: allowed == false ? AppColors.warm : null,
            ),
            title: const Text('Notifications', style: AppTypography.medium16),
            subtitle: Text(
              allowed == false
                  ? "Off: you won't hear when a held message is ready, or get "
                        'the morning check-in.'
                  : 'On',
              style: AppTypography.regular12,
            ),
            trailing: allowed == false
                ? TextButton(
                    onPressed: NotificationAccessBloc.of(context).enable,
                    child: const Text('Turn on'),
                  )
                : null,
          ),
        ),
        SwitchListTile(
          secondary: const Icon(Icons.wb_twilight_rounded),
          title: const Text('Morning check-in', style: AppTypography.medium16),
          subtitle: const Text(
            'After a heated send, ask the next morning: "Glad you sent it?"',
            style: AppTypography.regular12,
          ),
          value: settings.checkinEnabled,
          onChanged: bloc.setCheckinEnabled,
        ),
        ListTile(
          enabled: settings.checkinEnabled,
          leading: const Icon(Icons.schedule_rounded),
          title: const Text('Check-in time', style: AppTypography.medium16),
          trailing: Text(time.format(context), style: AppTypography.number16),
          onTap: () async {
            final picked = await showTimePicker(
              context: context,
              initialTime: time,
            );
            if (picked != null) {
              unawaited(
                bloc.setCheckinMinutes(picked.hour * 60 + picked.minute),
              );
            }
          },
        ),
      ],
    );
  }
}

class _PrivacySection extends StatelessWidget {
  final UserSettingsData settings;

  const _PrivacySection({required this.settings});

  @override
  Widget build(BuildContext context) {
    final bloc = SettingsPageBloc.of(context);
    return _Section(
      title: 'Privacy',
      children: [
        SwitchListTile(
          secondary: const Icon(Icons.notes_rounded),
          title: const Text('Keep message text', style: AppTypography.medium16),
          subtitle: const Text(
            'Off: text is saved only while a message is held. On: sent messages '
            'keep their text on this phone, and check-ins show it.',
            style: AppTypography.regular12,
          ),
          value: settings.keepMessageText,
          onChanged: bloc.setKeepMessageText,
        ),
        AppPreferencesBlocSelector.analyticsEnabled(
          builder: (enabled) => SwitchListTile(
            secondary: const Icon(Icons.insert_chart_outlined_rounded),
            title: const Text(
              'Anonymous usage statistics',
              style: AppTypography.medium16,
            ),
            subtitle: const Text(
              'Never messages, measurements or results.',
              style: AppTypography.regular12,
            ),
            value: enabled,
            onChanged: bloc.setAnalytics,
          ),
        ),
        AppPreferencesBlocSelector.crashReportsEnabled(
          builder: (enabled) => SwitchListTile(
            secondary: const Icon(Icons.bug_report_outlined),
            title: const Text('Crash reports', style: AppTypography.medium16),
            value: enabled,
            onChanged: bloc.setCrashReports,
          ),
        ),
        const Divider(),
        SettingsPageBlocSelector.isDeleting(
          builder: (deleting) => ListTile(
            leading: const Icon(
              Icons.delete_forever_rounded,
              color: AppColors.heated,
            ),
            title: Text(
              'Delete all my data',
              style: AppTypography.medium16.copyWith(color: AppColors.heated),
            ),
            subtitle: const Text(
              'Messages, checks, calibration and settings. Starts over.',
              style: AppTypography.regular12,
            ),
            trailing: deleting
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : null,
            onTap: deleting ? null : () => _confirmDelete(context),
          ),
        ),
      ],
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final bloc = SettingsPageBloc.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete all your data?'),
        content: const Text(
          'Every held message, check, check-in answer, your calibration and your '
          'settings are erased from this phone. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => dialogContext.pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => dialogContext.pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.heated),
            child: const Text('Delete everything'),
          ),
        ],
      ),
    );
    if (confirmed ?? false) {
      await bloc.deleteEverything();
    }
  }
}

/// QA builds only: shortcuts for testing and recording the demo.
class _DemoSection extends StatelessWidget {
  const _DemoSection();

  @override
  Widget build(BuildContext context) {
    final preferences = AppPreferencesBloc.of(context);
    return _Section(
      title: 'Demo (QA builds only)',
      children: [
        AppPreferencesBlocSelector.demoCheckinsNow(
          builder: (enabled) => SwitchListTile(
            secondary: const Icon(Icons.fast_forward_rounded),
            title: const Text(
              'Check-ins due right away',
              style: AppTypography.medium16,
            ),
            subtitle: const Text(
              'Heated sends get their check-in card now, and the '
              'notification a minute later, instead of tomorrow morning.',
              style: AppTypography.regular12,
            ),
            value: enabled,
            onChanged: preferences.updateDemoCheckinsNow,
          ),
        ),
        ListTile(
          leading: const Icon(Icons.history_rounded),
          title: const Text(
            'Fill with sample history',
            style: AppTypography.medium16,
          ),
          subtitle: const Text(
            'Adds two weeks of checks, cool-downs and check-in answers (no '
            'message text) so Insights has something to show. Delete all my '
            'data removes it.',
            style: AppTypography.regular12,
          ),
          onTap: () => _confirmFill(context),
        ),
        if (simulateMeasurement)
          AppPreferencesBlocSelector.simulateHeated(
            builder: (heated) => SwitchListTile(
              secondary: const Icon(Icons.local_fire_department_rounded),
              title: const Text(
                'Simulated reading: heated',
                style: AppTypography.medium16,
              ),
              subtitle: const Text(
                'This build simulates the camera. Off: a calm reading. On: a '
                'raised pulse and tense face that settle after ~25 s.',
                style: AppTypography.regular12,
              ),
              value: heated,
              onChanged: preferences.updateSimulateHeated,
            ),
          ),
      ],
    );
  }
}

Future<void> _confirmFill(BuildContext context) async {
  final bloc = SettingsPageBloc.of(context);
  final messenger = ScaffoldMessenger.of(context);
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Add sample history?'),
      content: const Text(
        'Adds about 20 past checks over the last two weeks. Running it twice '
        'adds them twice.',
      ),
      actions: [
        TextButton(
          onPressed: () => dialogContext.pop(false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => dialogContext.pop(true),
          child: const Text('Add'),
        ),
      ],
    ),
  );
  if (confirmed ?? false) {
    AppHaptics.tap();
    final note = await bloc.fillSampleHistory();
    messenger.showSnackBar(SnackBar(content: Text(note)));
  }
}

class _AboutSection extends StatelessWidget {
  const _AboutSection();

  @override
  Widget build(BuildContext context) {
    return SettingsPageBlocSelector.version(
      builder: (version) => _Section(
        title: 'About',
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Cool Off $version', style: AppTypography.semiBold16),
                const SizedBox(height: AppSpacing.xs),
                const Text(
                  'Checks your pulse and facial expression with the front camera '
                  'before you send a heated message. Measurements run on this '
                  'phone with the Presage SmartSpectra SDK, through the open-source '
                  'smartspectra_flutter plugin. Video is never recorded, and your '
                  'messages never leave the phone.',
                  style: AppTypography.regular14,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'For wellness and informational use only. Not a medical device.',
                  style: AppTypography.semiBold14.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: const Text(
              'Open-source licences',
              style: AppTypography.medium16,
            ),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => showLicensePage(
              context: context,
              applicationName: 'Cool Off',
              applicationVersion: version,
            ),
          ),
        ],
      ),
    );
  }
}
