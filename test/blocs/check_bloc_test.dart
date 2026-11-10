import 'package:cooloff/database/app_database.dart';
import 'package:cooloff/models/data/check_record_data.dart';
import 'package:cooloff/models/enums/check_action.dart';
import 'package:cooloff/models/enums/heat_level.dart';
import 'package:cooloff/pages/main/check/bloc/check_bloc.dart';
import 'package:cooloff/pages/main/check/bloc/check_state.dart';
import 'package:cooloff/services/measurement_service.dart';
import 'package:cooloff/services/records_service.dart';
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

  // The engine reports each step; AppLifecycleListener checks the order.
  void goToBackground() {
    for (final state in [
      AppLifecycleState.inactive,
      AppLifecycleState.hidden,
      AppLifecycleState.paused,
    ]) {
      binding.handleAppLifecycleStateChanged(state);
    }
  }

  void comeBack() {
    for (final state in [
      AppLifecycleState.hidden,
      AppLifecycleState.inactive,
      AppLifecycleState.resumed,
    ]) {
      binding.handleAppLifecycleStateChanged(state);
    }
  }

  CheckBloc newBloc({String text = 'Sounds good, see you then.'}) => CheckBloc(
    text: text,
    recipient: 'Sam',
    baseline: testBaseline(),
    settings: testSettings(),
  );

  /// Starts the bloc, reports the preview, and lets the SDK reach running.
  void startRunning(FakeAsync async, CheckBloc bloc) {
    bloc.start();
    bloc.previewReady();
    async.flushMicrotasks();
    sdk.emitStatus(ProcessingStatus.running);
    async.flushMicrotasks();
  }

  /// Sends a frame every half second for [seconds]; the pulse appears after
  /// [pulseAfter] seconds (the SDK needs ~12).
  void feed(
    FakeAsync async, {
    required int seconds,
    double? pulse,
    int pulseAfter = 12,
    double angry = 5,
    int startSecond = 0,
  }) {
    for (var i = 0; i < seconds * 2; i++) {
      final second = startSecond + i / 2;
      sdk.emitFrame(pulse: second >= pulseAfter ? pulse : null, angry: angry);
      async.elapse(_halfSecond);
    }
  }

  CheckRecordData? savedCheck(FakeAsync async, String id) {
    CheckRecordData? record;
    recordsService.getCheck(id).then((r) => record = r);
    async.flushMicrotasks();
    return record;
  }

  test('waits for the camera preview before starting the SDK', () {
    fakeAsync((async) {
      final bloc = newBloc()..start();
      async.flushMicrotasks();
      expect(sdk.startCalls, 0, reason: 'no preview yet');
      bloc.previewReady();
      async.flushMicrotasks();
      expect(sdk.startCalls, 1);
      bloc.close();
      async.flushMicrotasks();
    });
  });

  test('starts anyway if the preview never reports ready', () {
    fakeAsync((async) {
      final bloc = newBloc()..start();
      async.elapse(const Duration(seconds: 3, milliseconds: 100));
      expect(sdk.startCalls, 1);
      bloc.close();
      async.flushMicrotasks();
    });
  });

  test('a calm 20-second check: result, record, timing', () {
    fakeAsync((async) {
      final bloc = newBloc();
      startRunning(async, bloc);
      expect(bloc.state.phase, CheckPhase.measuring);

      feed(async, seconds: 10, pulse: 71);
      expect(bloc.state.secondsLeft, 10);
      expect(bloc.state.progress, closeTo(0.5, 0.05));
      expect(bloc.state.livePulse, isNull, reason: 'pulse comes after ~12 s');

      feed(async, seconds: 10, pulse: 71, startSecond: 10);
      expect(bloc.state.livePulse, 71);
      async.elapse(const Duration(seconds: 2));

      expect(bloc.state.phase, CheckPhase.done);
      final outcome = bloc.state.outcome!;
      expect(outcome.result.level, HeatLevel.calm);
      expect(outcome.pulseBpm, 71);
      expect(sdk.stopCalls, greaterThan(0), reason: 'camera released');

      final record = savedCheck(async, outcome.checkId)!;
      expect(record.heatLevel, HeatLevel.calm);
      expect(record.pulseBpm, 71);
      expect(record.action, isNull, reason: 'the user has not chosen yet');
      bloc.close();
      async.flushMicrotasks();
    });
  });

  test('raised pulse, tense face and hot words read Heated', () {
    fakeAsync((async) {
      final bloc = newBloc(
        text: 'YOU NEVER LISTEN TO ME!!! This is ridiculous',
      );
      startRunning(async, bloc);
      feed(async, seconds: 21, pulse: 92, angry: 45);
      async.elapse(const Duration(seconds: 2));

      final result = bloc.state.outcome!.result;
      expect(result.level, HeatLevel.heated);
      expect(result.pulsePoints, 2);
      expect(result.angerPoints, 2);
      expect(result.textPoints, 2);
      bloc.close();
      async.flushMicrotasks();
    });
  });

  test('waits past 20 s while the pulse is late, then finishes', () {
    fakeAsync((async) {
      final bloc = newBloc();
      startRunning(async, bloc);
      feed(async, seconds: 22, pulse: 74, pulseAfter: 21);
      expect(
        bloc.state.phase,
        CheckPhase.measuring,
        reason: 'only ~2 s of pulse at 22 s',
      );
      feed(async, seconds: 2, pulse: 74, pulseAfter: 0, startSecond: 22);
      async.elapse(const Duration(seconds: 2));
      expect(bloc.state.phase, CheckPhase.done);
      expect(bloc.state.outcome!.pulseBpm, 74);
      bloc.close();
      async.flushMicrotasks();
    });
  });

  test('without any pulse it gives up at 30 s, honestly', () {
    fakeAsync((async) {
      final bloc = newBloc();
      startRunning(async, bloc);
      feed(async, seconds: 31, pulseAfter: 999);
      async.elapse(const Duration(seconds: 2));
      expect(bloc.state.phase, CheckPhase.done);
      expect(bloc.state.outcome!.pulseBpm, isNull);
      expect(bloc.state.outcome!.result.pulseMissing, isTrue);
      bloc.close();
      async.flushMicrotasks();
    });
  });

  test('no face frames → asks to try again', () {
    fakeAsync((async) {
      final bloc = newBloc();
      startRunning(async, bloc);
      async.elapse(const Duration(seconds: 31));
      expect(bloc.state.phase, CheckPhase.failed);
      expect(bloc.state.couldNotSeeFace, isTrue);
      bloc.close();
      async.flushMicrotasks();
    });
  });

  test('shows imaging hints', () {
    fakeAsync((async) {
      final bloc = newBloc();
      startRunning(async, bloc);
      sdk.emitHint(ValidationCode.tooDark);
      async.flushMicrotasks();
      expect(bloc.state.hint, 'Find a bit more light');
      sdk.emitHint(ValidationCode.ok);
      async.flushMicrotasks();
      expect(bloc.state.hint, isNull);
      bloc.close();
      async.flushMicrotasks();
    });
  });

  test('leaving the app interrupts, saves it, and restarts on return', () {
    fakeAsync((async) {
      final bloc = newBloc();
      startRunning(async, bloc);
      feed(async, seconds: 5);

      goToBackground();
      sdk.emitStatus(ProcessingStatus.idle);
      async.flushMicrotasks();
      expect(bloc.state.phase, CheckPhase.interrupted);

      comeBack();
      async.flushMicrotasks();
      expect(bloc.state.phase, CheckPhase.starting);
      expect(sdk.startCalls, 2, reason: 'restarted from zero');
      expect(bloc.state.progress, 0);

      final records = <CheckRecordData>[];
      appDatabase.select(appDatabase.checkRecords).get().then(records.addAll);
      async.flushMicrotasks();
      expect(records.single.action, CheckAction.interrupted);
      bloc.close();
      async.flushMicrotasks();
    });
  });

  test(
    "the SDK's quick camera restart while in front is not an interruption",
    () {
      fakeAsync((async) {
        final bloc = newBloc();
        startRunning(async, bloc);
        sdk.emitStatus(ProcessingStatus.idle);
        async.flushMicrotasks();
        sdk.emitStatus(ProcessingStatus.running);
        async.flushMicrotasks();
        expect(bloc.state.phase, CheckPhase.measuring);
        bloc.close();
        async.flushMicrotasks();
      });
    },
  );

  test('no network → friendly failure that can be retried', () {
    fakeAsync((async) {
      sdk.failNextStart = SmartSpectraException.fromNative(
        code: 'PROCESSING_FAILED',
        message: 'COULDNT_RESOLVE_HOST cont-api.physiology.presagetech.com',
      );
      final bloc = newBloc()..start();
      bloc.previewReady();
      async.flushMicrotasks();
      expect(bloc.state.phase, CheckPhase.failed);
      expect(bloc.state.failure!.title, "Can't reach the measurement service");
      expect(bloc.state.failure!.canRetry, isTrue);
      bloc.close();
      async.flushMicrotasks();
    });
  });

  test('cancel mid-check stops the camera and records a cancel', () {
    fakeAsync((async) {
      final bloc = newBloc();
      startRunning(async, bloc);
      feed(async, seconds: 3);
      bloc.cancel();
      async.flushMicrotasks();
      expect(sdk.stopCalls, greaterThan(0));
      final records = <CheckRecordData>[];
      appDatabase.select(appDatabase.checkRecords).get().then(records.addAll);
      async.flushMicrotasks();
      expect(records.single.action, CheckAction.cancelled);
      expect(records.single.heatLevel, isNull);
      bloc.close();
      async.flushMicrotasks();
    });
  });
}
