import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:wc_dart_framework/wc_dart_framework.dart';

import '../../../../bloc/app_preferences_bloc.dart';
import '../../../../bloc/settings_bloc.dart';
import '../../../../database/app_database.dart';
import '../../../../models/enums/sensitivity.dart';
import '../../../../services/analytics_service.dart';
import '../../../../services/demo_history_service.dart';
import '../../../../services/notification_service.dart';
import '../../../../services/records_service.dart';
import '../../../../services/settings_service.dart';
import '../../../../widgets/cubit/cubit.dart';
import 'settings_page_state.dart';

part 'settings_page_bloc.bloc.g.dart';

final _logger = Logger('settings_page_bloc.dart');

/// Changes settings (analytics get the setting's name only, never its
/// value) and deletes everything.
@BlocGen()
class SettingsPageBloc
    extends BVCubit<SettingsPageState, SettingsPageStateBuilder>
    with _$SettingsPageBlocMixin {
  SettingsPageBloc({required this.preferences, required this.settings})
    : super(SettingsPageState());

  factory SettingsPageBloc.of(BuildContext context) =>
      BlocProvider.of<SettingsPageBloc>(context);

  final AppPreferencesBloc preferences;
  final SettingsBloc settings;

  Future<void> load() async {
    final info = await PackageInfo.fromPlatform();
    emit(
      state.rebuild((b) => b.version = '${info.version} (${info.buildNumber})'),
    );
  }

  Future<void> setSensitivity(Sensitivity value) =>
      _save('sensitivity', () => settingsService.update(sensitivity: value));

  Future<void> setHoldMinutes(int value) =>
      _save('hold_minutes', () => settingsService.update(holdMinutes: value));

  Future<void> setCheckinEnabled(bool value) => _save(
    'checkin_enabled',
    () => settingsService.update(checkinEnabled: value),
  );

  Future<void> setCheckinMinutes(int value) => _save(
    'checkin_minutes',
    () => settingsService.update(checkinMinutes: value),
  );

  Future<void> setHaptics(bool value) => _save(
    'haptics_enabled',
    () => settingsService.update(hapticsEnabled: value),
  );

  /// Turning it off also clears the text of messages that are no longer held.
  Future<void> setKeepMessageText(bool value) =>
      _save('keep_message_text', () async {
        await settingsService.update(keepMessageText: value);
        if (!value) {
          await recordsService.clearFinishedMessageText();
        }
      });

  Future<void> setAnalytics(bool value) async {
    await preferences.setAnalyticsEnabled(value);
    unawaited(analyticsService.logSettingsChanged('analytics_enabled'));
  }

  Future<void> setCrashReports(bool value) async {
    await preferences.setCrashReportsEnabled(value);
    unawaited(analyticsService.logSettingsChanged('crash_reports_enabled'));
  }

  /// "Delete all my data": every row, every scheduled notification, and this
  /// install's preferences. The router then shows onboarding again.
  Future<void> deleteEverything() async {
    emit(state.rebuild((b) => b.isDeleting = true));
    try {
      await notificationService.cancelAll();
      await recordsService.wipeEverything();
      await preferences.resetAll();
      appDatabase.deviceId = preferences.state.deviceId;
      await settings.start();
    } on Object catch (e) {
      _logger.warning('Deleting everything failed: $e');
      emit(
        state.rebuild(
          (b) => b.error = "Couldn't delete everything. Please try again.",
        ),
      );
    } finally {
      emit(state.rebuild((b) => b.isDeleting = false));
    }
  }

  /// QA builds only: two weeks of sample history for the demo video. The
  /// message for a snackbar.
  Future<String> fillSampleHistory() async {
    try {
      final added = await demoHistoryService.seed();
      return added
          ? 'Added two weeks of sample history. See Insights.'
          : 'Finish calibration first.';
    } on Object catch (e) {
      _logger.warning('Filling sample history failed: $e');
      return "Couldn't add the sample history.";
    }
  }

  Future<void> _save(String name, Future<void> Function() write) async {
    try {
      await write();
      unawaited(analyticsService.logSettingsChanged(name));
    } on Object catch (e) {
      _logger.warning('Saving $name failed: $e');
      emit(state.rebuild((b) => b.error = "Couldn't save that setting."));
      emit(state.rebuild((b) => b.error = null));
    }
  }
}
