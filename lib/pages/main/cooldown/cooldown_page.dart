import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../bloc/baseline_bloc.dart';
import '../../../bloc/app_preferences_bloc.dart';
import '../../../bloc/settings_bloc.dart';
import '../../../models/check_outcome.dart';
import '../../../widgets/app_scaffold.dart';
import 'bloc/cooldown_bloc.dart';
import 'cooldown_body.dart';

/// Extra 1: cool down with the live pulse graph, then before/after.
class CooldownPage extends StatelessWidget {
  static const String ROUTE_NAME = 'main/cooldown';

  final CheckOutcome outcome;

  const CooldownPage({super.key, required this.outcome});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => CooldownBloc(
        original: outcome,
        baseline: BaselineBloc.of(context).state,
        settings: SettingsBloc.of(context).state!,
        demoCheckinsNow: AppPreferencesBloc.of(context).state.demoCheckinsNow,
      )..start(),
      child: const AppScaffold(body: CooldownBody()),
    );
  }
}
