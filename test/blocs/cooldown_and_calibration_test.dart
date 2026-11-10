import 'package:cooloff/database/app_database.dart';
import 'package:cooloff/engine/baseline_calculator.dart';
import 'package:cooloff/engine/heat_engine.dart';
import 'package:cooloff/engine/text_heat.dart';
import 'package:cooloff/models/check_outcome.dart';
import 'package:cooloff/models/data/baseline_data.dart';
import 'package:cooloff/models/data/check_record_data.dart';
import 'package:cooloff/models/enums/check_kind.dart';
import 'package:cooloff/models/enums/heat_level.dart';
import 'package:cooloff/pages/calibration/bloc/calibration_bloc.dart';
import 'package:cooloff/pages/calibration/bloc/calibration_state.dart';
import 'package:cooloff/pages/main/cooldown/bloc/cooldown_bloc.dart';
import 'package:cooloff/pages/main/cooldown/bloc/cooldown_state.dart';
import 'package:cooloff/services/measurement_service.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartspectra_flutter/smartspectra_flutter.dart';

import '../support/fakes.dart';

const _halfSecond = Duration(milliseconds: 500);

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  late FakeMeasurementSource sdk;

  setUp(() {
    sdk = FakeMeasurementSource();
    measurementService = sdk;
    openTestDatabase();
    binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
  });

  tearDown(() => appDatabase.close());

  group('CooldownBloc', () {
    CheckOutcome heatedOriginal() {
      const text = 'YOU NEVER LISTEN!!! Unbelievable';
      final result = HeatEngine.evaluate(
        HeatInput(
          pulseBpm: 95,
          baselinePulseBpm: 70,
          angerLevel: 50,
          baselineAngerLevel: 5,
          textHeat: TextHeat.analyze(text),
        ),
      );
      return CheckOutcome(
        checkId: 'original-check',
        result: result,
        text: text,
        recipient: 'Sam',
        pulseBpm: 95,
        baselinePulseBpm: 70,
        angerLevel: 50,
      );
    }

    test(
      '60 s cooling, 20 s re-check in the same session, then before/after',
      () {
        fakeAsync((async) {
          final original = heatedOriginal();
          expect(original.result.level, HeatLevel.heated);
          final bloc = CooldownBloc(
            original: original,
            baseline: testBaseline(),
            settings: testSettings(),
          )..start();
          bloc.previewReady();
          async.flushMicrotasks();
          sdk.emitStatus(ProcessingStatus.running);
          async.flushMicrotasks();
          expect(bloc.state.phase, CooldownPhase.cooling);

          // The pulse settles from 95 to 72 and the face relaxes.
          for (var i = 0; i < 160; i++) {
            final second = i / 2;
            final pulse = second < 12
                ? null
                : (95 - (second - 12) * 0.6).clamp(72, 95).toDouble();
            sdk.emitFrame(pulse: pulse, angry: second < 60 ? 30 : 6);
            async.elapse(_halfSecond);
            if (i == 119) {
              expect(
                bloc.state.phase,
                CooldownPhase.rechecking,
                reason: 'at 60 s',
              );
              expect(sdk.startCalls, 1, reason: 'no second camera start');
            }
          }
          async.elapse(const Duration(seconds: 2));

          expect(bloc.state.phase, CooldownPhase.done);
          expect(
            bloc.state.pulseSeries.length,
            greaterThan(60),
            reason: 'one point a second',
          );
          final recheck = bloc.state.recheck!;
          expect(recheck.previous, same(original));
          expect(recheck.pulseBpm, 72);
          expect(
            recheck.result.level.rank,
            lessThan(original.result.level.rank),
          );
          expect(
            recheck.expressionHeat,
            1,
            reason: 'only the re-check window counts',
          );

          final records = <CheckRecordData>[];
          appDatabase
              .select(appDatabase.checkRecords)
              .get()
              .then(records.addAll);
          async.flushMicrotasks();
          expect(records.single.kind, CheckKind.recheck);
          expect(records.single.previousCheckId, 'original-check');
          bloc.close();
          async.flushMicrotasks();
        });
      },
    );
  });

  group('CalibrationBloc', () {
    void run(
      FakeAsync async,
      CalibrationBloc bloc, {
      required int seconds,
      double? pulse,
    }) {
      bloc.start();
      bloc.previewReady();
      async.flushMicrotasks();
      sdk.emitStatus(ProcessingStatus.running);
      async.flushMicrotasks();
      for (var i = 0; i < seconds * 2; i++) {
        sdk.emitFrame(pulse: i / 2 >= 12 ? pulse : null, angry: 4);
        async.elapse(_halfSecond);
      }
      async.flushMicrotasks();
    }

    test('a steady 30 s reading saves the baseline', () {
      fakeAsync((async) {
        final bloc = CalibrationBloc();
        run(async, bloc, seconds: 30, pulse: 68);
        expect(bloc.state.phase, CalibrationPhase.done);
        expect(bloc.state.result!.pulseBpm, 68);
        expect(bloc.state.result!.angerLevel, 4);

        BaselineData? saved;
        appDatabase.baselinesDao.getCurrent().then((b) => saved = b);
        async.flushMicrotasks();
        expect(saved!.pulseBpm, 68);
        bloc.close();
        async.flushMicrotasks();
      });
    });

    test('no steady pulse by 45 s fails with a reason and saves nothing', () {
      fakeAsync((async) {
        final bloc = CalibrationBloc();
        run(async, bloc, seconds: 46);
        expect(bloc.state.phase, CalibrationPhase.failed);
        expect(bloc.state.baselineFailure, BaselineFailure.notEnoughPulse);

        BaselineData? saved;
        appDatabase.baselinesDao.getCurrent().then((b) => saved = b);
        async.flushMicrotasks();
        expect(saved, isNull);
        bloc.close();
        async.flushMicrotasks();
      });
    });

    test('cancel goes back to the tips and releases the camera', () {
      fakeAsync((async) {
        final bloc = CalibrationBloc();
        run(async, bloc, seconds: 5, pulse: 70);
        bloc.cancel();
        async.flushMicrotasks();
        expect(bloc.state.phase, CalibrationPhase.intro);
        expect(sdk.stopCalls, greaterThan(0));
        bloc.close();
        async.flushMicrotasks();
      });
    });
  });
}
