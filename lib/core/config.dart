import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../models/enums/environment.dart';

class _Config {
  String get appName => dotenv.env['APP_NAME']!;

  final environment = Environment.valueOf(
    const String.fromEnvironment('DART_ENV', defaultValue: 'qa'),
  );
}

final config = _Config();

/// Builds with the camera simulated: `--dart-define=SIMULATE_MEASUREMENT=true`,
/// honoured in QA builds only. For emulators and simulators, which cannot run
/// the SmartSpectra SDK, and for trying the app without a phone.
const bool simulateMeasurement = bool.fromEnvironment('SIMULATE_MEASUREMENT');
