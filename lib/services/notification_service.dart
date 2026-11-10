import 'dart:async';
import 'dart:convert';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import 'package:wc_dart_framework/wc_dart_framework.dart';

import '../core/app_colors.dart';
import '../database/app_database.dart';
import '../models/enums/notification_kind.dart';
import '../models/enums/reflection_answer.dart';
import 'analytics_service.dart';
import 'checkin_service.dart';
import 'error_reporting_service.dart';

final _logger = Logger('notification_service.dart');

/// A notification the user tapped: what it is about.
class NotificationTap {
  const NotificationTap({
    required this.kind,
    required this.targetId,
    this.deviceId,
  });

  final NotificationKind kind;

  /// The held message (hold ended) or check record (check-in).
  final String targetId;

  /// This install's id, for rows a check-in button writes from the
  /// background, where the app's preferences are not loaded.
  final String? deviceId;

  String encode() =>
      jsonEncode({'kind': kind.name, 'target': targetId, 'device': ?deviceId});

  static NotificationTap? decode(String? payload) {
    if (payload == null) {
      return null;
    }
    try {
      final json = jsonDecode(payload) as Map<String, dynamic>;
      return NotificationTap(
        kind: NotificationKind.valueOf(json['kind'] as String),
        targetId: json['target'] as String,
        deviceId: json['device'] as String?,
      );
    } on Object catch (e) {
      _logger.warning('Unreadable notification payload: $e');
      return null;
    }
  }
}

/// The check-in notification's buttons.
class CheckinAction {
  CheckinAction._();

  static const String glad = 'glad';
  static const String regret = 'regret';

  static ReflectionAnswer? answerFor(String? actionId) => switch (actionId) {
    glad => ReflectionAnswer.glad,
    regret => ReflectionAnswer.regret,
    _ => null,
  };
}

/// 👍 or 👎 tapped on a check-in while the app is closed (and on Android,
/// always): runs in a background isolate. Top-level and kept through tree
/// shaking. It opens the database (shared with the app when it is running)
/// to save the answer, the same way the Write tab does.
@pragma('vm:entry-point')
Future<void> onBackgroundNotificationResponse(
  NotificationResponse response,
) async {
  final tap = NotificationTap.decode(response.payload);
  final answer = CheckinAction.answerFor(response.actionId);
  final deviceId = tap?.deviceId;
  if (tap == null || answer == null || deviceId == null) {
    return;
  }
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  appDatabase = AppDatabase.open(deviceId: deviceId);
  try {
    await checkinService.answer(tap.targetId, answer);
    await appDatabase.scheduledNotificationsDao.removeForTarget(tap.targetId);
  } on Object catch (e) {
    _logger.warning('Saving a check-in answer in the background failed: $e');
  } finally {
    await appDatabase.close();
  }
}

/// Local notifications only: "your held message is ready" and the
/// next-morning check-in (docs/02-features.md). No push, no server.
///
/// **Never message text or recipients in a notification**: they show on the
/// lock screen. Inexact scheduling on Android, so no exact-alarm permission.
class _NotificationService {
  final _plugin = FlutterLocalNotificationsPlugin();
  final _taps = StreamController<NotificationTap>.broadcast();

  bool _initialized = false;
  NotificationTap? _launchTap;

  static const String _channelId = 'cool_off';
  static const String _channelName = 'Held messages and check-ins';
  static const String _channelDescription =
      'When a held message is ready, and the next-morning check-in.';

  static const String _checkinCategory = 'checkin';

  static final InitializationSettings _settings = InitializationSettings(
    // A white silhouette: Android uses only its alpha.
    android: const AndroidInitializationSettings('ic_notification'),
    iOS: DarwinInitializationSettings(
      // Never ask at launch: onboarding asks, after explaining why.
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
      notificationCategories: [
        DarwinNotificationCategory(
          _checkinCategory,
          actions: [
            DarwinNotificationAction.plain(CheckinAction.glad, '👍 Glad I did'),
            DarwinNotificationAction.plain(
              CheckinAction.regret,
              '👎 Regret it',
            ),
          ],
        ),
      ],
    ),
  );

  static NotificationDetails _details({
    bool checkin = false,
  }) => NotificationDetails(
    android: AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.high,
      priority: Priority.high,
      icon: 'ic_notification',
      color: AppColors.primary,
      // Answered in the background; the notification goes away.
      actions: checkin
          ? const [
              AndroidNotificationAction(CheckinAction.glad, '👍 Glad I did'),
              AndroidNotificationAction(CheckinAction.regret, '👎 Regret it'),
            ]
          : null,
    ),
    iOS: DarwinNotificationDetails(
      presentAlert: true,
      presentBanner: true,
      presentList: true,
      presentSound: true,
      categoryIdentifier: checkin ? _checkinCategory : null,
    ),
  );

  /// Taps while the app runs. A tap that launched the app is
  /// [takeLaunchTap].
  Stream<NotificationTap> get taps => _taps.stream;

  /// The tap that opened the app, once.
  NotificationTap? takeLaunchTap() {
    final tap = _launchTap;
    _launchTap = null;
    return tap;
  }

  /// Prepares time zones and the plugin. A failure is reported and leaves
  /// the app working without notifications.
  Future<void> init() async {
    if (_initialized) {
      return;
    }
    try {
      tz_data.initializeTimeZones();
      await _followDeviceTimezone();
      await _plugin.initialize(
        settings: _settings,
        onDidReceiveNotificationResponse: _onResponse,
        onDidReceiveBackgroundNotificationResponse:
            onBackgroundNotificationResponse,
      );
      await _android?.createNotificationChannel(
        const AndroidNotificationChannel(
          _channelId,
          _channelName,
          description: _channelDescription,
          importance: Importance.high,
        ),
      );
      final launch = await _plugin.getNotificationAppLaunchDetails();
      if (launch?.didNotificationLaunchApp ?? false) {
        _launchTap = NotificationTap.decode(
          launch?.notificationResponse?.payload,
        );
      }
      _initialized = true;
    } on Exception catch (e, stackTrace) {
      _logger.warning('Notifications unavailable: $e');
      await errorReportingService.recordError(
        e,
        stackTrace,
        reason: 'Notifications failed to start',
      );
    }
  }

  /// Taps, and check-in buttons while the app is open.
  void _onResponse(NotificationResponse response) {
    final tap = NotificationTap.decode(response.payload);
    if (tap == null) {
      return;
    }
    final answer = CheckinAction.answerFor(response.actionId);
    if (answer == null) {
      _taps.add(tap);
      return;
    }
    unawaited(_answer(tap.targetId, answer));
  }

  Future<void> _answer(String checkId, ReflectionAnswer answer) async {
    try {
      if (await checkinService.answer(checkId, answer)) {
        unawaited(analyticsService.logCheckinAnswered());
      }
      await appDatabase.scheduledNotificationsDao.removeForTarget(checkId);
    } on Object catch (e, stackTrace) {
      await errorReportingService.recordError(
        e,
        stackTrace,
        reason: 'Saving a check-in answer from a notification failed',
      );
    }
  }

  Future<void> _followDeviceTimezone() async {
    try {
      final name = (await FlutterTimezone.getLocalTimezone()).identifier;
      tz.setLocalLocation(tz.getLocation(name));
    } on PlatformException catch (e) {
      _logger.warning('Device timezone unknown: $e');
    } on MissingPluginException catch (e) {
      _logger.warning('No timezone plugin here: $e');
    } on tz.LocationNotFoundException catch (e) {
      _logger.warning('Timezone not in the database: $e');
    }
  }

  AndroidFlutterLocalNotificationsPlugin? get _android => _plugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();

  IOSFlutterLocalNotificationsPlugin? get _ios => _plugin
      .resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin
      >();

  /// Whether the app may post notifications.
  Future<bool> isAllowed() async {
    if (!_initialized) {
      return false;
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      return await _android?.areNotificationsEnabled() ?? false;
    }
    final options = await _ios?.checkPermissions();
    return options?.isEnabled ?? false;
  }

  /// Asks the system once (Android 13+, iOS). After a refusal only the
  /// phone's settings can change it.
  Future<bool> requestPermission() async {
    if (!_initialized) {
      return false;
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      return await _android?.requestNotificationsPermission() ?? false;
    }
    return await _ios?.requestPermissions(alert: true, sound: true) ?? false;
  }

  Future<void> scheduleHoldEnded({
    required String messageId,
    required DateTime fireAt,
  }) => _schedule(
    kind: NotificationKind.holdEnded,
    targetId: messageId,
    fireAt: fireAt,
    title: 'Your held message is ready',
    body: 'Cooled off? Still want to send it?',
  );

  Future<void> scheduleCheckin({
    required String checkId,
    required DateTime fireAt,
  }) => _schedule(
    kind: NotificationKind.checkin,
    targetId: checkId,
    fireAt: fireAt,
    title: 'Glad you sent it?',
    body: 'You sent a message while heated. How do you feel about it now?',
    checkin: true,
  );

  /// Cancels what was scheduled for [targetId] (a message sent or deleted
  /// before its hold ended).
  Future<void> cancelFor(String targetId) async {
    try {
      final scheduled = await appDatabase.scheduledNotificationsDao.forTarget(
        targetId,
      );
      for (final notification in scheduled) {
        await _plugin.cancel(id: notification.id);
      }
      await appDatabase.scheduledNotificationsDao.removeForTarget(targetId);
    } on Object catch (e, stackTrace) {
      await errorReportingService.recordError(
        e,
        stackTrace,
        reason: 'Cancelling a notification failed',
      );
    }
  }

  /// "Delete all my data".
  Future<void> cancelAll() async {
    if (_initialized) {
      await _plugin.cancelAll();
    }
  }

  Future<void> _schedule({
    required NotificationKind kind,
    required String targetId,
    required DateTime fireAt,
    required String title,
    required String body,
    bool checkin = false,
  }) async {
    if (!_initialized) {
      return;
    }
    try {
      final id = await appDatabase.scheduledNotificationsDao.add(
        kind: kind,
        targetId: targetId,
        fireAt: fireAt.toUtc(),
      );
      await _plugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: tz.TZDateTime.from(fireAt, tz.local),
        notificationDetails: _details(checkin: checkin),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: NotificationTap(
          kind: kind,
          targetId: targetId,
          deviceId: appDatabase.deviceId,
        ).encode(),
      );
      errorReportingService.log('Notification scheduled: ${kind.name}');
    } on Object catch (e, stackTrace) {
      await errorReportingService.recordError(
        e,
        stackTrace,
        reason: 'Scheduling a ${kind.name} notification failed',
      );
    }
  }
}

final notificationService = _NotificationService();
