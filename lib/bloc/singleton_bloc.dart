import 'app_preferences_bloc.dart';
import 'baseline_bloc.dart';
import 'notification_access_bloc.dart';
import 'settings_bloc.dart';

/// Lazy holder for the global blocs, provided at the root in `main.dart`.
class _SingletonBloc {
  AppPreferencesBloc? _appPreferencesBloc;
  SettingsBloc? _settingsBloc;
  BaselineBloc? _baselineBloc;
  NotificationAccessBloc? _notificationAccessBloc;

  AppPreferencesBloc get appPreferencesBloc =>
      _appPreferencesBloc ??= AppPreferencesBloc();

  SettingsBloc get settingsBloc => _settingsBloc ??= SettingsBloc();

  BaselineBloc get baselineBloc => _baselineBloc ??= BaselineBloc();

  NotificationAccessBloc get notificationAccessBloc =>
      _notificationAccessBloc ??= NotificationAccessBloc();
}

final singletonBloc = _SingletonBloc();
