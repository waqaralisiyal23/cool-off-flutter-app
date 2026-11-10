import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/app_theme.dart';

class AppScaffold extends StatelessWidget {
  final PreferredSizeWidget? appBar;
  final Widget? body;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;

  /// Where [floatingActionButton] sits. Defaults to Material's bottom-right.
  final FloatingActionButtonLocation? floatingActionButtonLocation;

  /// How [floatingActionButton] enters, leaves and moves between locations.
  /// Null keeps Material's scale-and-slide.
  final FloatingActionButtonAnimator? floatingActionButtonAnimator;

  /// Overrides the themed page colour. Set on the scaffold rather than painted
  /// behind [body], which the scaffold lets shrink to its content and would
  /// leave the page colour showing underneath.
  final Color? backgroundColor;

  /// Lets [body] extend behind [bottomNavigationBar], for floating bars that
  /// the content should scroll underneath.
  final bool extendBody;

  const AppScaffold({
    super.key,
    this.appBar,
    this.body,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.floatingActionButtonAnimator,
    this.backgroundColor,
    this.extendBody = false,
  });

  @override
  Widget build(BuildContext context) {
    // Light status bar icons on the dark theme unless the page says otherwise.
    //
    // A screen without an app bar would otherwise set no style at all and keep
    // whatever the previous screen left behind. An app bar declares its own
    // style, and being deeper in the tree it wins over this default.
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: AppTheme.systemUi,
      child: Scaffold(
        appBar: appBar,
        body: body,
        bottomNavigationBar: bottomNavigationBar,
        floatingActionButton: floatingActionButton,
        floatingActionButtonLocation: floatingActionButtonLocation,
        floatingActionButtonAnimator: floatingActionButtonAnimator,
        backgroundColor: backgroundColor,
        extendBody: extendBody,
      ),
    );
  }
}
