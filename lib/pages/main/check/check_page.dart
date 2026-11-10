import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../bloc/baseline_bloc.dart';
import '../../../bloc/draft_bloc.dart';
import '../../../bloc/settings_bloc.dart';
import '../../../widgets/app_scaffold.dart';
import 'bloc/check_bloc.dart';
import 'check_body.dart';

/// The ~20-second check of the current draft (docs/02-features.md §4).
class CheckPage extends StatelessWidget {
  static const String ROUTE_NAME = 'main/check';

  const CheckPage({super.key});

  @override
  Widget build(BuildContext context) {
    final draft = DraftBloc.of(context).state;
    return BlocProvider(
      create: (_) => CheckBloc(
        text: draft.text.trim(),
        recipient: draft.recipientOrNull,
        baseline: BaselineBloc.of(context).state,
        settings: SettingsBloc.of(context).state!,
      )..start(),
      child: const AppScaffold(body: CheckBody()),
    );
  }
}
