import 'package:flutter/material.dart';

import '../../../widgets/app_scaffold.dart';
import 'home_body.dart';

class HomePage extends StatelessWidget {
  static const String ROUTE_NAME = '/';

  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppScaffold(body: HomeBody());
  }
}
