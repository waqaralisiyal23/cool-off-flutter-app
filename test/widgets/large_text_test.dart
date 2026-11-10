import 'package:cooloff/bloc/app_preferences_bloc.dart';
import 'package:cooloff/core/app_theme.dart';
import 'package:cooloff/engine/heat_engine.dart';
import 'package:cooloff/engine/text_heat.dart';
import 'package:cooloff/models/check_outcome.dart';
import 'package:cooloff/pages/main/cooldown/cooldown_body.dart';
import 'package:cooloff/pages/main/result/bloc/result_bloc.dart';
import 'package:cooloff/pages/main/result/result_body.dart';
import 'package:cooloff/pages/onboarding/consent/consent_body.dart';
import 'package:cooloff/pages/onboarding/welcome/welcome_body.dart';
import 'package:cooloff/utils/app_haptics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';

import '../support/fakes.dart';

/// In-memory storage for hydrated blocs.
class _MemoryStorage implements Storage {
  final _data = <String, dynamic>{};

  @override
  dynamic read(String key) => _data[key];

  @override
  Future<void> write(String key, dynamic value) async => _data[key] = value;

  @override
  Future<void> delete(String key) async => _data.remove(key);

  @override
  Future<void> clear() async => _data.clear();

  @override
  Future<void> close() async {}
}

CheckOutcome _outcome({required bool heated}) {
  final text = heated ? 'YOU NEVER LISTEN!!! idiot' : 'See you at 6.';
  final result = HeatEngine.evaluate(
    HeatInput(
      pulseBpm: heated ? 96 : 71,
      baselinePulseBpm: 70,
      angerLevel: heated ? 50 : 5,
      baselineAngerLevel: 5,
      textHeat: TextHeat.analyze(text),
    ),
  );
  return CheckOutcome(
    checkId: 'c',
    result: result,
    text: text,
    recipient: 'Sam',
    pulseBpm: heated ? 96 : 71,
    baselinePulseBpm: 70,
    angerLevel: heated ? 50 : 5,
  );
}

void main() {
  setUpAll(() {
    HydratedBloc.storage = _MemoryStorage();
    AppHaptics.enabled = false;
  });

  /// A small phone (360×640 dp) with system text at 2×, the app's cap.
  Future<void> pumpLarge(WidgetTester tester, Widget body) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 3;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.getDarkTheme(),
        home: Scaffold(body: body),
      ),
    );
    // Animations loop forever; let the entrances finish.
    await tester.pump(const Duration(seconds: 3));
  }

  testWidgets('Welcome fits (scrolls) at 2× text', (tester) async {
    await pumpLarge(tester, const WelcomeBody());
    expect(tester.takeException(), isNull);
    expect(find.text('Get started'), findsOneWidget);
  });

  testWidgets('Consent fits at 2× text', (tester) async {
    await pumpLarge(
      tester,
      BlocProvider(
        create: (_) => AppPreferencesBloc(),
        child: const ConsentBody(),
      ),
    );
    expect(tester.takeException(), isNull);
  });

  for (final heated in [false, true]) {
    testWidgets('Result (${heated ? 'heated' : 'calm'}) fits at 2× text', (
      tester,
    ) async {
      await pumpLarge(
        tester,
        BlocProvider(
          create: (_) => ResultBloc(
            outcome: _outcome(heated: heated),
            settings: testSettings(),
          ),
          child: const ResultBody(),
        ),
      );
      expect(tester.takeException(), isNull);
      expect(find.text(heated ? 'Send anyway' : 'Send'), findsOneWidget);
    });
  }

  testWidgets('Before/after card fits at 2× text', (tester) async {
    await pumpLarge(
      tester,
      SingleChildScrollView(
        child: BeforeAfterCard(
          before: _outcome(heated: true),
          after: _outcome(heated: false),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('the result gauge is announced to screen readers', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await pumpLarge(
      tester,
      BlocProvider(
        create: (_) => ResultBloc(
          outcome: _outcome(heated: true),
          settings: testSettings(),
        ),
        child: const ResultBody(),
      ),
    );
    expect(find.bySemanticsLabel('Result: Heated'), findsOneWidget);
    semantics.dispose();
  });
}
