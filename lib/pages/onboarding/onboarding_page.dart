import 'package:flutter/material.dart';

import '../../widgets/navigator/navigator.dart';
import '../calibration/calibration_page.dart';
import 'consent/consent_page.dart';
import 'permissions/permissions_page.dart';
import 'welcome/welcome_page.dart';

/// First run: welcome → consent → permissions → calibration
/// (docs/02-features.md). Finishing calibration completes onboarding.
class OnboardingPage extends StatelessWidget {
  const OnboardingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AppNavigator(
      initialRoute: WelcomePage.ROUTE_NAME,
      createNavigatorProvider: (_) => OnboardingNavigator(),
      getPage: _getPage,
    );
  }

  Widget? _getPage(BuildContext _, RouteSettings settings) {
    switch (settings.name) {
      case WelcomePage.ROUTE_NAME:
        return const WelcomePage();
      case ConsentPage.ROUTE_NAME:
        return const ConsentPage();
      case PermissionsPage.ROUTE_NAME:
        return const PermissionsPage();
      case CalibrationPage.ROUTE_NAME:
        return const CalibrationPage(fromOnboarding: true);
      default:
        return null;
    }
  }
}

class OnboardingNavigator extends NavigatorProvider {
  OnboardingNavigator() : super(navigatorKey: GlobalKey());
}
