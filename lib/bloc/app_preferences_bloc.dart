import 'dart:async';

import 'package:built_value/serializer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:uuid/uuid.dart';
import 'package:wc_dart_framework/wc_dart_framework.dart';

import '../models/serializers.dart';
import '../services/analytics_service.dart';
import '../utils/firebase_utils.dart';
import '../widgets/cubit/cubit.dart';
import 'states/app_preferences_state.dart';

part 'app_preferences_bloc.bloc.g.dart';

final _logger = Logger('app_preferences_bloc.dart');

/// This install's preferences: device id, consent, onboarding, and the
/// analytics and crash-report choices. Global and hydrated.
@BlocGen()
class AppPreferencesBloc
    extends BVCubit<AppPreferencesState, AppPreferencesStateBuilder>
    with
        HydratedMixin,
        _$AppPreferencesBlocMixin,
        _$AppPreferencesBlocHydratedMixin {
  AppPreferencesBloc() : super(AppPreferencesState()) {
    hydrate();
  }

  factory AppPreferencesBloc.of(BuildContext context) =>
      BlocProvider.of<AppPreferencesBloc>(context);

  /// Applies the saved analytics and crash-report choices. Call once at
  /// startup, after Firebase.
  Future<void> applyConsent() => FirebaseUtils.applyConsent(
    analyticsEnabled: state.analyticsEnabled,
    crashReportsEnabled: state.crashReportsEnabled,
  );

  void acceptConsent() {
    emit(
      state.rebuild(
        (b) => b.consentVersion = AppPreferencesState.currentConsentVersion,
      ),
    );
  }

  /// Consent and baseline done: the router swaps the main app in.
  void completeOnboarding() {
    if (state.isOnboardingComplete) {
      return;
    }
    emit(state.rebuild((b) => b.isOnboardingComplete = true));
    unawaited(analyticsService.logOnboardingCompleted());
  }

  Future<void> setAnalyticsEnabled(bool enabled) async {
    emit(state.rebuild((b) => b.analyticsEnabled = enabled));
    await applyConsent();
  }

  Future<void> setCrashReportsEnabled(bool enabled) async {
    emit(state.rebuild((b) => b.crashReportsEnabled = enabled));
    await applyConsent();
  }

  /// "Delete all my data": a new device id, no consent, onboarding again.
  /// The analytics choices go back to their defaults.
  Future<void> resetAll() async {
    emit(AppPreferencesState((b) => b.deviceId = const Uuid().v4()));
    await applyConsent();
  }
}
