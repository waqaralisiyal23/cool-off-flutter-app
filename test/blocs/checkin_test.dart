import 'dart:async';

import 'package:cooloff/database/app_database.dart';
import 'package:cooloff/models/enums/check_action.dart';
import 'package:cooloff/models/enums/check_kind.dart';
import 'package:cooloff/models/enums/heat_level.dart';
import 'package:cooloff/models/enums/reflection_answer.dart';
import 'package:cooloff/models/enums/sensitivity.dart';
import 'package:cooloff/pages/main/write/bloc/write_bloc.dart';
import 'package:cooloff/services/checkin_service.dart';
import 'package:cooloff/services/records_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fakes.dart';

Future<String> _heatedSend({String? recipient}) async {
  final messageId = await recordsService.recordSent(
    body: 'You never listen',
    recipientLabel: recipient,
    checkId: null,
    keepText: true,
  );
  return recordsService.saveCheck(
    kind: CheckKind.check,
    heatLevel: HeatLevel.heated,
    score: 5,
    pulseBpm: 92,
    baselineId: null,
    pulseDeltaPct: 30,
    angerLevel: 40,
    textHeat: 2,
    sensitivity: Sensitivity.normal,
    action: CheckAction.sentAnyway,
    messageId: messageId,
  );
}

Future<void> _settle() =>
    Future<void>.delayed(const Duration(milliseconds: 50));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(openTestDatabase);
  tearDown(() => appDatabase.close());

  group('checkinService', () {
    test('saves an answer once', () async {
      final id = await _heatedSend();
      expect(await checkinService.answer(id, ReflectionAnswer.glad), isTrue);
      expect(
        await checkinService.answer(id, ReflectionAnswer.regret),
        isFalse,
        reason: 'the card and the notification can both be tapped',
      );
      final answers = await recordsService.getReflections();
      expect(answers.single.answer, ReflectionAnswer.glad);
    });

    test(
      'three regrets make Cool Off more cautious; glad answers undo it',
      () async {
        for (var i = 0; i < 3; i++) {
          await checkinService.answer(
            await _heatedSend(),
            ReflectionAnswer.regret,
          );
        }
        expect(
          (await appDatabase.userSettingsDao.getCurrent())!.autoTuneOffset,
          -1,
        );

        for (var i = 0; i < 7; i++) {
          await checkinService.answer(
            await _heatedSend(),
            ReflectionAnswer.glad,
          );
        }
        expect(
          (await appDatabase.userSettingsDao.getCurrent())!.autoTuneOffset,
          1,
        );
      },
    );
  });

  group('WriteBloc', () {
    test(
      'shows due check-ins with recipient and kept text; answering clears them',
      () async {
        await _heatedSend(recipient: 'Sam');
        final settings = testSettings(keepMessageText: true);
        final bloc = WriteBloc(
          settings: Stream.value(settings),
          initialSettings: settings,
          demoCheckinsNow: Stream.value(true),
          initialDemo: true,
        );
        await _settle();
        final checkin = bloc.state.checkins.single;
        expect(checkin.recipient, 'Sam');
        expect(checkin.text, 'You never listen');

        await bloc.answer(checkin, ReflectionAnswer.regret);
        await _settle();
        expect(bloc.state.checkins, isEmpty);
        expect(bloc.state.lastAnswerNote, isNotNull);
        expect(
          (await recordsService.getReflections()).single.answer,
          ReflectionAnswer.regret,
        );
        await bloc.close();
      },
    );

    test(
      'answered check-ins stay hidden when the app opens (no stale refresh)',
      () async {
        // As on launch: three heated sends, two already answered.
        final answered1 = await _heatedSend(recipient: 'Team');
        final answered2 = await _heatedSend();
        await _heatedSend();
        await recordsService.saveReflection(
          checkRecordId: answered1,
          answer: ReflectionAnswer.regret,
        );
        await recordsService.saveReflection(
          checkRecordId: answered2,
          answer: ReflectionAnswer.regret,
        );

        final settings = testSettings(keepMessageText: true);
        final bloc = WriteBloc(
          settings: Stream.value(settings),
          initialSettings: settings,
          demoCheckinsNow: Stream.value(true),
          initialDemo: true,
        );
        await _settle();
        await _settle();
        expect(bloc.state.checkins, hasLength(1));
        await bloc.close();
      },
    );

    test('a send from a minute ago is not due yet outside demo mode', () async {
      await _heatedSend();
      final settings = testSettings();
      final bloc = WriteBloc(
        settings: Stream.value(settings),
        initialSettings: settings,
        demoCheckinsNow: Stream.value(false),
        initialDemo: false,
      );
      await _settle();
      expect(bloc.state.checkins, isEmpty);
      await bloc.close();
    });

    test('text is hidden when "Keep message text" is off', () async {
      await _heatedSend();
      final settings = testSettings();
      final bloc = WriteBloc(
        settings: Stream.value(settings),
        initialSettings: settings,
        demoCheckinsNow: Stream.value(true),
        initialDemo: true,
      );
      await _settle();
      expect(bloc.state.checkins.single.text, isNull);
      await bloc.close();
    });

    test('turning check-ins off hides them', () async {
      await _heatedSend();
      final settings = testSettings(checkinEnabled: false);
      final bloc = WriteBloc(
        settings: Stream.value(settings),
        initialSettings: settings,
        demoCheckinsNow: Stream.value(true),
        initialDemo: true,
      );
      await _settle();
      expect(bloc.state.checkins, isEmpty);
      await bloc.close();
    });
  });
}
