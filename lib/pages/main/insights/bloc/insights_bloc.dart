import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wc_dart_framework/wc_dart_framework.dart';

import '../../../../models/data/check_record_data.dart';
import '../../../../models/data/reflection_data.dart';
import '../../../../services/records_service.dart';
import '../../../../stats/insights.dart';
import '../../../../widgets/cubit/cubit.dart';
import 'insights_state.dart';

part 'insights_bloc.bloc.g.dart';

/// Insights from local history (`lib/stats/`), recomputed whenever checks or
/// check-in answers change.
@BlocGen()
class InsightsBloc extends BVCubit<InsightsState, InsightsStateBuilder>
    with _$InsightsBlocMixin {
  InsightsBloc() : super(InsightsState());

  factory InsightsBloc.of(BuildContext context) =>
      BlocProvider.of<InsightsBloc>(context);

  final List<StreamSubscription<Object?>> _subscriptions = [];
  List<CheckRecordData>? _checks;
  List<ReflectionData>? _reflections;

  void start() {
    _subscriptions
      ..add(
        recordsService.watchFinishedChecks().listen((checks) {
          _checks = checks;
          _compute();
        }, onError: addError),
      )
      ..add(
        recordsService.watchReflections().listen((reflections) {
          _reflections = reflections;
          _compute();
        }, onError: addError),
      );
  }

  void _compute() {
    final checks = _checks;
    final reflections = _reflections;
    if (checks == null || reflections == null) {
      return;
    }
    emit(
      state.rebuild(
        (b) => b.insights = Insights.compute(
          checks: checks,
          reflections: reflections,
          nowLocal: DateTime.now(),
        ),
      ),
    );
  }

  @override
  Future<void> close() async {
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    return super.close();
  }
}
