import 'package:cooloff/core/app_theme.dart';
import 'package:cooloff/models/enums/heat_level.dart';
import 'package:cooloff/utils/app_haptics.dart';
import 'package:cooloff/widgets/outcome_actions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<List<String>> _pump(
  WidgetTester tester,
  HeatLevel level, {
  bool withCoolDown = true,
  bool isBusy = false,
}) async {
  final taps = <String>[];
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.getDarkTheme(),
      home: Scaffold(
        body: OutcomeActions(
          level: level,
          holdMinutes: 10,
          isBusy: isBusy,
          onSend: (_) => taps.add('send'),
          onHold: () => taps.add('hold'),
          onCoolDown: withCoolDown ? () => taps.add('cooldown') : null,
          onEdit: () => taps.add('edit'),
          onDiscard: () => taps.add('discard'),
        ),
      ),
    ),
  );
  return taps;
}

void main() {
  setUp(() => AppHaptics.enabled = false);

  testWidgets('Calm: Send first, no hold', (tester) async {
    final taps = await _pump(tester, HeatLevel.calm);
    expect(find.text('Send'), findsOneWidget);
    expect(find.textContaining('Hold'), findsNothing);
    await tester.tap(find.text('Send'));
    expect(taps, ['send']);
  });

  testWidgets('Warm: Send, Edit and Hold', (tester) async {
    await _pump(tester, HeatLevel.warm);
    expect(find.text('Send'), findsOneWidget);
    expect(find.text('Edit'), findsOneWidget);
    expect(find.text('Hold 10 min'), findsOneWidget);
  });

  testWidgets(
    'Heated: Hold first, cool down, and Send anyway is always there',
    (tester) async {
      final taps = await _pump(tester, HeatLevel.heated);
      expect(find.text('Hold for 10 min'), findsOneWidget);
      expect(find.text('Cool down now · 60 s'), findsOneWidget);
      expect(find.text('Send anyway'), findsOneWidget);
      await tester.tap(find.text('Send anyway'));
      await tester.tap(find.text('Cool down now · 60 s'));
      expect(taps, ['send', 'cooldown']);
    },
  );

  testWidgets('after a cool-down there is no second cool-down', (tester) async {
    await _pump(tester, HeatLevel.heated, withCoolDown: false);
    expect(find.textContaining('Cool down'), findsNothing);
    expect(find.text('Send anyway'), findsOneWidget);
  });

  testWidgets('busy: nothing can be tapped twice', (tester) async {
    final taps = await _pump(tester, HeatLevel.calm, isBusy: true);
    await tester.tap(find.text('Send'));
    await tester.tap(find.text('Delete message'));
    expect(taps, isEmpty);
  });
}
