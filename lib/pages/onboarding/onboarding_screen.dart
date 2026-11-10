import 'package:flutter/material.dart';

import 'onboarding_page.dart';

class OnboardingScreen extends Page {
  const OnboardingScreen() : super(key: const ValueKey('onboarding'));

  @override
  Route createRoute(BuildContext context) {
    return MaterialPageRoute(
      settings: this,
      builder: (_) => const OnboardingPage(),
    );
  }
}
