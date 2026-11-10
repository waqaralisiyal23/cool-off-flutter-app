import 'dart:async';

import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wc_dart_framework/wc_dart_framework.dart';

import '../../../../engine/baseline_calculator.dart';
import '../../../../engine/signal_collector.dart';
import '../../../../services/analytics_service.dart';
import '../../../../services/measurement_session.dart';
import '../../../../services/records_service.dart';
import '../../../../widgets/cubit/cubit.dart';
import 'calibration_state.dart';

part 'calibration_bloc.bloc.g.dart';

/// The 30-second calm reading that gives the user's usual pulse and resting
/// expression (docs/03-heat-engine.md).
@BlocGen()
class CalibrationBloc extends BVCubit<CalibrationState, CalibrationStateBuilder>
    with _$CalibrationBlocMixin {
  CalibrationBloc() : super(CalibrationState()) {
    _session = MeasurementSession(
      operation: 'calibration',
      onRunning: _onRunning,
      onSample: _onSample,
      onHint: (hint) => emit(state.rebuild((b) => b.hint = hint)),
      onFailure: (failure) => emit(
        state.rebuild(
          (b) => b
            ..phase = CalibrationPhase.failed
            ..failure = failure,
        ),
      ),
      onInterrupted: _onInterrupted,
    );
  }

  factory CalibrationBloc.of(BuildContext context) =>
      BlocProvider.of<CalibrationBloc>(context);

  /// If the pulse is slow to settle, wait up to this long in total.
  static const Duration _maxDuration = Duration(seconds: 45);

  late final MeasurementSession _session;
  final _stopwatch = clock.stopwatch();
  Timer? _ticker;

  Future<void> start() async {
    _resetTimer();
    emit(
      CalibrationState(
        (b) => b
          ..phase = CalibrationPhase.starting
          ..wasInterrupted = state.wasInterrupted,
      ),
    );
    await _session.start();
  }

  void _onRunning() {
    _stopwatch
      ..reset()
      ..start();
    _ticker = Timer.periodic(const Duration(milliseconds: 200), (_) => _tick());
    emit(
      state.rebuild(
        (b) => b
          ..phase = CalibrationPhase.measuring
          ..wasInterrupted = false,
      ),
    );
  }

  void _onSample(SignalCollector collector) {
    final pulse = collector.latestPulse;
    if (pulse != state.livePulse) {
      emit(state.rebuild((b) => b.livePulse = pulse));
    }
  }

  void _tick() {
    final elapsed = _stopwatch.elapsed;
    final progress =
        elapsed.inMilliseconds / BaselineCalculator.duration.inMilliseconds;
    emit(state.rebuild((b) => b.progress = progress.clamp(0, 1)));
    final enoughPulse =
        _session.collector.pulseCount >= BaselineCalculator.minPulseSamples;
    if (elapsed >= BaselineCalculator.duration &&
        (enoughPulse || elapsed >= _maxDuration)) {
      unawaited(_finish());
    }
  }

  Future<void> _finish() async {
    _resetTimer();
    await _session.stop();
    final outcome = BaselineCalculator.calculate(_session.collector);
    final values = outcome.values;
    if (values == null) {
      emit(
        state.rebuild(
          (b) => b
            ..phase = CalibrationPhase.failed
            ..baselineFailure = outcome.failure,
        ),
      );
      return;
    }
    emit(state.rebuild((b) => b.phase = CalibrationPhase.saving));
    await recordsService.saveBaseline(
      pulseBpm: values.pulseBpm,
      angerLevel: values.angerLevel,
      sampleCount: values.sampleCount,
    );
    unawaited(analyticsService.logBaselineCompleted());
    emit(
      state.rebuild(
        (b) => b
          ..phase = CalibrationPhase.done
          ..result = values,
      ),
    );
  }

  void _onInterrupted() {
    _resetTimer();
    emit(CalibrationState((b) => b.wasInterrupted = true));
  }

  /// Stops the reading and goes back to the tips.
  Future<void> cancel() async {
    _resetTimer();
    await _session.stop();
    emit(CalibrationState());
  }

  /// From the screen's `CameraOrb`: the camera preview exists.
  void previewReady() => _session.previewReady();

  void previewGone() => _session.previewGone();

  void _resetTimer() {
    _ticker?.cancel();
    _ticker = null;
    _stopwatch.stop();
  }

  @override
  Future<void> close() async {
    _resetTimer();
    await _session.stop();
    return super.close();
  }
}
