import 'package:flutter/material.dart';

import '../../widgets/navigator/navigator.dart';
import 'home/home_page.dart';

/// Global route observer for [RouteAware] subscriptions.
final RouteObserver<ModalRoute<void>> routeObserver =
    RouteObserver<ModalRoute<void>>();

/// The main flow of the app, with its own navigator and named routes.
class MainPage extends StatelessWidget {
  const MainPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AppNavigator(
      initialRoute: HomePage.ROUTE_NAME,
      createNavigatorProvider: (_) => MainNavigator(),
      getPage: _getPage,
      observers: [routeObserver],
    );
  }

  Widget? _getPage(BuildContext _, RouteSettings settings) {
    switch (settings.name) {
      case HomePage.ROUTE_NAME:
        return const HomePage();

      default:
        return null;
    }
  }
}

class MainNavigator extends NavigatorProvider {
  MainNavigator() : super(navigatorKey: GlobalKey());

  static NavigatorState of(BuildContext context) =>
      NavigatorProvider.of<MainNavigator>(context);
}
