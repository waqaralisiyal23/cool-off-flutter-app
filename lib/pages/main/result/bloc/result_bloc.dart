import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wc_dart_framework/wc_dart_framework.dart';

import '../../../../models/check_outcome.dart';
import '../../../../models/data/user_settings_data.dart';
import '../../../../services/outcome_service.dart';
import '../../../../widgets/cubit/cubit.dart';
import 'result_state.dart';

part 'result_bloc.bloc.g.dart';

final _logger = Logger('result_bloc.dart');

/// Send, hold, cool down, edit or delete after a check. One choice per
/// result: later taps are ignored.
@BlocGen()
class ResultBloc extends BVCubit<ResultState, ResultStateBuilder>
    with _$ResultBlocMixin {
  ResultBloc({
    required this.outcome,
    required this.settings,
    this.demoCheckinsNow = false,
  }) : super(ResultState());

  factory ResultBloc.of(BuildContext context) =>
      BlocProvider.of<ResultBloc>(context);

  final CheckOutcome outcome;
  final UserSettingsData settings;

  /// QA demo mode: the check-in notification comes a minute after a heated
  /// send instead of the next morning.
  final bool demoCheckinsNow;

  bool get _locked => state.isBusy || state.choice != null;

  Future<void> send({Rect? origin}) => _run(() async {
    final sent = await outcomeService.send(
      outcome,
      settings: settings,
      origin: origin,
      checkinSoon: demoCheckinsNow,
    );
    if (sent) {
      emit(state.rebuild((b) => b.choice = ResultChoice.sent));
    }
  });

  Future<void> hold() => _run(() async {
    final until = await outcomeService.hold(outcome, settings: settings);
    emit(
      state.rebuild(
        (b) => b
          ..choice = ResultChoice.held
          ..heldUntil = until,
      ),
    );
  });

  Future<void> coolDown() => _run(() async {
    await outcomeService.startCooldown(outcome);
    emit(state.rebuild((b) => b.choice = ResultChoice.coolDown));
  });

  Future<void> edit() => _run(() async {
    await outcomeService.edit(outcome);
    emit(state.rebuild((b) => b.choice = ResultChoice.edited));
  });

  Future<void> discard() => _run(() async {
    await outcomeService.discard(outcome);
    emit(state.rebuild((b) => b.choice = ResultChoice.discarded));
  });

  Future<void> _run(Future<void> Function() action) async {
    if (_locked) {
      return;
    }
    emit(
      state.rebuild(
        (b) => b
          ..isBusy = true
          ..error = null,
      ),
    );
    try {
      await action();
    } on Object catch (e) {
      _logger.warning('Result action failed: $e');
      emit(
        state.rebuild((b) => b.error = "That didn't work. Please try again."),
      );
    } finally {
      emit(state.rebuild((b) => b.isBusy = false));
    }
  }
}
