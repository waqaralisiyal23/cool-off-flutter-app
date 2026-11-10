import 'dart:async';

import 'package:built_collection/built_collection.dart';

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
import '../../../../models/enums/check_kind.dart';
import '../../../../services/analytics_service.dart';
import '../../../../services/measurement_session.dart';
import '../../../../services/outcome_service.dart';
import '../../../../services/records_service.dart';
import '../../../../widgets/cubit/cubit.dart';
import '../../result/bloc/result_state.dart';
import 'cooldown_state.dart';

part 'cooldown_bloc.bloc.g.dart';

final _logger = Logger('cooldown_bloc.dart');

/// Extra 1 (docs/02-features.md §6): 60 seconds with the live pulse graph,
/// then an automatic 20-second re-check in the same camera session, then
/// before/after.
@BlocGen()
class CooldownBloc extends BVCubit<CooldownState, CooldownStateBuilder>
    with _$CooldownBlocMixin {
  CooldownBloc({
    required this.original,
    required this.baseline,
    required this.settings,
    this.demoCheckinsNow = false,
  }) : super(CooldownState()) {
    _session = MeasurementSession(
      operation: 'cooldown',
      onRunning: _onRunning,
      onSample: _onSample,
      onHint: (hint) => emit(state.rebuild((b) => b.hint = hint)),
      onFailure: (failure) {
        _stopTimer();
        emit(
          state.rebuild(
            (b) => b
              ..phase = CooldownPhase.failed
              ..failure = failure,
          ),
        );
      },
      onInterrupted: () {
        _stopTimer();
        emit(CooldownState((b) => b.phase = CooldownPhase.interrupted));
      },
    );
    _lifecycle = AppLifecycleListener(
      onResume: () {
        if (state.phase == CooldownPhase.interrupted) {
          unawaited(start());
        }
      },
    );
  }

  factory CooldownBloc.of(BuildContext context) =>
      BlocProvider.of<CooldownBloc>(context);

  static const Duration coolingDuration = Duration(seconds: 60);
  static const Duration recheckDuration = Duration(seconds: 20);
  static const Duration _total = Duration(seconds: 80);
  static const Duration _maxTotal = Duration(seconds: 90);

  final CheckOutcome original;
  final BaselineData? baseline;
  final UserSettingsData settings;

  /// QA demo mode: the check-in notification comes a minute after a heated
  /// send instead of the next morning.
  final bool demoCheckinsNow;

  late final MeasurementSession _session;
  late final AppLifecycleListener _lifecycle;
  final _stopwatch = clock.stopwatch();
  Timer? _ticker;
  int _lastSecond = -1;

  /// Where the re-check's expression frames start in the collector.
  int _recheckExpressionStart = 0;

  Future<void> start() async {
    _stopTimer();
    _lastSecond = -1;
    emit(CooldownState());
    await _session.start();
  }

  void _onRunning() {
    _stopwatch
      ..reset()
      ..start();
    _ticker = Timer.periodic(const Duration(milliseconds: 200), (_) => _tick());
    emit(state.rebuild((b) => b.phase = CooldownPhase.cooling));
  }

  void _onSample(SignalCollector collector) {
    final pulse = collector.latestPulse;
    if (pulse != state.livePulse) {
      emit(state.rebuild((b) => b.livePulse = pulse));
    }
  }

  void _tick() {
    final elapsed = _stopwatch.elapsed;
    final cooling = elapsed < coolingDuration;
    final phaseLeft = cooling ? coolingDuration - elapsed : _total - elapsed;
    final second = elapsed.inSeconds;
    final pulse = state.livePulse;
    emit(
      state.rebuild((b) {
        b
          ..progress = (elapsed.inMilliseconds / _total.inMilliseconds).clamp(
            0,
            1,
          )
          ..secondsLeft = phaseLeft.isNegative
              ? 0
              : (phaseLeft.inMilliseconds / 1000).ceil();
        if (second != _lastSecond && pulse != null) {
          b.pulseSeries.add(pulse);
        }
      }),
    );
    _lastSecond = second;

    if (!cooling && state.phase == CooldownPhase.cooling) {
      _recheckExpressionStart = _session.collector.expressionCount;
      emit(state.rebuild((b) => b.phase = CooldownPhase.rechecking));
    }
    final enoughPulse = _session.collector.pulseCount >= 4;
    if (elapsed >= _total && (enoughPulse || elapsed >= _maxTotal)) {
      unawaited(_finish());
    }
  }

  Future<void> _finish() async {
    _stopTimer();
    await _session.stop();
    emit(state.rebuild((b) => b.phase = CooldownPhase.analyzing));

    final collector = _session.collector;
    final recheckAnger = collector.angerValues
        .skip(_recheckExpressionStart)
        .toList();
    final anger = recheckAnger.isEmpty
        ? collector.angerMean()
        : recheckAnger.reduce((a, b) => a + b) / recheckAnger.length;
    final pulse = collector.pulseMedian(lastN: 10);
    final textHeat = TextHeat.analyze(original.text);
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
    final reveal = Future<void>.delayed(const Duration(milliseconds: 900));
    final checkId = await recordsService.saveCheck(
      kind: CheckKind.recheck,
      heatLevel: result.level,
      score: result.score,
      pulseBpm: pulse,
      baselineId: baseline?.id,
      pulseDeltaPct: result.pulseDeltaPct,
      angerLevel: anger,
      textHeat: textHeat.points,
      sensitivity: settings.sensitivity,
      previousCheckId: original.checkId,
    );
    await reveal;
    unawaited(analyticsService.logCooldownCompleted());
    emit(
      state.rebuild(
        (b) => b
          ..phase = CooldownPhase.done
          ..recheck = CheckOutcome(
            checkId: checkId,
            result: result,
            text: original.text,
            recipient: original.recipient,
            pulseBpm: pulse,
            baselinePulseBpm: baseline?.pulseBpm,
            angerLevel: anger,
            previous: original,
          ),
      ),
    );
  }

  // ─── Acting on the re-check ────────────────────────────────────────────
  Future<void> send({Rect? origin}) => _act((recheck) async {
    final sent = await outcomeService.send(
      recheck,
      settings: settings,
      origin: origin,
      checkinSoon: demoCheckinsNow,
    );
    return sent ? ResultChoice.sent : null;
  });

  Future<void> hold() => _act((recheck) async {
    final until = await outcomeService.hold(recheck, settings: settings);
    emit(state.rebuild((b) => b.heldUntil = until));
    return ResultChoice.held;
  });

  Future<void> edit() => _act((recheck) async {
    await outcomeService.edit(recheck);
    return ResultChoice.edited;
  });

  Future<void> discard() => _act((recheck) async {
    await outcomeService.discard(recheck);
    return ResultChoice.discarded;
  });

  Future<void> _act(
    Future<ResultChoice?> Function(CheckOutcome recheck) action,
  ) async {
    final recheck = state.recheck;
    if (recheck == null || state.isBusy || state.choice != null) {
      return;
    }
    emit(state.rebuild((b) => b.isBusy = true));
    try {
      final choice = await action(recheck);
      emit(state.rebuild((b) => b.choice = choice));
    } on Object catch (e) {
      _logger.warning('Cool-down action failed: $e');
    } finally {
      emit(state.rebuild((b) => b.isBusy = false));
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
