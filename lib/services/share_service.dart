import 'package:flutter/widgets.dart';
import 'package:share_plus/share_plus.dart';

import 'error_reporting_service.dart';

/// Sends a message through the system share sheet: the user picks WhatsApp,
/// SMS, email… Cool Off never sends anything itself (docs/02-features.md).
class _ShareService {
  /// Opens the share sheet with [text]. True when the user picked an app,
  /// or when the platform cannot say (Android often reports
  /// [ShareResultStatus.unavailable]); false when they dismissed the sheet.
  Future<bool> shareText(String text, {Rect? origin}) async {
    try {
      final result = await SharePlus.instance.share(
        ShareParams(text: text, sharePositionOrigin: origin),
      );
      return result.status != ShareResultStatus.dismissed;
    } on Object catch (e, stackTrace) {
      await errorReportingService.recordError(
        e,
        stackTrace,
        reason: 'Opening the share sheet failed',
      );
      rethrow;
    }
  }
}

final shareService = _ShareService();
