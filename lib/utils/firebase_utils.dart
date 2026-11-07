import 'dart:async';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

import '../core/config.dart';
import '../firebase_options.dart';

/// Firebase Core, Crashlytics and Analytics (docs/07-firebase.md).
///
/// Privacy (docs/06-privacy-and-data.md):
/// * Analytics and Crashlytics are on in release builds; the user can turn
///   either off in Settings ([applyConsent]). The advertising ID and ad
///   personalization are off natively (AndroidManifest / Info.plist).
/// * Debug builds never report either, so development never pollutes the
///   dashboards.
class FirebaseUtils {
  FirebaseUtils._();

  static FirebaseAnalytics get analytics => FirebaseAnalytics.instance;

  static FirebaseCrashlytics get crashlytics => FirebaseCrashlytics.instance;

  /// True once [init] has run. False in tests, which never initialize
  /// Firebase, so analytics and crash calls become no-ops there.
  static bool isInitialized = false;

  /// Initializes Firebase, Crashlytics and Analytics.
  ///
  /// Call once in `main()` after `WidgetsFlutterBinding.ensureInitialized()`
  /// and after dotenv has loaded (it reads `config.environment`).
  static Future<void> init() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    isInitialized = true;

    // QA and production share one Firebase project; this tells them apart.
    final environment = config.environment.name;
    await crashlytics.setCustomKey('environment', environment);
    await analytics.setDefaultEventParameters({'environment': environment});

    await analytics.setAnalyticsCollectionEnabled(!kDebugMode);
    await crashlytics.setCrashlyticsCollectionEnabled(!kDebugMode);

    // Errors thrown by the Flutter framework (build, layout, paint).
    FlutterError.onError = crashlytics.recordFlutterFatalError;

    // Uncaught async errors outside the Flutter framework.
    PlatformDispatcher.instance.onError = (error, stack) {
      unawaited(crashlytics.recordError(error, stack, fatal: true));
      return true;
    };
  }

  /// Applies the user's choices from Settings (both default to on). Call at
  /// startup once the saved choices are known, and whenever they change.
  static Future<void> applyConsent({
    required bool analyticsEnabled,
    required bool crashReportsEnabled,
  }) async {
    if (!isInitialized) {
      return;
    }
    await analytics.setAnalyticsCollectionEnabled(
      analyticsEnabled && !kDebugMode,
    );
    await crashlytics.setCrashlyticsCollectionEnabled(
      crashReportsEnabled && !kDebugMode,
    );
  }
}
