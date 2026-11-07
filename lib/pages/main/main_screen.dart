import 'package:flutter/material.dart';

import 'main_page.dart';

class MainScreen extends Page {
  const MainScreen();

  @override
  Route createRoute(BuildContext context) {
    return MaterialPageRoute(settings: this, builder: (_) => const MainPage());
  }
}
