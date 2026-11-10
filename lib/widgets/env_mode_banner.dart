import 'package:flutter/material.dart';

import '../core/config.dart';
import '../models/enums/environment.dart';

class EnvModeBanner extends StatelessWidget {
  final Widget child;

  const EnvModeBanner({required this.child});

  @override
  Widget build(BuildContext context) {
    final dartEnv = config.environment;
    if (dartEnv == Environment.production) {
      return child;
    }
    final banner = Banner(
      message: dartEnv.name,
      textDirection: TextDirection.ltr,
      location: BannerLocation.topEnd,
      child: child,
    );
    if (!simulateMeasurement) {
      return banner;
    }
    // Readings are made up: never let a screenshot pass for a real one.
    return Banner(
      message: 'SIMULATED',
      textDirection: TextDirection.ltr,
      location: BannerLocation.bottomStart,
      child: banner,
    );
  }
}
