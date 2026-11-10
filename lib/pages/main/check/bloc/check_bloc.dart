import 'dart:async';

import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wc_dart_framework/wc_dart_framework.dart';

import '../../../../engine/heat_engine.dart';
import '../../../../engine/signal_collector.dart';
import '../../../../engine/text_heat.dart';
import '../../../../models/check_outcome.dart';
import '../../../../models/data/baseline_data.dart';
import '../../../../models/data/user_settings_data.dart';
import '../../../../models/enums/check_action.dart';
import '../../../../models/enums/check_kind.dart';
import '../../../../services/analytics_service.dart';
import '../../../../services/error_reporting_service.dart';
import '../../../../services/measurement_session.dart';
import '../../../../services/records_service.dart';
import '../../../../services/share_service.dart';
import '../../../../widgets/cubit/cubit.dart';
import 'check_state.dart';

part 'check_bloc.bloc.g.dart';

final _logger = Logger('check_bloc.dart');

/// One ~20-second check of pulse and expression, then the heat engine
/// (docs/03-heat-engine.md, docs/05-architecture.md).
@BlocGen()
class CheckBloc extends BVCubit<CheckState, CheckStateBuilder>
    with _$CheckBlocMixin {
  CheckBloc({
    required this.text,
    required this.recipient,
    required this.baseline,
    required this.settings,
  }) : super(CheckState()) {
    _session = MeasurementSession(
      operation: 'check',
      onRunning: _onRunning,
      onSample: _onSample,
      onHint: (hint) => emit(state.rebuild((b) => b.hint = hint)),
      onFailure: (failure) {
        _stopTimer();
        emit(
          state.rebuild(
            (b) => b
              ..phase = CheckPhase.failed
              ..failure = failure,
          ),
        );
      },
      onInterrupted: _onInterrupted,
    );
    _lifecycle = AppLifecycleListener(onResume: _onResume);
  }

  factory CheckBloc.of(BuildContext context) =>
      BlocProvider.of<CheckBloc>(context);

  /// How long a check measures. The first pulse value takes ~12 s.
  static const Duration duration = Duration(seconds: 20);

  /// Waits up to this long in total for the pulse to settle.
  static const Duration maxDuration = Duration(seconds: 30);

  /// The check's pulse is the median of the last 5 seconds.
  static const int pulseWindow = 10;

  /// Pulse samples (one per half second) to finish on time.
  static const int minPulseSamples = 4;

  /// Face frames needed for a result: 3 seconds.
  static const int minExpressionSamples = 6;

  final String text;
  final String? recipient;
  final BaselineData? baseline;
  final UserSettingsData settings;

  late final MeasurementSession _session;
  late final AppLifecycleListener _lifecycle;
  final _stopwatch = clock.stopwatch();
  Timer? _ticker;

  Future<void> start() async {
    _stopTimer();
    emit(CheckState());
    unawaited(analyticsService.logCheckStarted());
    errorReportingService.log('Check started');
    await _session.start();
  }

  void _onRunning() {
    _stopwatch
      ..reset()
      ..start();
    _ticker = Timer.periodic(const Duration(milliseconds: 200), (_) => _tick());
    emit(state.rebuild((b) => b.phase = CheckPhase.measuring));
  }

  void _onSample(SignalCollector collector) {
    final pulse = collector.latestPulse;
    if (pulse != state.livePulse) {
      emit(state.rebuild((b) => b.livePulse = pulse));
    }
  }

  void _tick() {
    final elapsed = _stopwatch.elapsed;
    final progress = elapsed.inMilliseconds / duration.inMilliseconds;
    final left = (duration - elapsed).inMilliseconds / 1000;
    emit(
      state.rebuild(
        (b) => b
          ..progress = progress.clamp(0, 1)
          ..secondsLeft = left <= 0 ? 0 : left.ceil(),
      ),
    );
    final enoughPulse = _session.collector.pulseCount >= minPulseSamples;
    if (elapsed >= duration && (enoughPulse || elapsed >= maxDuration)) {
      unawaited(_finish());
    }
  }

  Future<void> _finish() async {
    _stopTimer();
    await _session.stop();
    emit(state.rebuild((b) => b.phase = CheckPhase.analyzing));

    final collector = _session.collector;
    if (collector.expressionCount < minExpressionSamples) {
      emit(
        state.rebuild(
          (b) => b
            ..phase = CheckPhase.failed
            ..couldNotSeeFace = true,
        ),
      );
      return;
    }

    final pulse = collector.pulseMedian(lastN: pulseWindow);
    final anger = collector.angerMean();
    final textHeat = TextHeat.analyze(text);
    final result = HeatEngine.evaluate(
      HeatInput(
        pulseBpm: pulse,
        baselinePulseBpm: baseline?.pulseBpm,
        angerLevel: anger,
        baselineAngerLevel: baseline?.angerLevel ?? 0,
        textHeat: textHeat,
        sensitivity: settings.sensitivity,
        autoTuneOffset: settings.autoTuneOffset,
      ),
    );

    // A short beat before the reveal, so the result lands as a moment.
    final reveal = Future<void>.delayed(const Duration(milliseconds: 900));
    final checkId = await recordsService.saveCheck(
      kind: CheckKind.check,
      heatLevel: result.level,
      score: result.score,
      pulseBpm: pulse,
      baselineId: baseline?.id,
      pulseDeltaPct: result.pulseDeltaPct,
      angerLevel: anger,
      textHeat: textHeat.points,
      sensitivity: settings.sensitivity,
    );
    await reveal;
    unawaited(analyticsService.logCheckCompleted());
    emit(
      state.rebuild(
        (b) => b
          ..phase = CheckPhase.done
          ..outcome = CheckOutcome(
            checkId: checkId,
            result: result,
            text: text,
            recipient: recipient,
            pulseBpm: pulse,
            baselinePulseBpm: baseline?.pulseBpm,
            angerLevel: anger,
          ),
      ),
    );
  }

  void _onInterrupted() {
    _stopTimer();
    emit(CheckState((b) => b.phase = CheckPhase.interrupted));
    unawaited(_saveUnfinished(CheckAction.interrupted));
  }

  /// Back from the background: the check starts again from zero.
  void _onResume() {
    if (state.phase == CheckPhase.interrupted) {
      unawaited(start());
    }
  }

  /// The user backed out mid-check.
  Future<void> cancel() async {
    final measuring =
        state.phase == CheckPhase.starting ||
        state.phase == CheckPhase.measuring;
    _stopTimer();
    await _session.stop();
    if (measuring) {
      unawaited(analyticsService.logCheckCancelled());
      await _saveUnfinished(CheckAction.cancelled);
    }
  }

  /// "Send without a check", offered when measuring is impossible. Nothing
  /// is recorded. True when the share sheet was used.
  Future<bool> sendUnchecked() => shareService.shareText(text);

  Future<void> _saveUnfinished(CheckAction action) async {
    try {
      await recordsService.saveCheck(
        kind: CheckKind.check,
        heatLevel: null,
        score: null,
        pulseBpm: null,
        baselineId: baseline?.id,
        pulseDeltaPct: null,
        angerLevel: null,
        textHeat: null,
        sensitivity: settings.sensitivity,
        action: action,
      );
    } on Object catch (e) {
      // Already reported by recordsService; an unsaved cancel is harmless.
      _logger.warning('Saving an unfinished check failed: $e');
    }
  }

  /// From the screen's `CameraOrb`: the camera preview exists.
  void previewReady() => _session.previewReady();

  void previewGone() => _session.previewGone();

  void _stopTimer() {
    _ticker?.cancel();
    _ticker = null;
    _stopwatch.stop();
  }

  @override
  Future<void> close() async {
    _stopTimer();
    _lifecycle.dispose();
    await _session.stop();
    return super.close();
  }
}
