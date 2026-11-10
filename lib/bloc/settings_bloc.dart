import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../models/data/user_settings_data.dart';
import '../services/settings_service.dart';
import '../utils/app_haptics.dart';
import '../widgets/cubit/cubit.dart';

/// The user's settings (the Drift `user_settings` row), followed live.
/// Null until the row is first read.
class SettingsBloc extends AppCubit<UserSettingsData?> {
  StreamSubscription<UserSettingsData?>? _subscription;

  SettingsBloc() : super(null);

  factory SettingsBloc.of(BuildContext context) =>
      BlocProvider.of<SettingsBloc>(context);

  /// Creates the row with the defaults if needed, then follows it.
  Future<void> start() async {
    final current = await settingsService.ensure();
    AppHaptics.enabled = current.hapticsEnabled;
    emit(current);
    await _subscription?.cancel();
    _subscription = settingsService.watch().listen((settings) {
      if (settings != null) {
        AppHaptics.enabled = settings.hapticsEnabled;
      }
      emit(settings);
    }, onError: addError);
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
