import 'package:built_value/built_value.dart';
import 'package:uuid/uuid.dart';
import 'package:wc_dart_framework/wc_dart_framework.dart';

part 'app_preferences_state.g.dart';

/// Preferences that belong to this install, not to the user's data: kept in
/// hydrated storage and never synced (docs/11-data-and-sync.md). Consent is
/// per device.
abstract class AppPreferencesState
    implements Built<AppPreferencesState, AppPreferencesStateBuilder> {
  factory AppPreferencesState([
    void Function(AppPreferencesStateBuilder) updates,
  ]) = _$AppPreferencesState;

  AppPreferencesState._();

  /// Bump when the consent text changes materially: onboarding then asks
  /// again.
  static const int currentConsentVersion = 1;

  @BuiltValueHook(initializeBuilder: true)
  static void _initialize(AppPreferencesStateBuilder b) => b
    ..deviceId = const Uuid().v4()
    ..isOnboardingComplete = false
    ..consentVersion = 0
    ..analyticsEnabled = true
    ..crashReportsEnabled = true
    ..demoCheckinsNow = false
    ..simulateHeated = false;

  /// This install's stable id, stamped as `origin_device_id` on the rows it
  /// creates. A reinstall, or "Delete all my data", is a new device.
  @BlocHydratedField()
  String get deviceId;

  /// False until consent and the baseline are done. The router shows
  /// onboarding while false.
  @BlocHydratedField()
  bool get isOnboardingComplete;

  /// The consent version the user accepted; 0 = never.
  @BlocHydratedField()
  int get consentVersion;

  /// Anonymous usage events (docs/06). On by default; Settings turns off.
  @BlocHydratedField()
  bool get analyticsEnabled;

  /// Crash reports (docs/06). On by default; Settings turns off.
  @BlocHydratedField()
  bool get crashReportsEnabled;

  /// QA builds only (Settings → Demo): unanswered check-ins are due at
  /// once, for testing and the demo video.
  @BlocUpdateField()
  @BlocHydratedField()
  bool get demoCheckinsNow;

  /// Builds with the camera simulated only (Settings → Demo): the simulated
  /// reading is heated instead of calm.
  @BlocUpdateField()
  @BlocHydratedField()
  bool get simulateHeated;

  bool get needsConsent => consentVersion < currentConsentVersion;
}
