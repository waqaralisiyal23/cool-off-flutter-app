import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../bloc/draft_bloc.dart';
import '../../../bloc/settings_bloc.dart';
import '../../../extension/context.dart';
import '../../../models/check_outcome.dart';
import '../../../models/enums/heat_level.dart';
import '../cooldown/cooldown_page.dart';
import '../tabs/bloc/tabs_bloc.dart';
import 'bloc/result_state.dart';

/// Where the app goes after a result (or a cool-down's re-check) is acted
/// on. Shared by both screens.
void navigateAfterChoice(
  BuildContext context, {
  required ResultChoice choice,
  required CheckOutcome outcome,
  DateTime? heldUntil,
}) {
  final messenger = ScaffoldMessenger.of(context);
  final draft = DraftBloc.of(context);
  final tabs = TabsBloc.of(context);
  void say(String text) => messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(text)));

  switch (choice) {
    case ResultChoice.sent:
      final heated = outcome.result.level == HeatLevel.heated;
      final checkin = SettingsBloc.of(context).state?.checkinEnabled ?? false;
      draft.clear();
      context.popToRoot();
      say(
        !heated
            ? 'Sent. Nicely done.'
            : checkin
            ? "Sent. Tomorrow morning we'll ask how it went."
            : 'Sent.',
      );
    case ResultChoice.held:
      draft.clear();
      tabs.select(MainTab.held);
      context.popToRoot();
      final time = heldUntil == null
          ? ''
          : ' until ${DateFormat.jm().format(heldUntil)}';
      say("Held$time. We'll let you know when it's ready.");
    case ResultChoice.coolDown:
      context.pushReplacementNamed(CooldownPage.ROUTE_NAME, arguments: outcome);
    case ResultChoice.edited:
      context.pop();
    case ResultChoice.discarded:
      draft.clear();
      context.popToRoot();
      say('Message deleted.');
  }
}
