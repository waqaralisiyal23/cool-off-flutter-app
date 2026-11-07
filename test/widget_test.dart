import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cooloff/widgets/app_scaffold.dart';

void main() {
  testWidgets('AppScaffold renders its body', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: AppScaffold(body: Center(child: Text('ok'))),
      ),
    );

    expect(find.text('ok'), findsOneWidget);
  });
}
