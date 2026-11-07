import '../utils/firebase_utils.dart';

/// Analytics events (docs/06-privacy-and-data.md). This list is the
/// allowlist: add an event here, and to the doc, or not at all.
///
/// **Never send** message text, recipients, pulse or expression values,
/// heat levels (calm/warm/heated) or check-in answers. Emotional and
/// physiological data stays on the phone. Events say only that something
/// happened.
///
/// Analytics is on by default; nothing is sent if the user turned it off in
/// Settings (`FirebaseUtils.applyConsent`) or in debug builds.
class _AnalyticsService {
  Future<void> logOnboardingCompleted() => _log('onboarding_completed');

  Future<void> logBaselineCompleted() => _log('baseline_completed');

  Future<void> logCheckStarted() => _log('check_started');

  /// Deliberately carries no result.
  Future<void> logCheckCompleted() => _log('check_completed');

  Future<void> logCheckCancelled() => _log('check_cancelled');

  Future<void> logCooldownStarted() => _log('cooldown_started');

  Future<void> logCooldownCompleted() => _log('cooldown_completed');

  Future<void> logMessageHeld() => _log('message_held');

  Future<void> logMessageShared() => _log('message_shared');

  /// Never the answer itself.
  Future<void> logCheckinAnswered() => _log('checkin_answered');

  /// [setting] is the setting's name only (e.g. `hold_minutes`), never its
  /// value.
  Future<void> logSettingsChanged(String setting) =>
      _log('settings_changed', {'setting': setting});

  Future<void> _log(String name, [Map<String, Object>? parameters]) async {
    if (!FirebaseUtils.isInitialized) {
      return;
    }
    await FirebaseUtils.analytics.logEvent(name: name, parameters: parameters);
  }
}

final analyticsService = _AnalyticsService();
