import 'package:flutter/material.dart';

import '../pages/main/main_screen.dart';

/// The app's single root navigator.
///
/// Cool Off has no accounts. Onboarding (consent → baseline) will gate the
/// main flow through `AppPreferencesBloc.isOnboardingComplete`
/// (docs/05-architecture.md); until it exists, the main flow always shows.
class AppRouterDelegate extends RouterDelegate<Object>
    with ChangeNotifier, PopNavigatorRouterDelegateMixin<Object> {
  final _navigatorKey = GlobalKey<NavigatorState>();

  @override
  GlobalKey<NavigatorState>? get navigatorKey => _navigatorKey;

  @override
  Widget build(BuildContext context) {
    return Navigator(
      key: navigatorKey,
      pages: const [MainScreen()],
      onDidRemovePage: (page) {},
    );
  }

  @override
  Future<void> setNewRoutePath(Object _) async {}
}
