import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:wc_dart_framework/wc_dart_framework.dart';

final _logger = Logger('share_intent_service.dart');

/// Text the user shared INTO Cool Off from another app (Android share sheet
/// → Cool Off). Android only for now: iOS needs a Share Extension, which is
/// in the backlog (docs/02-features.md). Nothing is ever read from other
/// apps; only what the user explicitly shares arrives here.
///
/// Text that arrives before the main screens exist (a share that launches
/// the app, or one during onboarding) waits in [takePending].
class _ShareIntentService {
  static const _methods = MethodChannel('cooloff/share');
  static const _events = EventChannel('cooloff/share/events');

  final _texts = StreamController<String>.broadcast();
  String? _pending;

  bool get isSupported => defaultTargetPlatform == TargetPlatform.android;

  /// Shared text while the app runs.
  Stream<String> get texts => _texts.stream;

  Future<void> init() async {
    if (!isSupported) {
      return;
    }
    try {
      _pending = await _methods.invokeMethod<String>('takeInitialText');
      _events.receiveBroadcastStream().listen((event) {
        if (event is! String || event.trim().isEmpty) {
          return;
        }
        if (_texts.hasListener) {
          _texts.add(event);
        } else {
          _pending = event;
        }
      });
    } on PlatformException catch (e) {
      _logger.warning('Share intake unavailable: $e');
    }
  }

  /// Shared text that arrived while nothing was listening, once.
  String? takePending() {
    final text = _pending;
    _pending = null;
    return text;
  }
}

final shareIntentService = _ShareIntentService();
