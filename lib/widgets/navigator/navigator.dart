import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AppNavigator<NP extends NavigatorProvider> extends StatelessWidget {
  final String initialRoute;
  final NP Function(BuildContext) createNavigatorProvider;
  final Widget? Function(BuildContext, RouteSettings) getPage;
  final List<NavigatorObserver> observers;

  const AppNavigator({
    super.key,
    required this.initialRoute,
    required this.createNavigatorProvider,
    required this.getPage,
    this.observers = const [],
  });

  @override
  Widget build(BuildContext context) {
    return InheritedProvider<NP>(
      create: createNavigatorProvider,
      child: Builder(
        builder: (context) {
          final navigatorKey = Provider.of<NP>(context)._navigatorKey;
          return NavigatorPopHandler(
            onPopWithResult: (result) => navigatorKey.currentState?.maybePop(),
            child: Navigator(
              key: navigatorKey,
              initialRoute: initialRoute,
              onGenerateRoute: _onGenerateRoute,
              onDidRemovePage: (page) {},
              observers: observers,
            ),
          );
        },
      ),
    );
  }

  Route<dynamic>? _onGenerateRoute(RouteSettings settings) {
    FocusManager.instance.primaryFocus?.unfocus();
    return MaterialPageRoute(
      builder: (context) {
        final page = getPage(context, settings);
        if (page == null) {
          throw ArgumentError('Route ${settings.name} not handled yet');
        }
        return page;
      },
      settings: settings,
    );
  }
}

abstract class NavigatorProvider {
  final GlobalKey<NavigatorState> _navigatorKey;

  const NavigatorProvider({required this._navigatorKey});

  static NavigatorState of<NP extends NavigatorProvider>(
    BuildContext context,
  ) => Provider.of<NP>(context)._navigatorKey.currentState!;
}
