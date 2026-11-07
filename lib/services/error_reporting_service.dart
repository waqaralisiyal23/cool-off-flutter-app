import 'dart:async';

import '../utils/firebase_utils.dart';

/// Non-fatal error reports and breadcrumbs to Crashlytics
/// (docs/06-privacy-and-data.md, docs/07-firebase.md). Crashes themselves are
/// caught in `FirebaseUtils.init()`.
///
/// **Never personal or physiological data**: no message text, recipients,
/// pulse or expression values, heat levels or check-in answers. Reports say
/// what failed and where, nothing about the person.
///
/// Silent when Firebase isn't initialized (tests) or the user turned crash
/// reports off (`FirebaseUtils.applyConsent`).
class _ErrorReportingService {
  /// A failure that is not a crash but should be looked into, such as
  /// notifications failing to schedule or a database write failing.
  /// [reason] says what was being done, e.g. `Saving a held message failed`.
  Future<void> recordError(
    Object error,
    StackTrace stackTrace, {
    required String reason,
    Iterable<String> information = const [],
  }) async {
    if (!FirebaseUtils.isInitialized) {
      return;
    }
    await FirebaseUtils.crashlytics.recordError(
      error,
      stackTrace,
      reason: reason,
      information: information,
    );
  }

  /// A measurement that failed during [operation] (`baseline`, `check`,
  /// `cooldown`). [code] is the plugin's error code name, e.g.
  /// `authenticationFailed`.
  ///
  /// The phone's own situation is left out: no network or DNS
  /// (`networkError`) and no camera access (`inputUnavailable`). The screen
  /// already tells the user what to do, and they are not bugs.
  Future<void> recordMeasurementFailure(
    Object error,
    StackTrace stackTrace, {
    required String operation,
    required String code,
    bool? retryable,
  }) async {
    if (!FirebaseUtils.isInitialized || _phoneSituation.contains(code)) {
      return;
    }
    await FirebaseUtils.crashlytics.recordError(
      error,
      stackTrace,
      reason: 'Measurement $operation failed: $code',
      information: [if (retryable != null) 'retryable: $retryable'],
    );
  }

  /// A step on the way (check started, cool-down finished, notification
  /// scheduled), sent with the next report from this run to show what led
  /// up to it. [message] must hold no message text or measured values.
  void log(String message) {
    if (FirebaseUtils.isInitialized) {
      unawaited(FirebaseUtils.crashlytics.log(message));
    }
  }

  static const _phoneSituation = {'networkError', 'inputUnavailable'};
}

final errorReportingService = _ErrorReportingService();
