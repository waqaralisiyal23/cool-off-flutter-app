import 'package:flutter/material.dart';

extension XBuildContext on BuildContext {
  /// The nearest [NavigatorState].
  ///
  /// Capture this *before* an `await` when you need to navigate after the async
  /// gap — `context` may be unmounted by then, but a captured navigator is
  /// still valid:
  ///
  /// ```dart
  /// final navigator = context.navigator;
  /// final confirmed = await showDialog<bool>(...);
  /// if (confirmed ?? false) navigator.pop();
  /// ```
  NavigatorState get navigator => Navigator.of(this);

  /// Pushes [page] on the nearest navigator without a named route.
  ///
  /// Prefer [pushNamed]; this is for screens that have no `ROUTE_NAME` because
  /// they are only reachable from one place.
  Future<T?> push<T extends Object?>(Widget page) =>
      Navigator.push<T>(this, MaterialPageRoute<T>(builder: (_) => page));

  /// Pushes [page] full-screen on the **root** navigator, above any nested one
  /// such as a bottom-nav shell.
  ///
  /// Use when the pushed screen must cover the shell rather than appear inside
  /// the current tab.
  Future<T?> pushRoot<T extends Object?>(Widget page) => Navigator.of(
    this,
    rootNavigator: true,
  ).push<T>(MaterialPageRoute<T>(builder: (_) => page));

  Future<T?> pushNamed<T extends Object?>(
    String routeName, {
    Object? arguments,
  }) => Navigator.pushNamed<T>(this, routeName, arguments: arguments);

  /// Pushes [routeName] and returns what it popped, when that is a [T].
  ///
  /// Use this rather than `pushNamed<T>` for a screen that hands something
  /// back. `AppNavigator` builds every route through a single
  /// `onGenerateRoute` factory, which has no way to know the result type and
  /// so can only produce a `MaterialPageRoute<dynamic>`. Asking `pushNamed`
  /// for a typed route makes Flutter cast that to a `Route<T?>` it is not,
  /// and the push throws before the screen ever opens.
  ///
  /// So the route is pushed untyped and its result checked here. Anything
  /// else — including the null a dismissed screen pops — comes back as null.
  Future<T?> pushNamedForResult<T extends Object>(
    String routeName, {
    Object? arguments,
  }) async {
    final result = await Navigator.pushNamed<Object?>(
      this,
      routeName,
      arguments: arguments,
    );
    return result is T ? result : null;
  }

  Future<T?> pushReplacementNamed<T extends Object?, TO extends Object?>(
    String routeName, {
    Object? arguments,
    TO? result,
  }) => Navigator.pushReplacementNamed<T, TO>(
    this,
    routeName,
    arguments: arguments,
    result: result,
  );

  Future<T?> pushNamedAndRemoveUntil<T extends Object?>(
    String newRouteName,
    bool Function(Route<dynamic>) predicate, {
    Object? arguments,
  }) => Navigator.pushNamedAndRemoveUntil<T>(
    this,
    newRouteName,
    predicate,
    arguments: arguments,
  );

  Future<Object?> popAndPushNamed(
    String routeName, {
    Object? arguments,
    Object? result,
  }) => Navigator.popAndPushNamed(
    this,
    routeName,
    arguments: arguments,
    result: result,
  );

  Future<T?> pushAndRemoveAll<T extends Object?>(
    String routeName, {
    Object? arguments,
  }) => Navigator.pushNamedAndRemoveUntil<T>(
    this,
    routeName,
    (route) => false,
    arguments: arguments,
  );

  void popToRoot() => Navigator.popUntil(this, (route) => route.isFirst);

  void popUntil(bool Function(Route<dynamic>) predicate) =>
      Navigator.popUntil(this, predicate);

  void pop<T extends Object?>([T? result]) => Navigator.pop<T>(this, result);

  bool canPop() => Navigator.canPop(this);

  Future<bool> maybePop<T extends Object?>([T? result]) =>
      Navigator.maybePop<T>(this, result);
}
