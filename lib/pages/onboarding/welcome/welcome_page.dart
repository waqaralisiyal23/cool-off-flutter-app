import 'package:flutter/material.dart';

import '../../../widgets/app_scaffold.dart';
import 'welcome_body.dart';

class WelcomePage extends StatelessWidget {
  static const String ROUTE_NAME = '/';

  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppScaffold(body: WelcomeBody());
  }
}
