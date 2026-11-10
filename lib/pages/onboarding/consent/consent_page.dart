import 'package:flutter/material.dart';

import '../../../widgets/app_scaffold.dart';
import 'consent_body.dart';

/// What the camera does, what is stored, and the analytics choices, before
/// any camera use (docs/06-privacy-and-data.md).
class ConsentPage extends StatelessWidget {
  static const String ROUTE_NAME = 'onboarding/consent';

  const ConsentPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(appBar: AppBar(), body: const ConsentBody());
  }
}
