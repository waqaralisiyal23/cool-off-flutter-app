import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../bloc/app_preferences_bloc.dart';
import '../../../bloc/settings_bloc.dart';
import '../../../models/check_outcome.dart';
import '../../../widgets/app_scaffold.dart';
import 'bloc/result_bloc.dart';
import 'result_body.dart';

/// Calm / Warm / Heated, with reasons and what to do next
/// (docs/02-features.md §5).
class ResultPage extends StatelessWidget {
  static const String ROUTE_NAME = 'main/result';

  final CheckOutcome outcome;

  const ResultPage({super.key, required this.outcome});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ResultBloc(
        outcome: outcome,
        settings: SettingsBloc.of(context).state!,
        demoCheckinsNow: AppPreferencesBloc.of(context).state.demoCheckinsNow,
      ),
      child: const AppScaffold(body: ResultBody()),
    );
  }
}
