import 'dart:async';

import 'package:flutter/material.dart';

import '../bloc/app_preferences_bloc.dart';
import '../bloc/states/app_preferences_state.dart';
import '../pages/main/main_screen.dart';
import '../pages/onboarding/onboarding_screen.dart';

/// The app's single root navigator.
///
/// Cool Off has no accounts. `AppPreferencesBloc` gates the flows
/// (docs/05-architecture.md): onboarding (welcome, consent, permissions,
/// baseline) until it is complete, then the main app. "Delete all my data"
/// resets the preferences, which swaps onboarding back in.
class AppRouterDelegate extends RouterDelegate<Object>
    with ChangeNotifier, PopNavigatorRouterDelegateMixin<Object> {
  AppRouterDelegate({required AppPreferencesBloc preferences})
    : _showMain = _isMain(preferences.state) {
    _subscription = preferences.stream.listen((state) {
      final showMain = _isMain(state);
      if (showMain != _showMain) {
        _showMain = showMain;
        notifyListeners();
      }
    });
  }

  final _navigatorKey = GlobalKey<NavigatorState>();
  late final StreamSubscription<AppPreferencesState> _subscription;
  bool _showMain;

  static bool _isMain(AppPreferencesState state) =>
      state.isOnboardingComplete && !state.needsConsent;

  @override
  GlobalKey<NavigatorState>? get navigatorKey => _navigatorKey;

  @override
  Widget build(BuildContext context) {
    return Navigator(
      key: navigatorKey,
      pages: [if (_showMain) const MainScreen() else const OnboardingScreen()],
      onDidRemovePage: (page) {},
    );
  }

  @override
  Future<void> setNewRoutePath(Object _) async {}

  @override
  void dispose() {
    unawaited(_subscription.cancel());
    super.dispose();
  }
}
