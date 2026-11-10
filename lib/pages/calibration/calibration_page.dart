import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../widgets/app_scaffold.dart';
import 'bloc/calibration_bloc.dart';
import 'calibration_body.dart';

/// The 30-second calm reading: in onboarding, and from Settings → Redo
/// calibration.
class CalibrationPage extends StatelessWidget {
  static const String ROUTE_NAME = 'calibration';

  /// In onboarding, finishing completes onboarding; from Settings it
  /// returns.
  final bool fromOnboarding;

  const CalibrationPage({super.key, this.fromOnboarding = false});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => CalibrationBloc(),
      child: AppScaffold(
        appBar: AppBar(),
        body: CalibrationBody(fromOnboarding: fromOnboarding),
      ),
    );
  }
}
