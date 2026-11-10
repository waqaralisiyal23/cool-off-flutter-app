import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../services/notification_service.dart';
import '../services/system_settings_service.dart';
import '../widgets/cubit/cubit.dart';

/// Whether Cool Off may post notifications: null until known. Checked again
/// whenever the app comes back to the front, since the user may have
/// changed it in the phone's settings.
class NotificationAccessBloc extends AppCubit<bool?> {
  NotificationAccessBloc() : super(null) {
    _lifecycle = AppLifecycleListener(onResume: () => unawaited(refresh()));
  }

  factory NotificationAccessBloc.of(BuildContext context) =>
      BlocProvider.of<NotificationAccessBloc>(context);

  late final AppLifecycleListener _lifecycle;

  Future<void> refresh() async => emit(await notificationService.isAllowed());

  /// Asks the system. After an earlier "no" the system no longer asks, so
  /// the phone's notification settings for Cool Off open instead.
  Future<void> enable() async {
    if (await notificationService.requestPermission()) {
      emit(true);
      return;
    }
    await systemSettingsService.openNotificationSettings();
  }

  @override
  Future<void> close() {
    _lifecycle.dispose();
    return super.close();
  }
}
