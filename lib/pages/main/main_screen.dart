import 'package:flutter/material.dart';

import 'main_page.dart';

class MainScreen extends Page {
  const MainScreen() : super(key: const ValueKey('main'));

  @override
  Route createRoute(BuildContext context) {
    return MaterialPageRoute(settings: this, builder: (_) => const MainPage());
  }
}
