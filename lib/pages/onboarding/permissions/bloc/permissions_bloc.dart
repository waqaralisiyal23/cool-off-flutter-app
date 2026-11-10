import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wc_dart_framework/wc_dart_framework.dart';

import '../../../../services/measurement_service.dart';
import '../../../../services/notification_service.dart';
import '../../../../services/system_settings_service.dart';
import '../../../../widgets/cubit/cubit.dart';
import 'permissions_state.dart';

part 'permissions_bloc.bloc.g.dart';

/// Camera (required) and notifications (optional), each asked only after
/// the screen explains why.
@BlocGen()
class PermissionsBloc extends BVCubit<PermissionsState, PermissionsStateBuilder>
    with _$PermissionsBlocMixin {
  PermissionsBloc() : super(PermissionsState()) {
    // Back from the phone's settings: the camera may be allowed now.
    _lifecycle = AppLifecycleListener(onResume: () => unawaited(load()));
  }

  late final AppLifecycleListener _lifecycle;

  factory PermissionsBloc.of(BuildContext context) =>
      BlocProvider.of<PermissionsBloc>(context);

  Future<void> load() async {
    final camera = await measurementService.hasCameraPermission();
    final notifications = await notificationService.isAllowed();
    emit(
      state.rebuild(
        (b) => b
          ..cameraGranted = camera
          ..notificationsGranted = notifications,
      ),
    );
  }

  Future<void> requestCamera() async {
    final granted = await measurementService.requestCameraPermission();
    emit(
      state.rebuild(
        (b) => b
          ..cameraGranted = granted
          ..cameraDenied = !granted,
      ),
    );
  }

  /// After a refusal only the phone's settings can allow the camera.
  Future<void> openSettings() => systemSettingsService.openAppSettings();

  @override
  Future<void> close() {
    _lifecycle.dispose();
    return super.close();
  }

  Future<void> requestNotifications() async {
    final granted = await notificationService.requestPermission();
    emit(
      state.rebuild(
        (b) => b
          ..notificationsGranted = granted
          ..notificationsAsked = true,
      ),
    );
  }
}
