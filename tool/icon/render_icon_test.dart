// Renders the app icon PNGs into assets/icon/. Not part of the test suite:
//   flutter test tool/icon/render_icon_test.dart
// then:
//   flutter_launcher_icons
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'cool_off_icon.dart';

void main() {
  const size = 1024.0;

  Future<void> render(
    WidgetTester tester,
    String file,
    CoolOffIconPainter painter,
  ) async {
    final key = GlobalKey();
    tester.view
      ..physicalSize = const Size(size, size)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      Center(
        child: RepaintBoundary(
          key: key,
          child: CustomPaint(size: const Size(size, size), painter: painter),
        ),
      ),
    );
    await tester.runAsync(() async {
      final boundary =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await boundary.toImage();
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      File('assets/icon/$file').writeAsBytesSync(bytes!.buffer.asUint8List());
    });
  }

  // iOS (and the legacy Android icon): everything, edge to edge. iOS rounds
  // the corners itself.
  testWidgets(
    'icon.png',
    (tester) => render(tester, 'icon.png', const CoolOffIconPainter()),
  );

  // Android adaptive icon: background and foreground layers. The foreground
  // must fit the 66/108 safe zone, so the artwork is smaller.
  testWidgets(
    'icon_background.png',
    (tester) => render(
      tester,
      'icon_background.png',
      const CoolOffIconPainter(artwork: false),
    ),
  );
  testWidgets(
    'icon_foreground.png',
    (tester) => render(
      tester,
      'icon_foreground.png',
      const CoolOffIconPainter(background: false),
    ),
  );

  // Android 13+ themed icon: a single-colour silhouette.
  testWidgets(
    'icon_monochrome.png',
    (tester) => render(
      tester,
      'icon_monochrome.png',
      const CoolOffIconPainter(background: false, monochrome: true),
    ),
  );
}
