import 'package:app_settings/app_settings.dart';

/// Opens the phone's own settings pages, for permissions the app may no
/// longer ask for itself (after the user said no once).
class _SystemSettingsService {
  Future<void> openNotificationSettings() =>
      AppSettings.openAppSettings(type: AppSettingsType.notification);

  /// Cool Off's page in the phone's settings (camera access lives there).
  Future<void> openAppSettings() => AppSettings.openAppSettings();
}

final systemSettingsService = _SystemSettingsService();
